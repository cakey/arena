_ = require 'lodash'

GameState = require "../lib/game-state"
Config = require "../lib/config"
Gfx = require "./gfx"
Camera = require "./camera"
Handlers = require "./handlers"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer
AIPlayer = Player.AIPlayer

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

render = =>
    requestAnimFrame render
    gfx.render gameState, handler

camera = new Camera()
gfx = new Gfx 'render-area'
gameState = new GameState new Date().getTime()

handler = new Handlers.Client gameState, camera
handler.ready().then ->
    try
        randomPoint = gameState.map.randomPoint()
        gameState.addTeam "red", 0xaa3333
        gameState.addTeam "blue", 0x3333aa

        randomTeam = _.sample((name for name, r of gameState.teams))
        handler.focusedUIPlayer = new UIPlayer gameState, handler, randomPoint, randomTeam
        handler.registerLocal handler.focusedUIPlayer

        if Config.game.numAIs > 0
            gameState.addTeam "yellowAI", 0xddaa44
            gameState.addTeam "greenAI", 0x33aa33

        handler.startLoop()
    catch e
        console.log e.message
        console.log e.stack

requestAnimFrame render
