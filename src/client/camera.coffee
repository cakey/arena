Point = require "../lib/point"

class Camera
    constructor: ->
        @p = new Point 25, 25
        @mapMouseP = new Point 0, 0
        @mouseP = new Point 0, 0

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        @cameraSpeed = 0.3

        addEventListener "mousemove", (event) =>
            @mouseP = Point.fromObject event
            @mapMouseP = @mouseP.subtract(@p)

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards Point.fromObject(event), 100


    update: (msDiff) ->
        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @p = @p.subtract moveVector

module.exports = Camera
