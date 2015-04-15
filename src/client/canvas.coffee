_ = require 'lodash'

Point = require "../lib/point"

class Canvas
    constructor: (@id) ->
        @canvas = document.getElementById @id

        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @ctx = @canvas.getContext '2d'

        onResize = =>
            @canvas.width = window.innerWidth
            @canvas.height = window.innerHeight

        window.onresize = _.throttle onResize, 50

    mapContext: (map) ->
        o = @ctx
        translatedContext =
            moveTo: (p) ->
                mappedP = p.add(map.p)
                o.moveTo mappedP.x, mappedP.y
            arc: (p, radius, startAngle, endAngle) ->
                mappedP = p.add(map.p)
                o.arc mappedP.x, mappedP.y, radius, startAngle, endAngle
            strokeRect: (p, size) ->
                mappedP = p.add(map.p)
                o.strokeRect mappedP.x, mappedP.y, size.x, size.y
            fillRect: (p, size) ->
                mappedP = p.add(map.p)
                o.fillRect mappedP.x, mappedP.y, size.x, size.y
            fillText: (arg, p) ->
                mappedP = p.add(map.p)
                o.fillText arg, mappedP.x, mappedP.y
            strokeText: (arg, p) ->
                mappedP = p.add(map.p)
                o.strokeText arg, mappedP.x, mappedP.y

            circle: (p, radius) -> translatedContext.arc p, radius, 0, 2 * Math.PI
            filledCircle: (p, radius, color) ->
                translatedContext.beginPath()
                translatedContext.circle p, radius
                translatedContext.fillStyle color
                translatedContext.fill()

            beginPath: -> o.beginPath()
            fillStyle: (arg) -> o.fillStyle = arg
            globalAlpha: (arg) -> o.globalAlpha = arg
            fill: o.fill.bind o
            lineWidth: (arg) -> o.lineWidth = arg
            setLineDash: o.setLineDash.bind o
            stroke: o.stroke.bind o
            font: (arg) -> o.font = arg
            strokeStyle: (arg) -> o.strokeStyle = arg

    begin: ->
        @ctx.clearRect 0, 0, @canvas.width, @canvas.height

    end: ->

    context: ->
        @mapContext
            p: new Point 0, 0

module.exports = Canvas
