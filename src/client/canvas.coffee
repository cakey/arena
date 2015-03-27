_ = require 'lodash'

Point = require "../lib/point"

class Canvas
    constructor: (@id) ->
        @stage = new createjs.Stage "canvas"
        @stage.canvas.width = window.innerWidth
        @stage.canvas.height = window.innerHeight
        @stage.setTransform 25, 25

        onResize = =>
            @stage.canvas.width = window.innerWidth
            @stage.canvas.height = window.innerHeight

        window.onresize = _.throttle onResize, 50

        @cameraOffset = new Point 25, 25

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @cameraOffset = new Point event.x, event.y
                @stage.setTransform event.x, event.y

        @mousePosition = new Point 0, 0

        addEventListener "mousemove", (event) =>
            eventPosition = Point.fromObject event
            @mousePosition = eventPosition.subtract @cameraOffset

module.exports = Canvas
