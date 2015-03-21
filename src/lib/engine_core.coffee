# Core game engine
_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"
Utils = require "../lib/utils"
Player = require "../lib/player"

class AIPlayer

    constructor: (@arena, @handler, startP, team) ->
        @player = new Player @arena, startP, team

    update: (newTime) ->

        otherPs = _.reject _.values(@handler.players), team: @player.team

        if Math.random() < Utils.game.speed(0.005) and not @player.startCastTime?
            @handler.fire @player, _.sample(otherPs).p, 'orb'

        chanceToMove = Math.random() < Utils.game.speed(0.03)
        if not @player.startCastTime? and (chanceToMove or @player.p.equal @player.destP)
            @handler.moveTo @player, @arena.map.randomPoint()

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

class Arena

    constructor: ->
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

    onReady: (player, loopCallback = null) ->
        randomPoint = @map.randomPoint()
        randomTeam = _.sample((name for name, r of @teams))

        player.player.destP = player.player.p = randomPoint
        player.player.team = randomTeam
        @handler.registerLocal player

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

        @loop loopCallback

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

    loop: (callback) =>
        setTimeout @loop, 5, callback
        # TODO: A non sucky game loop...
        # Fixed time updates.
        callback() if callback
        @update()

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

module.exports = { Projectile, AIPlayer, Arena }

