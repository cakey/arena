# class for each client

uuid = require 'node-uuid'

WebSocketServer = require('ws').Server

Config = require "../lib/config"
GameState = require "../lib/game-state"
Point = require "../lib/point"
Player = require "../lib/player"

class FixedBuffer
    constructor: (@n) ->
        @i = 0
        @_arr = []

    add: (v) ->
        if @i < @n
            @_arr[@i] = v
            @i += 1
        else
            @i = 0
            @_arr[@i] = v

    average: ->
        sum = 0
        length = 0

        for i in @_arr
            sum += i
            length += 1

        sum / length

class GameHandler

    constructor: ->
        @SERVERID = "SERVER"

    start: ->
        console.log "Game Loop (start)"
        @tick = 0
        @gameState = new GameState (new Date().getTime())

        # I will fix this when I move AI processing to serverSide
        @gameState.addTeam "red", "#aa3333"
        @gameState.addTeam "blue", "#3333aa"

        if Config.game.numAIs > 0
            @gameState.addTeam "yellowAI", "#ddaa44"
            @gameState.addTeam "greenAI", "#33aa33"

        @locallyProccessed = []

        for a in [0...Config.game.numAIs]
            aip1 = new Player.AIPlayer @, @gameState.map.randomPoint(), "yellowAI"
            @registerAI aip1
            aip2 = new Player.AIPlayer @, @gameState.map.randomPoint(), "greenAI"
            @registerAI aip2

        process.nextTick @loop

    loop: =>
        @loopTimeout = setTimeout @loop, Config.game.tickTime

        newTime = new Date().getTime()

        for ai in @locallyProccessed
            ai.update newTime, @gameState

        @gameState.update newTime

        if @tick % 500 is 0
            console.log JSON.stringify @gameState, null, 4

        if @tick % 200 is 0
            for clientID, conn of clientHandler.clients
                console.log clientID, clientHandler.clientPings[clientID].average()


        if @tick % 10 is 0
            for clientID, conn of clientHandler.clients
                pingID = uuid.v4()
                clientHandler.pings[pingID] =
                    clientID: clientID
                    time: new Date().getTime()
                conn.send JSON.stringify
                    data: pingID
                    action: "ping"

        if @tick % 5 is 0
            for clientID, conn of clientHandler.clients
                conn.send JSON.stringify
                    data: @gameState
                    action: "sync"


        @tick += 1

    newPlayer: (d) ->
        playerPosition = Point.fromObject d.playerPosition
        player = new Player.GamePlayer @gameState.time, playerPosition, d.team, d.playerId
        @gameState.addPlayer player

    removePlayer: (id) ->
        @gameState.removePlayer id

    movePlayer: (id, dest) ->
        @gameState.movePlayer id, dest

    playerFire: (id, castP, skillName) ->
        @gameState.playerFire id, castP, skillName

    # These need to be refactored with ClientHandler

    registerAI: (ai) ->
        @locallyProccessed.push ai
        clientHandler.newPlayer null,
            action: 'newPlayer'
            data:
                playerId: ai.id
                playerPosition: ai.p.toObject()
                team: ai.team
            id: @SERVERID

    triggerMoveTo: (player, destP) ->
        clientHandler.control null,
            action: 'control'
            data:
                playerId: player.id
                action: 'moveTo'
                actionPosition: destP.toObject()
                team: player.team
            id: @SERVERID

    triggerFire: (player, castP, skillName) ->
        clientHandler.control null,
            action: 'control'
            data:
                playerId: player.id
                action: 'fire'
                actionPosition: castP.toObject()
                skill: skillName
                team: player.team
            id: @SERVERID

    stop: ->
        console.log "Game Loop (end)"
        clearTimeout @loopTimeout
        @gameState = null
        @locallyProccessed = []


class ClientHandler
    constructor: (@wss) ->

        @messageCount = 0
        @players = {}
        @clients = {}
        @pings = {} # Unbounded resources
        @clientPings = {}

        @wss.on 'connection', (ws) =>
            ws.on 'message', (unparsed) => @sprayMessage ws, unparsed

    sprayMessage: (ws, unparsed) ->
        @messageCount += 1
        if @messageCount % 100 is 0
            console.log @messageCount
        try
            message = JSON.parse unparsed
            switch message.action
                when "register"
                    @register ws, message
                when "deregister"
                    @deregister ws, message
                when "control"
                    @control ws, message
                when "newPlayer"
                    @newPlayer ws, message
                when "ping"
                    @ping ws, message
                else
                    console.log "Unsupported message action #{message.action}"
        catch e
            console.log "EXCEPTION!"
            console.log e.message
            console.log e.stack

    register: (ws, message) ->
        console.log "register --- #{message.id[..7]}"

        @clients[message.id] = ws
        @clientPings[message.id] = new FixedBuffer 50
        @players[message.id] = {}

        if Object.keys(@clients).length is 1
            @players[gameHandler.SERVERID] = {}
            gameHandler.start()

        # send existing @players so the client can catch up
        for client_id, clientPs of @players
            if client_id isnt message.id
                for id, p of clientPs
                    ws.send JSON.stringify
                        data: p
                        action: "newPlayer"
        return

    deregister: (ws, message) ->
        console.log "deregister - #{message.id[..7]}"
        delete @clients[message.id]

        for client_id, client of @clients
            for id, p of @players[message.id]
                client.send JSON.stringify
                    data: id
                    action: "deletePlayer"

        for id, p of @players[message.id]
            gameHandler.removePlayer id

        delete @players[message.id]

        if Object.keys(@clients).length is 0
            @players = {} # To remove server AIs too
            gameHandler.stop()
            messageCount = 0

    control: (ws, message) ->
        for client_id, client of @clients
            client.send JSON.stringify message
        id = message.data.playerId
        point = Point.fromObject message.data.actionPosition
        switch message.data.action
            when 'moveTo'
                gameHandler.movePlayer id, point
            when 'fire'
                gameHandler.playerFire id, point, message.data.skill

    newPlayer: (ws, message) ->
        gameHandler.newPlayer message.data
        @players[message.id][message.data.playerId] = message.data
        for client_id, client of @clients
            client.send JSON.stringify message
        return

    ping: (ws, message) ->
        returnTime = new Date().getTime()
        ping = @pings[message.data]
        rtt = returnTime - ping.time
        @clientPings[ping.clientID].add rtt


# These need to be uncoupled.

wss = new WebSocketServer port: Config.ws.port
gameHandler = new GameHandler()
clientHandler = new ClientHandler wss


