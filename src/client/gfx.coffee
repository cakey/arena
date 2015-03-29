_ = require 'lodash'

Point = require "../lib/point"
ReactRenderer = require "./react-renderer"
Utils = require "../lib/utils"
Skills = require "../lib/skills"
Config = require "../lib/config"

toRad = (p_angle) ->
    return (p_angle - 90) * Math.PI / 180

PIXI.Graphics.prototype.drawArc = (p_x, p_y, p_radius, p_startAngle, p_endAngle) ->
    totalAngle = p_endAngle - p_startAngle
    segments = Math.ceil Math.abs(Math.sqrt(1 - Math.pow (1 - Math.min(p_radius / 60, 1)), 2) * totalAngle * p_radius * 0.01)
    anglePerSegment = totalAngle / segments

    for index in [1..segments]
        x = p_x + Math.cos(toRad(p_startAngle + (anglePerSegment * index))) * p_radius
        y = p_y + Math.sin(toRad(p_startAngle + (anglePerSegment * index))) * p_radius
        @.lineTo x, y

    return @

class Gfx
    constructor: (@id) ->
        # Set up the canvas.
        @renderElement = document.getElementById @id
        @renderElement.width = window.innerWidth
        @renderElement.height = window.innerHeight
        @stage = new PIXI.Stage 0xCCCCCC
        @container = new PIXI.DisplayObjectContainer
        @stage.addChild @container
        @renderer = new PIXI.autoDetectRenderer @renderElement.width, @renderElement.height, {antialias: true}
        @renderElement.appendChild @renderer.view

        # TODO: fix resizing the renderer.
        onResize = =>
            @renderElement.width = window.innerWidth
            @renderElement.height = window.innerHeight
            @renderer.resize @renderElement.width, @renderElement.height

        window.onresize = _.throttle onResize, 50

        # Render variables.
        @playerCounter = 0
        @projectileCounter = 0
        @players = []
        @projectiles = []
        @addMap()

    # Main render function. Called from outside each game loop.
    render: (gameState) ->

        # # Render map.
        # @stage.update()

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

        # Render stage.
        @renderer.render @stage

        # Render react UI.
        ReactRenderer.arena gameState, @canvas

    moveCameraTo: (x, y) ->
        @container.x = x
        @container.y = y

    #
    # Map.
    #
    addMap: () ->
        @map = new PIXI.Graphics()
        @map.beginFill(0xf3f3f3, 1).lineStyle(6, 0x558893, 1).
            drawRect(0, 0, Config.game.width, Config.game.height)
        @container.addChild @map

    #
    # Player.
    #
    addPlayer: (player) ->
        player.gfxId = @playerCounter++
        playerShape = new PIXI.Graphics()
        playerShape.beginFill(player.arena.teams[player.team].color).
            drawCircle(0, 0, player.radius)
        castArc = new PIXI.Graphics()
        @container.addChild playerShape
        @container.addChildAt castArc, 1

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
        castArc.clear()
        if player.startCastTime?
            realCastTime = Utils.game.speedInverse(Skills[player.castedSkill].castTime)
            radiusMs = player.radius / realCastTime
            radius = (radiusMs * (player.time - player.startCastTime)) + player.radius

            castArc.beginFill(Skills[player.castedSkill].hexcolor).
                moveTo(player.p.x, player.p.y).
                arc(player.p.x, player.p.y, radius, player.angle - player.halfCone, player.angle + player.halfCone).
                lineTo(player.p.x, player.p.y)

    removePlayer: ->

    #
    # Projectile.
    #
    addProjectile: (projectile) ->
        projectile.gfxId = @projectileCounter++
        proj = new PIXI.Graphics()
        proj.beginFill(projectile.skill.hexcolor).
            lineStyle(1, projectile.arena.teams[projectile.team].color, 1).
            drawCircle(0, 0, projectile.skill.radius)
        proj.x = projectile.p.x
        proj.y = projectile.p.y
        @container.addChild proj
        @projectiles[projectile.gfxId] = proj

    updateProjectile: (projectile) ->
        p = @projectiles[projectile.gfxId]
        p.x = projectile.p.x
        p.y = projectile.p.y

    removeProjectile: (projectile) ->
        @container.removeChild @projectiles[projectile.gfxId]
        delete @projectiles[projectile.gfxId]

module.exports = Gfx
