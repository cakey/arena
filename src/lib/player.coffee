_ = require 'lodash'
uuid = require 'node-uuid'

Utils = require "../lib/utils"
Skills = require "../lib/skills"
Point = require "../lib/point"
Config = require "../lib/config"

class BasePlayer
    constructor: (@p, @team)->
        @id = uuid.v4()

class GamePlayer
    constructor: (initTime, @p, @team, @id) ->
        @time = initTime
        @radius = 20
        @maxCastRadius = @radius * 2
        @destP = @p
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castP = null
        @alive = true

        @_lastCasted = {}

        if not @id?
            @id = uuid.v4()

    kill: (spawnLocation) ->
        @alive = false
        @p = @destP = spawnLocation
        @castP = null
        @startCastTime = null

    respawn: ->
        @alive = true

    moveTo: (destP) ->
        if @alive
            @destP = destP
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

    fire: (castP, castedSkill) ->
        if @alive
            @castP = castP
            @castedSkill = castedSkill

            # first check cool down
            pctCooldown = @pctCooldown @castedSkill

            if pctCooldown >= 1
                # stop moving to fire
                if Skills[@castedSkill].channeled
                    @destP = @p
                @startCastTime = @time # needs to be passed through

    update: (newTime, gameState) ->
        msDiff = newTime - @time
        if @alive
            # Location
            newP = @p.towards @destP, (Utils.game.speed(@speed) * msDiff)
            if gameState.allowedMovement newP, @
                @p = newP

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

                    gameState.addProjectile edgeP, @castP, Skills[@castedSkill], @team

                @_lastCasted[@castedSkill] = newTime

        @time = newTime

    render: (ctx, gameState, focused) ->
        # Cast
        if @startCastTime? and @alive
            realCastTime = Utils.game.speedInverse(Skills[@castedSkill].castTime)
            radiusMs = @radius / realCastTime
            radius = (radiusMs * (@time - @startCastTime)) + @radius

            angle = @p.angle @castP
            halfCone = Skills[@castedSkill].cone / 2

            ctx.beginPath()
            ctx.moveTo @p
            ctx.arc @p, radius, angle - halfCone, angle + halfCone
            ctx.moveTo @p
            ctx.fillStyle Skills[@castedSkill].color
            ctx.fill()

        # Location
        if @alive
            ctx.filledCircle @p, @radius, gameState.teams[@team].color
        else
            deathTime = gameState.deadPlayerIds[@id]
            pctRespawn = (@time - deathTime) / Config.game.respawnTime
            ctx.filledCircle @p, (@radius-1), Config.colors.barrierBrown
            ctx.filledCircle @p, (@radius * pctRespawn), gameState.teams[@team].color

        if focused
            ctx.filledCircle @p, 3, "#000000"


        # casting circle
        if Config.UI.castingCircles
            ctx.beginPath()
            ctx.circle @p, @maxCastRadius
            ctx.lineWidth 1
            ctx.setLineDash [3,12]
            ctx.strokeStyle "#777777"
            ctx.stroke()
            ctx.setLineDash []

class AIPlayer extends BasePlayer
    constructor: (@handler, startP, team) ->
        super startP, team

    update: (newTime, gameState) ->
        self = gameState.players[@id]
        if not self?
            # AIPlayer hasn't registered with gameState via server yet
            return
        if self.alive
            otherPs = _.reject _.values(gameState.players), team: @team
            otherPs = _.reject otherPs, alive: false

            if otherPs.length > 0
                if Math.random() < Utils.game.speed(0.005) and not self.startCastTime?
                    @handler.triggerFire @, _.sample(otherPs).p, 'bomb'

            chanceToMove = Math.random() < Utils.game.speed(0.03)
            if not self.startCastTime? and (chanceToMove or self.p.equal self.destP)
                @handler.triggerMoveTo @, gameState.map.randomPoint()

class UIPlayer extends BasePlayer
    constructor: (@gameState, @handler, startP, team) ->
        super startP, team
        @keyBindings =
            g: 'orb'
            h: 'flame'
            b: 'gun'
            n: 'bomb'
            j: 'interrupt'
        addEventListener "mousedown", (event) =>
            radius = @gameState.players[@id].radius
            topLeft = new Point radius, radius
            bottomRight = @gameState.map.size.subtract topLeft

            p = @handler.camera.mapMouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.triggerMoveTo @, p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                castP = @handler.camera.mapMouseP.mapBound @p, @gameState.map
                @handler.triggerFire @, castP, skill
            else
                console.log event
                console.log event.which

module.exports = {
    AIPlayer,
    GamePlayer,
    UIPlayer,
}
