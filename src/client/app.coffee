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

Gfx = require "./gfx"
Handlers = require "./handlers"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (@canvas) ->
        @cameraOffset = new Point 25, 25
        # @canvas.moveCameraTo @cameraOffset.x, @cameraOffset.y
        @mousePosition = new Point 0, 0

        @time = new Date().getTime()

        @teams =
            red:
                color: 0xaa3333
                score: 0
            blue:
                color: 0x3333aa
                score: 0

        @projectiles = []
        @map = new Arena
        @newPlayers = []
        @toAddProjectiles = []
        @toRemoveProjectiles = []

        @handler = new Handlers.Network @
        readyPromise = @handler.ready()
        readyPromise.then =>

            randomPoint = @map.randomPoint()
            randomTeam = _.sample((name for name, r of @teams))

            @focusedUIPlayer = new UIPlayer this, @handler, randomPoint, randomTeam
            @handler.registerLocal @focusedUIPlayer
            @newPlayers.push @focusedUIPlayer

            if Config.game.numAIs > 0
                @teams.greenAI =
                    color: 0x33aa33
                    score: 0
                @teams.yellowAI =
                    color: 0xddaa44
                    score: 0

            for a in [0...Config.game.numAIs]
                aip1 = new AIPlayer @, @handler, @map.randomPoint(), "yellowAI"
                @handler.registerLocal aip1
                @newPlayers.push aip1
                aip2 = new AIPlayer @, @handler, @map.randomPoint(), "greenAI"
                @handler.registerLocal aip2
                @newPlayers.push aip2

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @toAddProjectiles.push p
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
                    @toRemoveProjectiles.push projectile
                    skill = projectile.skill
                    @teams[projectile.team].score += skill.score
                    @teams[hitPlayer.team].score -= skill.score
                    if skill.hitPlayer?
                        skill.hitPlayer hitPlayer, projectile
                    if skill.continue
                        newProjectiles.push projectile
                else
                    newProjectiles.push projectile
            else
                @toRemoveProjectiles.push projectile

        @projectiles = newProjectiles

        @time = updateTime

gameLoop = =>
    setTimeout gameLoop, 5
    time = new Date().getTime()
    gameState.update()
    stateTime = new Date().getTime()
    console.log "game state update took: " + (stateTime - time)
    gfx.render gameState
    renderTime = new Date().getTime()
    console.log "rendering took: " + (renderTime - stateTime)

gfx = new Gfx 'render-area'
gameState = new GameState gfx

addEventListener "mousedown", (event) =>
    if event.which is 1
        gameState.cameraOffset = new Point event.x, event.y
        gfx.moveCameraTo event.x, event.y

addEventListener "mousemove", (event) =>
    eventPosition = Point.fromObject event
    gameState.mousePosition = eventPosition.subtract gameState.cameraOffset

gameLoop()
