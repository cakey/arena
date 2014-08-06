# todo:
# immutable coordinate
# generalise abilities
# generalise projectiles?
# player extends projectile
# todo: pull out key bindings
# smooth the camera panning by setting a speed for a certain time


utils =
    randInt: (lower, upper=0) ->
        start = Math.random()
        if not lower?
            [lower, upper] = [0, lower]
        if lower > upper
            [lower, upper] = [upper, lower]
        return Math.floor(start * (upper - lower + 1) + lower)


document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false
class Canvas
    constructor: ->
        @canvas = document.getElementById 'canvas'
        @offscreenCanvas = document.createElement 'canvas'

        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @offscreenCanvas.width = @canvas.width
        @offscreenCanvas.height = @canvas.height
        @ctx = @canvas.getContext '2d'
        @ctxOffscreen = @offscreenCanvas.getContext '2d'

    withMap: (map, drawFunc) ->
        =>
            @ctxOffscreen.clearRect 0, 0, @canvas.width, @canvas.height

            o = @ctxOffscreen

            # TODO: not this

            translatedContext =
                beginPath: -> o.beginPath()
                moveTo: (x, y) -> o.moveTo (x+map.x+map.wallSize), (y+map.y+map.wallSize)
                arc: (x, y, args...) -> o.arc (x+map.x+map.wallSize), (y+map.y+map.wallSize), args...
                fillStyle: (arg) -> o.fillStyle = arg
                fill: o.fill.bind o
                lineWidth: (arg) -> o.lineWidth = arg
                setLineDash: o.setLineDash.bind o
                stroke: o.stroke.bind o
                strokeStyle: (arg) -> o.strokeStyle = arg
                strokeRect: (x, y, args...) -> o.strokeRect (x+map.x+map.wallSize), (y+map.y+map.wallSize), args...

            drawFunc translatedContext

            @ctx.clearRect 0, 0, @canvas.width, @canvas.height
            @ctx.drawImage @offscreenCanvas, 0, 0

skills =
    orb:
        cone: Math.PI / 5
        radius: 7
        castTime: 400
        speed: 0.6
        range: 400
        color: "#aa0000"

    disrupt:
        cone: Math.PI / 10
        radius: 3
        castTime: 50
        speed: 3
        range: 800
        color: "#990099"

class Player

    constructor: (@arena, @time, @x, @y) ->
        @radius = 20
        @maxCastRadius = (@radius+3+@radius)
        @destX = @x
        @destY = @y
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castX = null
        @castY = null

    moveTo: (@destX, @destY) ->
        @startCastTime = null

    fire: (@castX, @castY, @castedSkill) ->
        # stop moving to fire
        @destX = @x
        @destY = @y
        @startCastTime = @time # needs to be passed through

    draw: (ctx) ->

        # Cast
        if @startCastTime?
            radiusMs = @radius / @castedSkill.castTime
            radius = (radiusMs * (@time - @startCastTime))+@radius+3

            diffY = @castY - @y
            diffX = @castX - @x
            angle = Math.atan2 diffY, diffX

            ctx.beginPath()
            ctx.moveTo @x, @y
            ctx.arc @x, @y, radius, angle-(@castedSkill.cone/2), angle + (@castedSkill.cone/2)
            ctx.moveTo @x, @y
            ctx.fillStyle @castedSkill.color
            ctx.fill()

        # Location
        ctx.beginPath()
        ctx.moveTo (@x + @radius), @y
        ctx.arc @x, @y, @radius, 0, 2*Math.PI
        ctx.lineWidth 3
        ctx.fillStyle "#aaaacc"
        ctx.fill()

        # casting circle

        ctx.beginPath()
        ctx.moveTo (@x + @maxCastRadius), @y
        ctx.arc @x, @y, @maxCastRadius, 0, 2*Math.PI
        ctx.lineWidth 1
        ctx.setLineDash [3,12]
        ctx.strokeStyle "#777777"
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
            if newTime - @startCastTime > @castedSkill.castTime
                @startCastTime = null

                castAngle = Math.atan2 (@castY - @y), (@castX - @x)

                edgeX = @x + Math.cos(castAngle) * @maxCastRadius
                edgeY = @y + Math.sin(castAngle) * @maxCastRadius

                # handle edgecase where castPoint was within casting circle
                castX = @castX
                castY = @castY
                if @x < castX < edgeX or @x > castX > edgeX
                    castX = edgeX + Math.cos(castAngle)

                if @y < castY < edgeY or @y > castY > edgeY
                    castY = edgeY + Math.sin(castAngle)

                @arena.addProjectile edgeX, edgeY, castX, castY, @castedSkill

        @time = newTime

