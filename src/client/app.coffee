_ = require 'lodash'

GameState = require "../lib/game-state"
Config = require "../lib/config"
Canvas = require "./canvas"
Camera = require "./camera"
Handlers = require "./handlers"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

camera = new Camera()
canvas = new Canvas 'canvas'
gameState = new GameState new Date().getTime()

handler = new Handlers.Client gameState, canvas, camera
handler.ready().then ->
    try
        randomPoint = gameState.map.randomPoint()
        gameState.addTeam "red", Config.colors.red
        gameState.addTeam "blue", Config.colors.blue

        randomTeam = _.sample((name for name, r of gameState.teams))
        handler.focusedUIPlayer = new UIPlayer gameState, handler, randomPoint, randomTeam
        handler.registerLocal handler.focusedUIPlayer

        if Config.game.numAIs > 0
            gameState.addTeam "yellowAI", Config.colors.yellow
            gameState.addTeam "greenAI", Config.colors.green

        handler.startLoop()
    catch e
        console.log e.message
        console.log e.stack
