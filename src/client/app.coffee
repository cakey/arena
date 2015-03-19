# TODO:
# interrupt skill with cooldown
# UI for cooldown / skills
# health
# heal
# shield / reversal

_ = require 'lodash'

uuid = require 'node-uuid'
# Utils = require "../lib/utils"
Skills = require "../lib/skills"

Point = require "../lib/point"
Config = require "../lib/config"
Utils = require "../lib/utils"

Canvas = require "./canvas"
Renderers = require "./renderers"
Handlers = require "./handlers"
# Player = require "../lib/player"
# AIPlayer = require "./game-element"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

# class AIPlayer

#     constructor: (@arena, @handler, startP, team) ->
#         @player = new Player @arena, startP, team
#         console.log @

#     update: (newTime) ->

#         otherPs = _.reject _.values(@handler.players), team: @player.team

#         if Math.random() < Utils.game.speed(0.005) and not @player.startCastTime?
#             @handler.fire @player, _.sample(otherPs).p, 'orb'

#         chanceToMove = Math.random() < Utils.game.speed(0.03)
#         if not @player.startCastTime?
# and (chanceToMove or @player.p.equal @player.destP)
#             @handler.moveTo @player, @arena.map.randomPoint()

class UIElement
    # Constuctor takes @name so that other unimplemented functions
    # can give meaningful messages. Elements should super this.
    constructor: (@name) ->

    # Render function required, should receive the canvas.
    render: ->
        console.log "Drawing " + @name

    # Clear function required, should receive the canvas.
    clear: ->
        console.log "Clearing " + @name

    # Update function for updating the elements logical status.
    update: ->
        console.log "Updating " + @name

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

    render: ->
        super()

    clear: ->
        super()

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

    moveTo: (@destP) ->
        super @destP

    pctCooldown: (castedSkill) ->
        super castedSkill

    fire: (@castP, @castedSkill) ->
        super @castP, @castedSkill

    # No place actually uses the update from Player?
    # update: (newTime) ->
    #     super newTime

    render: ->
        super()

    clear: ->
        super()

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

            p = @arena.mapMouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo @, p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                castP = @arena.mapMouseP.mapBound @p, @arena.map
                @handler.fire @, castP, skill
            else
                console.log event
                console.log event.which

    update: (newTime) ->
        super newTimen

    moveTo: (@destP) ->
        super @destP

    pctCooldown: (castedSkill) ->
        super castedSkill

    fire: (@castP, @castedSkill) ->
        super @castP, @castedSkill

    render: ->
        super()

    clear: ->
        super()

# class UIPlayer

#     constructor: (@arena, @handler, startP, team) ->
#         @player = new Player @arena, startP, team

#         @keyBindings =
#             g: 'orb'
#             h: 'flame'
#             b: 'gun'
#             n: 'bomb'
#             j: 'interrupt'
#         addEventListener "mousedown", (event) =>
#             topLeft = new Point @player.radius, @player.radius
#             bottomRight = @arena.map.size.subtract topLeft

#             p = @arena.mapMouseP.bound topLeft, bottomRight

#             if event.which is 3
#                 @handler.moveTo @player, p

#         addEventListener "keypress", (event) =>

#             if skill = @keyBindings[String.fromCharCode event.which]
#                 castP = @arena.mapMouseP.mapBound @player.p, @arena.map
#                 @handler.fire @player, castP, skill
#             else
#                 console.log event
#                 console.log event.which

#     update: (newTime) ->

class Projectile

    constructor: (@arena, @time, @p, dirP, @skill, @team) ->
        angle = @p.angle dirP
        @destP = @p.bearing angle, @skill.range

    update: (newTime) ->

        if @p.equal @destP
            return false

        msDiff = newTime - @time

        @p = @p.towards @destP, (Utils.game.speed(@skill.speed) * msDiff)

        @time = newTime
        return true

# TODO pull out update parts of arena and player to allow running on the server
class Arena

    constructor: (@canvas) ->
        @time = new Date().getTime()

        @map =
            p: new Point 25, 25
            size: new Point Config.game.width, Config.game.height
            wallSize: new Point 6, 6
            randomPoint: =>
                new Point _.random(0, @map.size.x), _.random(0, @map.size.y)

        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0

        @projectiles = []
        @cameraSpeed = 0.3

        @mapMouseP = new Point 0, 0
        @mouseP = new Point 0, 0

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        addEventListener "mousemove", (event) =>
            @mouseP = Point.fromObject event
            @mapMouseP = @mouseP.subtract(@map.p).subtract(@map.wallSize)

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards Point.fromObject(event), 100

        @handler = new Handlers.Network @
        readyPromise = @handler.ready()
        readyPromise.then =>

            randomPoint = @map.randomPoint()
            randomTeam = _.sample((name for name, r of @teams))

            @focusedUIPlayer = new UIPlayer this, @handler, randomPoint, randomTeam
            @handler.registerLocal @focusedUIPlayer

            if Config.game.numAIs > 0
                @teams.greenAI =
                    color: "#33aa33"
                    score: 0
                @teams.yellowAI =
                    color: "#ddaa44"
                    score: 0

            for a in [0...Config.game.numAIs]
                aip1 = new AIPlayer @, @handler, @map.randomPoint(), "yellowAI"
                @handler.registerLocal aip1
                aip2 = new AIPlayer @, @handler, @map.randomPoint(), "greenAI"
                @handler.registerLocal aip2

            @loop()

    render: ->
        @canvas.begin()
        Renderers.arena @, @canvas
        @canvas.end()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    allowedMovement: (newP, player) ->

        # TODO: n^2? seriously?

        currentUnallowed = 0
        newUnallowed = 0

        for otherId, otherPlayer of @handler.players
            if otherId isnt player.id
                currentD = player.p.distance otherPlayer.p
                newD = newP.distance otherPlayer.p
                minimum = player.radius + otherPlayer.radius
                if currentD < minimum
                    currentUnallowed += (minimum - currentD)
                if newD < minimum
                    newUnallowed += (minimum - newD)

        allowed = newUnallowed <= currentUnallowed

        # stickiness parameter (less likely to get caught on an edge)
        if 0 < newUnallowed < 2
            return true

        return allowed

    projectileCollide: (p) ->
        # for each other team
        # check if projectile hits a player
        # if so increment owner of projechtile score
        # otherwise add to newProjectiles
        for id, player of @handler.players
            if p.team isnt player.team
                return player if p.p.within player.p, p.skill.radius + player.radius
        return false

    loop: =>
        setTimeout @loop, 5
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        updateTime = new Date().getTime()

        msDiff = updateTime - @time

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @map.p = @map.p.subtract moveVector

        for processor in @handler.locallyProcessed
            processor.update updateTime

        for id, player of @handler.players
            player.update updateTime

        newProjectiles = []
        for projectile in @projectiles
            alive = projectile.update updateTime
            withinMap = (
                projectile.p.x > 0 and
                projectile.p.y > 0 and
                projectile.p.x < @map.size.x and
                projectile.p.y < @map.size.y)
            if alive and withinMap
                if hitPlayer = @projectileCollide projectile
                    skill = projectile.skill
                    @teams[projectile.team].score += skill.score
                    @teams[hitPlayer.team].score -= skill.score
                    if skill.hitPlayer?
                        skill.hitPlayer hitPlayer, projectile
                    if skill.continue
                        newProjectiles.push projectile

                else
                    newProjectiles.push projectile
        @projectiles = newProjectiles

        @time = updateTime

#TODO:
canvas = new Canvas 'canvas'
arena = new Arena canvas
