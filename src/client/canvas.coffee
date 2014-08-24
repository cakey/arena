class Canvas
    constructor: (@id) ->
        @canvas = document.getElementById @id
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
                fillRect: (p, args...) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.fillRect x, y, args...
                circle: (p, radius) -> translatedContext.arc p, radius, 0, 2 * Math.PI
                filledCircle: (p, radius, color) ->
                    translatedContext.beginPath()
                    translatedContext.circle p, radius
                    translatedContext.fillStyle color
                    translatedContext.fill()


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

module.exports = Canvas
