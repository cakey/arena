ReactRenderer = require "./react-renderer"
Utils = require "../lib/utils"
Skills = require "../lib/skills"
Config = require "../lib/config"

class Gfx
    constructor: (@canvas) ->
        @playerCounter = 0
        @projectileCounter = 0
        @players = []
        @addMap()

    # Main render function. Called from outside each game loop.
    render: (gameState) ->
        # Render map.
        @canvas.stage.update()

        # Render Players.
        for player in gameState.newPlayers
            @addPlayer player
            gameState.newPlayers = []
        for id, player of gameState.handler.players
            @updatePlayer player

        # Render projectiles.
        for p in gameState.projectiles
            p.render()

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
        @canvas.stage.addChild @map

    #
    # Player.
    #
    addPlayer: (player) ->
        player.gfxId = @playerCounter++
        playerShape = new createjs.Shape()
        playerShape.graphics.beginFill(player.arena.teams[player.team].color).
            drawCircle(0, 0, player.radius)
        @canvas.stage.addChild playerShape
        castArc = new createjs.Shape()
        @canvas.stage.addChildAt castArc, 1
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
    addProjectile: ->



module.exports = Gfx
