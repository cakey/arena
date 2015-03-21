RSVP = require 'rsvp'

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
        player.fire castP, skillName

    ready: -> @_readyDeferred.promise

module.exports = LocalHandler
