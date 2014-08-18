Config = require "../lib/config"

WebSocketServer = require('ws').Server

wss = new WebSocketServer port: Config.ws.port

players = {}
clients = {}

actions =
    register: (ws, message) ->
        console.log "register --- #{message.id}"
        clients[message.id] = ws
        players[message.id] = {}

        for client_id, clientPs of players
            if client_id isnt message.id
                for id, p of clientPs
                    ws.send JSON.stringify
                        data: p
                        action: "newPlayer"

    deregister: (ws, message) ->
        console.log "deregister - #{message.id}"
        delete clients[message.id]

        for client_id, client of clients
            for id, p of players[message.id]
                client.send JSON.stringify
                    data: id
                    action: "deletePlayer"

        delete players[message.id]

    control: (ws, message) ->
        for client_id, client of clients
            client.send JSON.stringify message
        player = players[message.id][message.data.playerId]
        player.playerPosition = message.data.playerPosition

    newPlayer: (ws, message) ->
        players[message.id][message.data.playerId] = message.data

        for client_id, client of clients
            if message.id isnt client_id
                client.send JSON.stringify message

wss.on 'connection', (ws) ->
    ws.on 'message', (unparsed) ->
        try
            message = JSON.parse unparsed
            actions[message.action](ws, message)
        catch e
            console.log "EXCEPTION!"
            console.log e.message
            console.log e.stack
