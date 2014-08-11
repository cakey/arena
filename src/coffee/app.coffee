# todo:
# generalise abilities
# generalise projectiles?
# player extends projectile
# todo: pull out key bindings

Point = require "./point"

Array.prototype.some ?= (f) ->
    (return true if f x) for x in @
    return false

Array.prototype.every ?= (f) ->
    (return false if not f x) for x in @
    return true

utils =
    randInt: (lower, upper = 0) ->
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

            # TODO: higher level...

            translatedContext =
                moveTo: (p) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.moveTo x, y
                arc: (p, args...) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.arc x, y, args...
                strokeRect: (p, args...) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.strokeRect x, y, args...
                circle: (p, radius) -> translatedContext.arc p, radius, 0, 2 * Math.PI
                beginPath: -> o.beginPath()
                fillStyle: (arg) -> o.fillStyle = arg
                fill: o.fill.bind o
                lineWidth: (arg) -> o.lineWidth = arg
                setLineDash: o.setLineDash.bind o
                stroke: o.stroke.bind o
                fillText: o.fillText.bind o
                font: (arg) -> o.font = arg
                strokeStyle: (arg) -> o.strokeStyle = arg

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
        cone: Math.PI / 3
        radius: 10
        castTime: 10 #10
        speed: 0.1 #0.2
        range: 800
        color: "#990099"

class Player

    constructor: (@arena, @time, @p, @team) ->
        @radius = 20
        @maxCastRadius = @radius * 2
        @destP = @p
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castP = null

    moveTo: (@destP) ->
        @startCastTime = null

    fire: (@castP, @castedSkill) ->
        # stop moving to fire
        @destP = @p
        @startCastTime = @time # needs to be passed through

    draw: (ctx) ->

        # Cast
        if @startCastTime?
            radiusMs = @radius / @castedSkill.castTime
            radius = (radiusMs * (@time - @startCastTime)) + @radius

            angle = @p.angle @castP
            halfCone = @castedSkill.cone / 2

            ctx.beginPath()
            ctx.moveTo @p
            ctx.arc @p, radius, angle - halfCone, angle + halfCone
            ctx.moveTo @p
            ctx.fillStyle @castedSkill.color
            ctx.fill()

        # Location
        ctx.beginPath()
        ctx.circle @p, @radius
        ctx.fillStyle "#aaaacc"
        ctx.fill()

        # casting circle

        ctx.beginPath()
        ctx.circle @p, @maxCastRadius
        ctx.lineWidth 1
        ctx.setLineDash [3,12]
        ctx.strokeStyle "#777777"
        ctx.stroke()
        ctx.setLineDash []

    update: (newTime) ->
        msDiff = newTime - @time

        # Location

        @p = @p.towards @destP, (@speed * msDiff)

        # Cast

        if @startCastTime?
            if newTime - @startCastTime > @castedSkill.castTime
                @startCastTime = null

                castAngle = @p.angle @castP

                edgeP = @p.bearing castAngle, @maxCastRadius

                # handle edgecase where castPoint was within casting circle
                if @castP.within @p, @maxCastRadius
                    @castP = edgeP.bearing castAngle, 0.1

                @arena.addProjectile edgeP, @castP, @castedSkill, @team

        @time = newTime

class AI extends Player

    update: (newTime) ->
        super newTime

        #if @arena.p1.startCastTime? and not @startCastTime?
        #    @fire @arena.p1.x, @arena.p1.y, skills.disrupt

        if Math.random() < 0.005 and not @startCastTime?
            @fire @arena.p1.p, skills.orb

        if not @startCastTime? and (Math.random() < 0.03 or (@p.equal @destP))
            @moveTo new Point(
                utils.randInt(0,@arena.map.width),
                utils.randInt(0,@arena.map.height)
            )
            #@moveTo(
            #    ((@arena.p1.x+@x)/2)+utils.randInt(-250,250),
            #    ((@arena.p1.y+@y)/2)+utils.randInt(-250,250)
            #)

class UIPlayer extends Player

    constructor: ->
        super
        addEventListener "mousedown", (event) =>
            topLeft = new Point @radius, @radius
            bottomRight = new Point(
                @arena.map.width - @radius,
                @arena.map.height - @radius)

            p = @arena.mouseP.bound topLeft, bottomRight

            if event.which is 3
                @moveTo p

        addEventListener "keypress", (event) =>
            if event.which is 103
                @fire (@arena.mouseP.mapBound @p, @arena.map), skills.orb
            else if event.which is 104
                @fire (@arena.mouseP.mapBound @p, @arena.map), skills.disrupt
            else
                console.log event
                console.log event.which

class Projectile

    constructor: (@arena, @time, @p, dirP, @skill, @team) ->
        angle = @p.angle dirP
        @destP = @p.bearing angle, @skill.range

    draw: (ctx) ->

        # Location
        ctx.beginPath()
        ctx.circle @p, @skill.radius
        ctx.fillStyle @skill.color
        ctx.fill()

    update: (newTime) ->

        if @p.equal @destP
            return false

        msDiff = newTime - @time

        @p = @p.towards @destP, (@skill.speed * msDiff)

        @time = newTime
        return true

class Arena

    constructor: (@canvas) ->
        @time = new Date().getTime()
        @p1 = new UIPlayer @, @time, new Point(100, 100), "human"
        numais = 2
        @ais = []
        for a in [0...numais]
            @ais.push new AI @, @time, new Point(200, 100), "ai1"
        @projectiles = []
        @cameraSpeed = 0.3

        @mouseP = new Point 0, 0

        @p1score = 0
        @aiscore = 0

        @map =
            p: new Point 25, 25
            width: window.innerWidth - 100
            height: window.innerHeight - 100
            wallSize: 10

        @mapMiddle = @mapToGo = new Point window.innerWidth / 2, window.innerHeight / 2

        addEventListener "mousemove", (event) =>
            @mouseP = new Point(
                event.x - (@map.p.x + @map.wallSize),
                event.y - (@map.p.y + @map.wallSize))

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards new Point(event.x, event.y), 100

        # well this is ugly...
        @render = @canvas.withMap @map, (ctx) =>

            # draw Map
            # Location
            ctx.beginPath()
            ctx.lineWidth @map.wallSize
            ctx.strokeStyle "#558893"
            wallP = new Point (-@map.wallSize / 2), (-@map.wallSize / 2)
            ctx.strokeRect wallP, @map.width + @map.wallSize, @map.height + @map.wallSize

            ctx.fillStyle "#444466"
            ctx.font "20px verdana"
            ctx.fillText "P1: #{@p1score}", 10, window.innerHeight - 20
            ctx.fillText "AI: #{@aiscore}", 150, window.innerHeight - 20

            @p1.draw ctx
            for ai in @ais
                ai.draw ctx
            for p in @projectiles
                p.draw ctx

        @loop()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    loop: =>
        setTimeout @loop, 5
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        updateTime = new Date().getTime()

        msDiff = updateTime - @time

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @map.p = @map.p.subtract moveVector

        @p1.update updateTime
        for ai in @ais
            ai.update updateTime

        newProjectiles = []
        for p in @projectiles
            alive = p.update updateTime
            if alive
                hithuman = p.team isnt "human" and
                    p.p.within @p1.p, p.skill.radius + @p1.radius

                hitai = p.team isnt "ai1" and @ais.some (ai) ->
                    p.p.within ai.p, p.skill.radius + ai.radius

                if hithuman
                    @aiscore += 1
                else if hitai
                    @p1score += 1
                else
                    newProjectiles.push p
        @projectiles = newProjectiles

        @time = updateTime


canvas = new Canvas()
arena = new Arena canvas
