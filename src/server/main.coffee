Config = require "../lib/config"
GameState = require "../lib/game-state"

WebSocketServer = require('ws').Server

wss = new WebSocketServer port: Config.ws.port

players = {}
clients = {}

messageCount = 0

class ServerHandler
    constructor: ->

    start: ->
        console.log "Game Loop (start)"

    stop: ->
        console.log "Game Loop (end)"


serverHandler = new ServerHandler()

actions =
    register: (ws, message) ->
        console.log "register --- #{message.id[..7]}"

        if Object.keys(clients).length is 0
            serverHandler.start()

        clients[message.id] = ws
        players[message.id] = {}

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

        delete players[message.id]

        if Object.keys(clients).length is 0
            serverHandler.stop()
            messageCount = 0

    control: (ws, message) ->
        for client_id, client of clients
            client.send JSON.stringify message
        player = players[message.id][message.data.playerId]
        player.playerPosition = message.data.playerPosition

    newPlayer: (ws, message) ->
        players[message.id][message.data.playerId] = message.data

        for client_id, client of clients
            client.send JSON.stringify message
        return

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
