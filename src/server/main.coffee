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




wss = new WebSocketServer port: Config.ws.port

players = {}
clients = {}
pings = {}
clientPings = {}
messageCount = 0

class ServerHandler
    constructor: ->

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

        process.nextTick @loop

    loop: =>
        @loopTimeout = setTimeout @loop, 10

        if @tick % 500 is 0
            console.log JSON.stringify @gameState, null, 4

        if @tick % 200 is 0
            for clientID, conn of clients
                console.log clientID, clientPings[clientID].average()

        if @tick % 10 is 0
            for clientID, conn of clients
                pingID = uuid.v4()
                pings[pingID] =
                    clientID: clientID
                    time: new Date().getTime()
                conn.send JSON.stringify
                    data: pingID
                    action: "ping"

        @gameState.update new Date().getTime()

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

    stop: ->
        console.log "Game Loop (end)"
        clearTimeout @loopTimeout
        @gameState = null


serverHandler = new ServerHandler()

actions =
    register: (ws, message) ->
        console.log "register --- #{message.id[..7]}"

        clients[message.id] = ws
        clientPings[message.id] = new FixedBuffer 50
        players[message.id] = {}

        if Object.keys(clients).length is 1
            serverHandler.start()

        # send existing players so the client can catch up
        for client_id, clientPs of players
            if client_id isnt message.id
                for id, p of clientPs
                    ws.send JSON.stringify
                        data: p
                        action: "newPlayer"
        return

    deregister: (ws, message) ->
        console.log "deregister - #{message.id[..7]}"
        delete clients[message.id]

        for client_id, client of clients
            for id, p of players[message.id]
                client.send JSON.stringify
                    data: id
                    action: "deletePlayer"

        for id, p of players[message.id]
            serverHandler.removePlayer id

        delete players[message.id]

        if Object.keys(clients).length is 0
            serverHandler.stop()
            messageCount = 0

    control: (ws, message) ->
        for client_id, client of clients
            client.send JSON.stringify message
        id = message.data.playerId
        point = Point.fromObject message.data.actionPosition
        switch message.data.action
            when 'moveTo'
                serverHandler.movePlayer id, point
            when 'fire'
                serverHandler.playerFire id, point, message.data.skill

        player = players[message.id][message.data.playerId]
        player.playerPosition = message.data.playerPosition

    newPlayer: (ws, message) ->
        serverHandler.newPlayer message.data
        players[message.id][message.data.playerId] = message.data
        for client_id, client of clients
            client.send JSON.stringify message
        return

    ping: (ws, message) ->
        returnTime = new Date().getTime()
        ping = pings[message.data]
        rtt = returnTime - ping.time
        clientPings[ping.clientID].add rtt

wss.on 'connection', (ws) ->
    ws.on 'message', (unparsed) ->
        messageCount += 1
        if messageCount % 100 is 0
            console.log messageCount
        try
            message = JSON.parse unparsed
            actions[message.action](ws, message)
        catch e
            console.log "EXCEPTION!"
            console.log e.message
            console.log e.stack
