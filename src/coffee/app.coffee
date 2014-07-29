canvas = document.getElementById 'canvas'
offscreenCanvas = document.createElement 'canvas'

canvas.width = window.innerWidth
canvas.height = window.innerHeight
offscreenCanvas.width = canvas.width
offscreenCanvas.height = canvas.height

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

ctx = canvas.getContext '2d'

ctxOffscreen = offscreenCanvas.getContext '2d'


class Player

    constructor: (@arena, @time) ->
        @cone = Math.PI / 4
        @radius = 20
        @x = @destX = 300
        @y = @destY = 300
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castX = null
        @castY = null
        @castTime = 600 # ms

    moveTo: (@destX,@destY) ->
        @startCastTime = null

    fire: (@castX, @castY) ->
        # stop moving to fire
        @destX = @x
        @destY = @y
        @startCastTime = @time # needs to be passed through


    draw: (ctx) ->

        maxCastRadius = (@radius+3+@radius)

        # Cast
        if @startCastTime?
            radiusMs = maxCastRadius / @castTime
            radius = radiusMs * (@time - @startCastTime)

            diffY = @castY - @y
            diffX = @castX - @x
            angle = Math.atan2 diffY, diffX

            ctx.beginPath()
            ctx.moveTo @x, @y
            ctx.arc @x, @y, radius, angle-(@cone/2), angle + (@cone/2)
            ctx.moveTo @x, @y
            ctx.lineWidth = 3
            ctx.fillStyle = "#aa0000"
            ctx.fill()



        # Location
        ctx.beginPath()
        ctx.moveTo (@x + @radius), @y
        ctx.arc @x, @y, @radius, 0, 2*Math.PI
        ctx.lineWidth = 3
        ctx.strokeStyle = "#000000"
        ctx.stroke()

        # casting circle

        ctx.beginPath()
        ctx.moveTo (@x + maxCastRadius), @y
        ctx.arc @x, @y, maxCastRadius, 0, 2*Math.PI
        ctx.lineWidth = 1
        ctx.setLineDash [3,7]
        ctx.strokeStyle = "#bbbbbb"
        ctx.stroke()
        ctx.setLineDash []


    update: (newTime) ->
        msDiff = newTime - @time

        # Location

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

        # Cast

        if @startCastTime?
            if newTime - @startCastTime > @castTime
                @startCastTime = null

        @time = newTime


class Arena

    constructor: ->
        @startTime = new Date().getTime()
        @p1 = new Player @, @startTime

        addEventListener "mousedown", (event) =>
            if event.which is 3
                @p1.moveTo event.x, event.y
            else if event.which is 1
                @p1.fire event.x, event.y

        @loop()

    loop: =>
        setTimeout @loop, 20
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        @p1.update new Date().getTime()

    render: ->
      
        ctxOffscreen.clearRect 0, 0, canvas.width, canvas.height
        
        @p1.draw ctxOffscreen
        
        ctx.clearRect 0, 0, canvas.width, canvas.height
        ctx.drawImage offscreenCanvas, 0, 0

arena = new Arena()
