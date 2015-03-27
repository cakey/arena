_ = require 'lodash'

Point = require "../lib/point"

class Canvas
    constructor: (@id) ->
        @stage = new createjs.Stage "canvas"
        @stage.canvas.width = window.innerWidth
        @stage.canvas.height = window.innerHeight
        @stage.setTransform 25, 25
        @cameraOffset = new Point 0, 0

        onResize = =>
            @stage.canvas.width = window.innerWidth
            @stage.canvas.height = window.innerHeight

        window.onresize = _.throttle onResize, 50

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @stage.setTransform event.x, event.y
                @cameraOffset = new Point event.x, event.y

module.exports = Canvas