class AI extends Player

    update: (newTime) ->
        super newTime

        #if @arena.p1.startCastTime? and not @startCastTime?
        #    @fire @arena.p1.x, @arena.p1.y, skills.disrupt

        if Math.random() < 0.005 and not @startCastTime?
            @fire @arena.p1.x, @arena.p1.y, skills.orb

        if not @startCastTime? and (Math.random() < 0.03 or (@x is @destX and @y is @destY))
            @moveTo utils.randInt(0,@arena.map.width), utils.randInt(0,@arena.map.height)
            #@moveTo ((@arena.p1.x+@x)/2)+utils.randInt(-250,250), ((@arena.p1.y+@y)/2)+utils.randInt(-250,250)


class Projectile

    constructor: (@arena, @time, @x, @y, dirX, dirY, @skill) ->
        diffY = dirY - @y
        diffX = dirX - @x
        angle = Math.atan2 diffY, diffX
        ySpeed = Math.sin(angle) * @skill.range
        xSpeed = Math.cos(angle) * @skill.range
        @destX = @x + xSpeed
        @destY = @y + ySpeed

    draw: (ctx) ->

        # Location
        ctx.beginPath()
        ctx.moveTo (@x + @skill.radius), @y
        ctx.arc @x, @y, @skill.radius, 0, 2*Math.PI
        ctx.fillStyle @skill.color
        ctx.fill()

    update: (newTime) ->

        if @x is @destX and @y is @destY
            return false

        msDiff = newTime - @time

        # Location

        diffY = @destY - @y
        diffX = @destX - @x
        angle = Math.atan2 diffY, diffX
        ySpeed = Math.sin(angle) * @skill.speed
        xSpeed = Math.cos(angle) * @skill.speed

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

        @time = newTime
        return true

class Arena

    constructor: (@canvas) ->
        @startTime = new Date().getTime()
        @p1 = new Player @, @startTime, 100, 100
        @ai = new AI @, @startTime, 200, 100
        @projectiles = []
        @cameraSpeed = 100

        @map =
            x: 25
            y: 25
            width: window.innerWidth - 100
            height: window.innerHeight - 100
            wallSize: 10

        addEventListener "mousedown", (event) =>
            x = event.x-@map.x
            y = event.y-@map.y

            if x < 0 + @p1.radius
                x = 0 + @p1.radius
            else if x > @map.width - @p1.radius
                x = @map.width - @p1.radius

            if y < 0  + @p1.radius
                y = 0  + @p1.radius
            else if y > @map.height - @p1.radius
                y = @map.height - @p1.radius

            if event.which is 3
                @p1.moveTo x, y
            else if event.which is 1
                @p1.fire x, y, skills.orb
            else if event.which is 2
                @p1.fire x, y, skills.disrupt

        addEventListener "keypress", (event) =>
            # TODO: naive keyboard camera pan feels far too clunky
            if event.which is 97 
                @map.x += @cameraSpeed
            else if event.which is 100
                @map.x -= @cameraSpeed
            else if event.which is 115
                @map.y -= @cameraSpeed
            else if event.which is 119
                @map.y += @cameraSpeed
            else
                console.log event
                console.log event.which

        # well this is ugly...
        @render = @canvas.withMap @map, (ctx) =>

            # draw Map
            # Location
            ctx.beginPath()
            ctx.lineWidth @map.wallSize
            ctx.strokeStyle "#558893"
            ctx.strokeRect (-@map.wallSize/2), (-@map.wallSize/2), @map.width+@map.wallSize, @map.height+@map.wallSize

            @p1.draw ctx
            @ai.draw ctx
            for p in @projectiles
                p.draw ctx

        @loop()

    addProjectile: (startX, startY, destX, destY, skill) ->
        p = new Projectile @, new Date().getTime(), startX, startY, destX, destY, skill
        @projectiles.push p

    loop: =>
        setTimeout @loop, 5
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        updateTime = new Date().getTime()
        @p1.update updateTime


        @ai.update updateTime

        newProjectiles = []
        for p in @projectiles
            alive = p.update updateTime
            if alive
                newProjectiles.push p
        @projectiles = newProjectiles


canvas = new Canvas()
arena = new Arena canvas
