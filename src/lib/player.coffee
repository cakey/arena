uuid = require 'node-uuid'
Utils = require "../lib/utils"

class Player

    constructor: (@arena, @p, @team, @id) ->
        @time = @arena.time
        @radius = 20
        @maxCastRadius = @radius * 2
        @destP = @p
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castP = null
        if not @id?
            @id = uuid.v4()

    moveTo: (@destP) ->
        if @startCastTime isnt null and @castedSkill.channeled
            @startCastTime = null

    fire: (@castP, @castedSkill) ->
        # stop moving to fire
        if @castedSkill.channeled
            @destP = @p
        @startCastTime = @time # needs to be passed through

    update: (newTime) ->
        msDiff = newTime - @time

        # Location

        newP = @p.towards @destP, (Utils.game.speed(@speed) * msDiff)
        if @arena.allowedMovement newP, @
            @p = newP

        # Cast

        if @startCastTime?
            if newTime - @startCastTime > Utils.game.speedInverse(@castedSkill.castTime)
                @startCastTime = null

                castAngle = @p.angle @castP

                edgeP = @p.bearing castAngle, @maxCastRadius

                # handle edgecase where castPoint was within casting circle
                if @castP.within @p, @maxCastRadius
                    @castP = edgeP.bearing castAngle, 0.1

                @arena.addProjectile edgeP, @castP, @castedSkill, @team

        @time = newTime

module.exports = Player
