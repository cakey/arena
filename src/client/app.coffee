# TODO:
# interrupt skill with cooldown
# UI for cooldown / skills
# health
# heal
# shield / reversal

_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer
AIPlayer = Player.AIPlayer
Projectile = require "../lib/projectile"

Canvas = require "./canvas"
Renderers = require "./renderers"
Handlers = require "./handlers"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

# TODO pull out update parts of arena and player to allow running on the server
# TODO: separate out the game loop logic from the arena logic.

class Arena
    constructor: ->
        @p = new Point 25, 25
        @size = new Point Config.game.width, Config.game.height
        @wallSize = new Point 6, 6

        @mapMouseP = new Point 0, 0
        @mouseP = new Point 0, 0

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        @cameraSpeed = 0.3

        addEventListener "mousemove", (event) =>
            @mouseP = Point.fromObject event
            @mapMouseP = @mouseP.subtract(@p).subtract(@wallSize)

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards Point.fromObject(event), 100

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    update: (msDiff) ->
        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @p = @p.subtract moveVector

    render: ->

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
        @canvas.begin()
        # TODO make this loop over our players/projectiles/arena rendering.
        # This shouldn't cascade with arena renders players etc.
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
