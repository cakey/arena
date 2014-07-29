canvas = document.getElementById 'canvas'
canvas.width = window.innerWidth
canvas.height = window.innerHeight

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

ctx = canvas.getContext '2d'

class Player
    radius = 20

    constructor: (@time) ->
        @x = @destX = 300
        @y = @destY = 300
        @speed = 0.2 # pixels/ms

    moveTo: (@destX,@destY) ->

    draw: (ctx) ->
        ctx.beginPath()
        ctx.moveTo (@x+20), @y
        ctx.arc @x, @y, 20, 0, 2*Math.PI
        ctx.lineWidth = 3
        ctx.stroke()

    update: (newTime) ->
        msDiff = newTime - @time

        diffY = @destY - @y
        diffX = @destX - @x
        angle = Math.atan2 diffY, diffX
        ySpeed = Math.sin(angle) * @speed
        xSpeed = Math.cos(angle) * @speed

        maxXTravel = xSpeed * msDiff
        if maxXTravel > Math.abs diffX
            @x = @destX
        else
            @x += maxXTravel

        maxYTravel = ySpeed * msDiff
        if maxYTravel > Math.abs diffY
            @y = @destY
        else
            @y += maxYTravel

        @time = newTime


class Arena

    constructor: ->
        @startTime = new Date().getTime()
        @p1 = new Player @startTime

        addEventListener "mousedown", (event) =>
            @p1.moveTo event.x, event.y

        @loop()

    loop: =>
        setTimeout @loop, 20
        console.log "loop"
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        @p1.update new Date().getTime()

    render: ->
        ctx.clearRect 0, 0, canvas.width, canvas.height
        @p1.draw ctx

arena = new Arena()
