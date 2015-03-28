ReactRenderer = require "./react-renderer"

class Gfx
    constructor: (@canvas) ->

    render: (gameState) ->
        # Render map.
        gameState.map.render @canvas.state
        @canvas.stage.update()

        # Render Players.
        for id, player of gameState.handler.players
            player.render @canvas

        # Render projectiles.
        for p in gameState.projectiles
            p.render()

        # Render react UI.
        ReactRenderer.arena gameState, @canvas

    # Add functions here to manage graphics like:
    addPlayer: ->
    updatePlayer: ->
    removePlayer: ->


module.exports = Gfx
