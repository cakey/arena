Config = require "../lib/config"
WebSocket = require 'ws'
RSVP = require 'rsvp'
uuid = require 'node-uuid'

Point = require "../lib/point"
Skills = require "../lib/skills"
Player = require "../lib/player"

class LocalHandler
    constructor: ->
        @players = {}
        @locallyProcessed = []
        @_readyDeferred = RSVP.defer()
        @_readyDeferred.resolve()

    registerLocal: (processor) ->
        player = processor.player
        @players[player.id] = player
        @locallyProcessed.push processor

    register: (player) ->
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    moveTo: (player, destP) ->
        player.moveTo destP

    fire: (player, castP, skillName) ->
        player.fire castP, Skills[skillName]

    ready: -> @_readyDeferred.promise

class NetworkHandler
    constructor: (@arena) ->
        @players = {}
        @locallyProcessed = []

        @host = "ws://#{location.hostname}:#{Config.ws.port}"
        @ws = new WebSocket @host

        @client_uuid = uuid.v4()

        @_readyDeferred = RSVP.defer()

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
                player = @players[d.playerId]

                playerPosition = Point.fromObject d.playerPosition
                if not player
                    console.log "unregistered player"
                    return

                if d.action is "moveTo"
                    # server corrects us
                    player.p = playerPosition
                    player.moveTo position
                else if d.action is "fire"
                    player.fire position, Skills[d.skill]
            else if message.action is "newPlayer"
                playerPosition = Point.fromObject d.playerPosition
                player = new Player @arena, playerPosition, d.team, d.playerId
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

    registerLocal: (processor) ->
        player = processor.player
        @players[player.id] = player
        @locallyProcessed.push processor

        message =
            action: 'newPlayer'
            data:
                playerId: player.id
                playerPosition: player.p.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    register: (player) ->
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    moveTo: (player, destP) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'moveTo'
                actionPosition: destP.toObject()
                playerPosition: player.p.toObject()
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
                playerPosition: player.p.toObject()
                skill: skillName
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

module.exports =
    Local: LocalHandler
    Network: NetworkHandler
