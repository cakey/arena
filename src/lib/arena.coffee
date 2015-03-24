_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"

# TODO remove the "map" from the "@mapBlah" variables.
class Arena
    constructor: ->
        @p = new Point 25, 25
        @size = new Point Config.game.width, Config.game.height
        @wallSize = new Point 6, 6

        @mapMouseP = new Point 0, 0
        @mouseP = new Point 0, 0

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        @cameraSpeed = 0.3

        addEventListener "mousemove", (event) =>
            @mouseP = Point.fromObject event
            @mapMouseP = @mouseP.subtract(@p).subtract(@wallSize)

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards Point.fromObject(event), 100

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    update: (msDiff) ->
        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @p = @p.subtract moveVector

    render: (ctx) ->
        wallP = new Point (-@wallSize.x / 2), (-@wallSize.y / 2)

        ctx.beginPath()
        ctx.fillStyle "#f3f3f3"
        ctx.fillRect wallP, @size.add(@wallSize)
        ctx.beginPath()
        ctx.lineWidth @wallSize.x
        ctx.strokeStyle "#558893"
        ctx.strokeRect wallP, @size.add(@wallSize)

module.exports = Arena
