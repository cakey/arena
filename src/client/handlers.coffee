Config = require "../lib/config"
WebSocket = require 'ws'
RSVP = require 'rsvp'
uuid = require 'node-uuid'

Point = require "../lib/point"
Player = require "../lib/player"

class ClientNetworkHandler
    constructor: (@gameState) ->
        @host = "ws://#{location.hostname}:#{Config.ws.port}"
        @ws = new WebSocket @host

        @client_uuid = uuid.v4()

        @_readyDeferred = RSVP.defer()

        @locallyProcessed = []

        @ws.onopen = =>
            message =
                action: 'register'
                id: @client_uuid
            @ws.send JSON.stringify message
            @_readyDeferred.resolve()

        window.onbeforeunload = =>
            message =
                action: 'deregister'
                id: @client_uuid
            @ws.send JSON.stringify message

        @ws.onmessage = (unparsed) =>
            message = JSON.parse unparsed.data
            d = message.data
            if message.action is "control"
                position = Point.fromObject d.actionPosition
                player = @gameState.players[d.playerId]

                playerPosition = Point.fromObject d.playerPosition
                if not player
                    console.log "unregistered player"
                    return

                if d.action is "moveTo"
                    # server corrects us
                    player.p = playerPosition
                    player.moveTo position
                else if d.action is "fire"
                    player.fire position, d.skill
            else if message.action is "newPlayer"
                playerPosition = Point.fromObject d.playerPosition
                player = new Player.GamePlayer @gameState, playerPosition, d.team, d.playerId
                @register player
            else if message.action is "deletePlayer"
                @removePlayer d
            else
                console.log "unrecognised message"
                console.log message

        @ws.onclose = ->
            # Server crashed or connection dropped
            # TODO: more rebust, in the meantime, essentially live reload
            document.location.reload true

    ready: -> @_readyDeferred.promise

    registerLocal: (player, ai) ->
        message =
            action: 'newPlayer'
            data:
                playerId: player.id
                playerPosition: player.p.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message
        if ai
            @locallyProcessed.push player


    register: (player) ->
        @gameState.players[player.id] = player

    removePlayer: (playerId) ->
        delete @gameState.players[playerId]

    moveTo: (player, destP) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'moveTo'
                actionPosition: destP.toObject()
                playerPosition: @gameState.players[player.id].p.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    fire: (player, castP, skillName) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'fire'
                actionPosition: castP.toObject()
                playerPosition: @gameState.players[player.id].p.toObject()
                skill: skillName
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    loop: =>
        setTimeout @loop, 5
        # TODO: A non sucky game loop...
        # Fixed time updates.
        for player in @locallyProcessed
            player.update()
        @gameState.update new Date().getTime()
        @gameState.render()

module.exports =
    Client: ClientNetworkHandler
