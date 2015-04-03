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
gameState = new GameState new Date().getTime()

handler = new Handlers.Client gameState, canvas, camera
handler.ready().then ->
    try
        randomPoint = gameState.map.randomPoint()
        gameState.addTeam "red", "#aa3333"
        gameState.addTeam "blue", "#3333aa"

        randomTeam = _.sample((name for name, r of gameState.teams))
        handler.focusedUIPlayer = new UIPlayer gameState, handler, randomPoint, randomTeam
        handler.registerLocal handler.focusedUIPlayer

        if Config.game.numAIs > 0
            gameState.addTeam "yellowAI", "#ddaa44"
            gameState.addTeam "greenAI", "#33aa33"

        for a in [0...Config.game.numAIs]
            aip1 = new AIPlayer handler, gameState.map.randomPoint(), "yellowAI"
            handler.registerLocal aip1, true
            aip2 = new AIPlayer handler, gameState.map.randomPoint(), "greenAI"
            handler.registerLocal aip2, true

        handler.startLoop()
    catch e
        console.log e.message
        console.log e.stack
