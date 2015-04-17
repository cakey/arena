Config = require "../lib/config"
WebSocket = require 'ws'
RSVP = require 'rsvp'
uuid = require 'node-uuid'

Point = require "../lib/point"
Player = require "../lib/player"
Renderers = require "./renderers"


class ClientNetworkHandler
    constructor: (@gameState, @canvas, @camera) ->
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
            switch message.action
                when "control"
                    position = Point.fromObject d.actionPosition
                    player = @gameState.players[d.playerId]

                    if not player
                        console.log "unregistered player"
                        return

                    if d.action is "moveTo"
                        @gameState.movePlayer d.playerId, position
                    else if d.action is "fire"
                        @gameState.playerFire d.playerId, position, d.skill
                when "newPlayer"
                    player = new Player.GamePlayer @gameState.time, @gameState.map.randomPoint(), d.team, d.playerId
                    @gameState.addPlayer player
                when "deletePlayer"
                    @gameState.removePlayer d
                when "ping"
                    @ws.send JSON.stringify message
                when "sync"
                    @gameState.sync d
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

    triggerMoveTo: (player, destP) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'moveTo'
                actionPosition: destP.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    triggerFire: (player, castP, skillName) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'fire'
                actionPosition: castP.toObject()
                skill: skillName
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    startLoop: ->
        @time = new Date().getTime()
        @tickNo = 0
        @loopTick()

    loopTick: =>
        @tickNo += 1
        setTimeout @loopTick, Config.game.tickTime
        newTime = new Date().getTime()
        # TODO: A non sucky game loop...
        # Fixed time updates.
        for player in @locallyProcessed
            player.update newTime, @gameState

        # Map.
        @camera.update newTime - @time

        @gameState.update newTime

        # Clear the canvas.
        @canvas.begin()

        # Render all the things.
        Renderers.arena @gameState, @canvas, @camera, @focusedUIPlayer
        if @tickNo % 10 is 0
            Renderers.ui @gameState, @canvas, @camera, @focusedUIPlayer

        # Nothing right now.
        @canvas.end()
        @time = newTime

module.exports =
    Client: ClientNetworkHandler
