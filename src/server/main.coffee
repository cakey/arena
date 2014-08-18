Config = require "../lib/config"

WebSocketServer = require('ws').Server

wss = new WebSocketServer port: Config.ws.port

clients = {}

wss.on 'connection', (ws) ->
    ws.on 'message', (unparsed) ->
        message = JSON.parse unparsed
        if message.action is "register"
            console.log "register --- #{message.id}"
            clients[message.id] = ws
        else if message.action is "deregister"
            console.log "deregister - #{message.id}"
            delete clients[message.id]
        else if message.action is "control"
            for client_id, client of clients
                client.send unparsed
