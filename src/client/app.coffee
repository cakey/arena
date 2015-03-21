# TODO:
# interrupt skill with cooldown
# UI for cooldown / skills
# health
# heal
# shield / reversal

_ = require 'lodash'

Config = require "../lib/config"
Point = require "../lib/point"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer
AIPlayer = Player.AIPlayer
Projectile = require "../lib/projectile"
Arena = require "../lib/arena"

Canvas = require "./canvas"
Renderers = require "./renderers"
Handlers = require "./handlers"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (@canvas) ->
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
        console.log @map

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
        #Start
        @canvas.begin()

        ctx = @canvas.mapContext @map
        staticCtx = @canvas.context()

        @map.render ctx

        for id, player of @handler.players
            player.render ctx

        for p in @projectiles
            p.render ctx

        # Leave UI crap here as it's going in favour of react stuff anyway.
        Renderers.ui @focusedUIPlayer, ctx, staticCtx

        # Score
        staticCtx.globalAlpha 0.8

        backLoc = new Point (window.innerWidth - 220), 20
        scoreBoxSize = new Point(200, (Object.keys(@teams).length * 32) + 20)
        Renderers.box backLoc, scoreBoxSize, staticCtx

        staticCtx.font "16px verdana"

        teamKeys = Object.keys(@teams)
        teamKeys.sort (a,b) => @teams[b].score - @teams[a].score

        y = 50
        for name in teamKeys
            location = new Point(window.innerWidth - 200, y)

            staticCtx.fillStyle "#222233"
            staticCtx.fillText name, location

            location = new Point(window.innerWidth - 100, y)

            staticCtx.fillStyle "#444466"
            staticCtx.fillText @teams[name].score, location

            y += 32

        staticCtx.globalAlpha 1
        # End
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

#TODO:
canvas = new Canvas 'canvas'
gameState = new GameState canvas
