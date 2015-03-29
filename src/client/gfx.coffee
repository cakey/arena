_ = require 'lodash'

Point = require "../lib/point"
ReactRenderer = require "./react-renderer"
Utils = require "../lib/utils"
Skills = require "../lib/skills"
Config = require "../lib/config"

class Gfx
    constructor: (@id) ->
        # Set up the canvas.
        @stage = new createjs.Stage @id
        @stage.canvas.width = window.innerWidth
        @stage.canvas.height = window.innerHeight
        @stage.setTransform 25, 25

        onResize = =>
            @stage.canvas.width = window.innerWidth
            @stage.canvas.height = window.innerHeight

        window.onresize = _.throttle onResize, 50

        @cameraOffset = new Point 25, 25

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @cameraOffset = new Point event.x, event.y
                @stage.setTransform event.x, event.y

        @mousePosition = new Point 0, 0

        addEventListener "mousemove", (event) =>
            eventPosition = Point.fromObject event
            @mousePosition = eventPosition.subtract @cameraOffset

        # Render variables.
        @playerCounter = 0
        @projectileCounter = 0
        @players = []
        @projectiles = []
        @addMap()

    # Main render function. Called from outside each game loop.
    render: (gameState) ->
        # Render map.
        @stage.update()

        # Render Players.
        for player in gameState.newPlayers
            @addPlayer player
        gameState.newPlayers = []
        for id, player of gameState.handler.players
            @updatePlayer player

        # Render projectiles.
        for p in gameState.toAddProjectiles
            @addProjectile p
        gameState.toAddProjectiles = []
        for p in gameState.projectiles
            @updateProjectile p
        for p in gameState.toRemoveProjectiles
            @removeProjectile p
        gameState.toRemoveProjectiles = []

        # Render react UI.
        ReactRenderer.arena gameState, @canvas

    #
    # Map.
    #
    addMap: () ->
        @map = new createjs.Shape()
        @map.graphics.beginFill("#f3f3f3").beginStroke("#558893").
            setStrokeStyle(6).
            drawRect(0, 0, Config.game.width, Config.game.height)
        @stage.addChild @map

    #
    # Player.
    #
    addPlayer: (player) ->
        player.gfxId = @playerCounter++
        playerShape = new createjs.Shape()
        playerShape.graphics.beginFill(player.arena.teams[player.team].color).
            drawCircle(0, 0, player.radius)
        @stage.addChild playerShape
        castArc = new createjs.Shape()
        @stage.addChildAt castArc, 1
        @players[player.gfxId] =
            playerBody: playerShape
            castArc: castArc

    updatePlayer: (player) ->
        playerBody = @players[player.gfxId].playerBody
        # Move player circle.
        playerBody.x = player.p.x
        playerBody.y = player.p.y

        # Cast
        castArc = @players[player.gfxId].castArc
        castArc.graphics.clear()
        if player.startCastTime?
            realCastTime = Utils.game.speedInverse(Skills[player.castedSkill].castTime)
            radiusMs = player.radius / realCastTime
            radius = (radiusMs * (player.time - player.startCastTime)) + player.radius

            castArc.graphics.clear()
            castArc.graphics.beginFill(Skills[player.castedSkill].color).
                arc(player.p.x, player.p.y, radius, player.angle - player.halfCone, player.angle + player.halfCone).
                lineTo(player.p.x, player.p.y).closePath()

    removePlayer: ->

    #
    # Projectile.
    #
    addProjectile: (projectile) ->
        projectile.gfxId = @projectileCounter++
        proj = new createjs.Shape()
        proj.graphics.beginFill(projectile.skill.color).
            beginStroke(projectile.arena.teams[projectile.team].color).
            setStrokeStyle(1).
            drawCircle(0, 0, projectile.skill.radius)
        proj.x = projectile.p.x
        proj.y = projectile.p.y
        @stage.addChild proj
        @projectiles[projectile.gfxId] = proj

    updateProjectile: (projectile) ->
        p = @projectiles[projectile.gfxId]
        p.x = projectile.p.x
        p.y = projectile.p.y

    removeProjectile: (projectile) ->
        @stage.removeChild @projectiles[projectile.gfxId]
        delete @projectiles[projectile.gfxId]

module.exports = Gfx
