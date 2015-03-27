_ = require 'lodash'

GameState = require "../lib/game-state"
Config = require "../lib/config"
Canvas = require "./canvas"
Camera = require "./camera"
Handlers = require "./handlers"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer
AIPlayer = Player.AIPlayer

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

camera = new Camera()
canvas = new Canvas 'canvas'
gameState = new GameState
    shouldRender: true
    canvas: canvas
    camera: camera

handler = new Handlers.Client gameState
handler.ready().then ->
    try
        randomPoint = gameState.map.randomPoint()
        gameState.addTeam "red", "#aa3333"
        gameState.addTeam "blue", "#3333aa"

        randomTeam = _.sample((name for name, r of gameState.teams))
        gameState.focusedUIPlayer = new UIPlayer gameState, handler, randomPoint, randomTeam
        handler.registerLocal gameState.focusedUIPlayer

        if Config.game.numAIs > 0
            gameState.addTeam "yellowAI", "#ddaa44"
            gameState.addTeam "greenAI", "#33aa33"

        for a in [0...Config.game.numAIs]
            aip1 = new AIPlayer gameState, handler, gameState.map.randomPoint(), "yellowAI"
            handler.registerLocal aip1, true
            aip2 = new AIPlayer gameState, handler, gameState.map.randomPoint(), "greenAI"
            handler.registerLocal aip2, true

        handler.loop()
    catch e
        console.log e.message
        console.log e.stack
