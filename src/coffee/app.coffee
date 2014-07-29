canvas = document.getElementById 'canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

ctx = canvas.getContext '2d'

ctx.beginPath()
ctx.arc 100, 100, 20, 0, 2*Math.PI
ctx.stroke()

canvas.addEventListener "mouseup", (event) ->
    ctx.clearRect 0, 0, canvas.width, canvas.height
    ctx.beginPath()
    ctx.moveTo (event.x+20), event.y
    ctx.arc (event.x), event.y, 20, 0, 2*Math.PI
    ctx.stroke()
