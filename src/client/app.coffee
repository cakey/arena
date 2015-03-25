GameState = require "../lib/game-state"
Canvas = require "./canvas"
Camera = require "./camera"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

camera = new Camera()
canvas = new Canvas 'canvas'
gameState = new GameState
    shouldRender: true
    canvas: canvas
    camera: camera
