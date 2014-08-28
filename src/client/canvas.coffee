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

        _withMap = (func) ->
            (p, args...) ->
                x = p.x + map.p.x + map.wallSize
                y = p.y + map.p.y + map.wallSize
                o[func] x, y, args...

        _flippedWithMap = (func) ->
            (arg, p, args...) ->
                x = p.x + map.p.x + map.wallSize
                y = p.y + map.p.y + map.wallSize
                o[func] arg, x, y, args...

        translatedContext =
            moveTo: _withMap 'moveTo'
            arc: _withMap 'arc'
            strokeRect: _withMap 'strokeRect'
            fillRect: _withMap 'fillRect'
            fillText: _flippedWithMap 'fillText'
            strokeText: _flippedWithMap 'strokeText'

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
            wallSize: 0

module.exports = Canvas
