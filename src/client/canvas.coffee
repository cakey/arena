Fabric = require('fabric').fabric
_ = require 'lodash'

Point = require "../lib/point"

class Canvas
    constructor: (@id) ->
        @context = new Fabric.StaticCanvas(@id)
        @context.setWidth window.innerWidth
        @context.setHeight window.innerHeight

        onResize = =>
            @context.setWidth window.innerWidth
            @context.setHeight window.innerHeight

        window.onresize = _.throttle onResize, 50

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards Point.fromObject(event), 100

    # mapContext: (point, wallSize) ->
    #     o = @ctx
    #     translatedContext =
    #         moveTo: (p) ->
    #             mappedP = p.add(point).add(wallSize)
    #             o.moveTo mappedP.x, mappedP.y
    #         arc: (p, args...) ->
    #             # mappedP = p.add(point).add(wallSize)
    #             o.arc p.x, p.y, args...
    #         strokeRect: (p, size) ->
    #             mappedP = p.add(point).add(wallSize)
    #             o.strokeRect mappedP.x, mappedP.y, size.x, size.y
    #         fillRect: (p, size) ->
    #             mappedP = p.add(point).add(wallSize)
    #             o.fillRect mappedP.x, mappedP.y, size.x, size.y
    #         fillText: (arg, p) ->
    #             mappedP = p.add(point).add(wallSize)
    #             o.fillText arg, mappedP.x, mappedP.y
    #         strokeText: (arg, p) ->
    #             mappedP = p.add(point).add(wallSize)
    #             o.strokeText arg, mappedP.x, mappedP.y

    #         circle: (p, radius) -> translatedContext.arc p, radius, 0, 2 * Math.PI
    #         filledCircle: (p, radius, color) ->
    #             translatedContext.beginPath()
    #             translatedContext.circle p, radius
    #             translatedContext.fillStyle color
    #             translatedContext.fill()

    #         beginPath: -> o.beginPath()
    #         fillStyle: (arg) -> o.fillStyle = arg
    #         globalAlpha: (arg) -> o.globalAlpha = arg
    #         fill: o.fill.bind o
    #         lineWidth: (arg) -> o.lineWidth = arg
    #         setLineDash: o.setLineDash.bind o
    #         stroke: o.stroke.bind o
    #         font: (arg) -> o.font = arg
    #         strokeStyle: (arg) -> o.strokeStyle = arg

    # begin: ->
    #     @ctx.clearRect 0, 0, @canvas.width, @canvas.height

    # end: ->

    # context: ->
    #     @mapContext
    #         p: new Point 0, 0
    #         wallSize: new Point 0, 0

module.exports = Canvas
