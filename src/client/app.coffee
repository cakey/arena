_ = require 'lodash'

GameState = require "../lib/game-state"
Canvas = require "./canvas"
Camera = require "./camera"
Handlers = require "./handlers"
Player = require "../lib/player"
UIPlayer = Player.UIPlayer

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
        randomTeam = _.sample((name for name, r of gameState.teams))
        gameState.focusedUIPlayer = new UIPlayer gameState, handler, randomPoint, randomTeam
        handler.registerLocal gameState.focusedUIPlayer
        handler.loop()
    catch e
        console.log e.message
        console.log e.stack
