canvas = document.getElementById 'canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

ctx = canvas.getContext '2d'

class Player
    radius = 20

    constructor: ->
        @x = 100
        @y = 100

    moveTo: (@x,@y) ->

    draw: (ctx) ->
        ctx.beginPath()
        ctx.moveTo (@x+20), @y
        ctx.arc @x, @y, 20, 0, 2*Math.PI
        ctx.lineWidth = 3
        ctx.stroke()

class Arena

    constructor: ->
        @p1 = new Player()
        @render()

        addEventListener "mousedown", (event) =>
            @p1.moveTo event.x, event.y
            @render()

    render: ->
        ctx.clearRect 0, 0, canvas.width, canvas.height
        @p1.draw ctx

arena = new Arena()
