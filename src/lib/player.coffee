_ = require 'lodash'
uuid = require 'node-uuid'

Utils = require "../lib/utils"
Skills = require "../lib/skills"
UIElement = require "../lib/ui-element"
Point = require "../lib/point"
Config = require "../lib/config"

class ProtoPlayer extends UIElement
    constructor: (@arena, @p, @team, @id) ->
        @time = @arena.time
        @radius = 20
        @maxCastRadius = @radius * 2
        @destP = @p
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castP = null

        @_lastCasted = {}

        @circle = new createjs.Shape()
        @circle.graphics.beginFill(@arena.teams[@team].color).
            drawCircle(@p.x, @p.y, @radius)
        @arena.canvas.stage.addChild @circle

        if not @id?
            @id = uuid.v4()

        super(@id)

    moveTo: (@destP) ->
        if @startCastTime isnt null and Skills[@castedSkill].channeled
            @startCastTime = null

    pctCooldown: (castedSkill) ->
        realCooldown = Utils.game.speedInverse Skills[castedSkill].cooldown

        lastCasted = @_lastCasted[castedSkill]

        if realCooldown is 0
            return 1

        if not lastCasted?
            return 1

        if lastCasted is @time
            return 0

        return Math.min ((@time - lastCasted) / realCooldown), 1

    fire: (@castP, @castedSkill) ->
        # first check cool down
        pctCooldown = @pctCooldown @castedSkill

        if pctCooldown >= 1
            # stop moving to fire
            if Skills[@castedSkill].channeled
                @destP = @p
            @startCastTime = @time # needs to be passed through

    update: (newTime) ->
        msDiff = newTime - @time

        # Location
        newP = @p.towards @destP, (Utils.game.speed(@speed) * msDiff)
        if @arena.allowedMovement newP, @
            @p = newP

        @circle.x = @p.x
        @circle.y = @p.y

        # Cast
        if @startCastTime?
            realCastTime = Utils.game.speedInverse(Skills[@castedSkill].castTime)
            if newTime - @startCastTime > realCastTime
                @startCastTime = null

                castAngle = @p.angle @castP

                edgeP = @p.bearing castAngle, @maxCastRadius

                # handle edgecase where castPoint was within casting circle
                if @castP.within @p, @maxCastRadius
                    @castP = edgeP.bearing castAngle, 0.1

                @arena.addProjectile edgeP, @castP, Skills[@castedSkill], @team

                @_lastCasted[@castedSkill] = newTime

        @time = newTime

    render: (canvas) ->
        # Cast

        # Location

        ctx.filledCircle @p, @radius, @arena.teams[@team].color

        # casting circle

class AIPlayer extends ProtoPlayer
    constructor: (@arena, @handler, startP, team) ->
        super @arena, startP, team

    update: (newTime) ->
        super newTime
        otherPs = _.reject _.values(@handler.players), team: @team

        if Math.random() < Utils.game.speed(0.005) and not @startCastTime?
            @handler.fire @, _.sample(otherPs).p, 'orb'

        chanceToMove = Math.random() < Utils.game.speed(0.03)
        if not @startCastTime? and (chanceToMove or @p.equal @destP)
            @handler.moveTo @, @arena.map.randomPoint()

class UIPlayer extends ProtoPlayer
    constructor: (@arena, @handler, startP, team) ->
        super @arena, startP, team

        @keyBindings =
            g: 'orb'
            h: 'flame'
            b: 'gun'
            n: 'bomb'
            j: 'interrupt'
        addEventListener "mousedown", (event) =>
            topLeft = new Point @radius, @radius
            bottomRight = @arena.map.size.subtract topLeft

            p = @arena.map.mapMouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo @, p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                castP = @arena.map.mapMouseP.mapBound @p, @arena.map
                @handler.fire @, castP, skill
            else
                console.log event
                console.log event.which

module.exports = {
    AIPlayer,
    ProtoPlayer,
    UIPlayer,
}
