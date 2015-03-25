_ = require 'lodash'

Config = require "./config"
Point = require "./point"
Player = require "./player"
UIPlayer = Player.UIPlayer
AIPlayer = Player.AIPlayer
Projectile = require "./projectile"
Arena = require "./arena"
Renderers = require "../client/renderers"
Handlers = require "../client/handlers"

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (options) ->
        {@shouldRender, @canvas} = options
        @time = new Date().getTime()

        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0

        @projectiles = []
        @map = new Arena

        @handler = new Handlers.Client @
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
        # Clear the canvas.
        @canvas.begin()

        # Render all the things.
        Renderers.arena @, @canvas

        # Nothing right now.
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
        if @shouldRender
            @render()

    update: ->
        updateTime = new Date().getTime()
        msDiff = updateTime - @time

        # Map.
        @map.update msDiff

        # Players.
        for processor in @handler.locallyProcessed
            processor.update updateTime

        for id, player of @handler.players
            player.update updateTime

        # Projectiles.
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

module.exports = GameState
