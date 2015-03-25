GameState = require "../lib/game-state"
Canvas = require "./canvas"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

canvas = new Canvas 'canvas'
gameState = new GameState
    shouldRender: true
    canvas: canvas
