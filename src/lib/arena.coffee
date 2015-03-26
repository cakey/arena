Fabric = require('fabric').fabric
_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"

# TODO remove the "map" from the "@mapBlah" variables.
class Arena
    constructor: (context) ->
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

        # addEventListener "mousedown", (event) =>
        #     if event.which is 1
        #         @mapToGo = @mapMiddle.towards Point.fromObject(event), 100

        # Set up map canvas object.
        @canvasObj = new Fabric.Rect {
            left: 100
            top: 100
            fill: '#f3f3f3'
            width: @size.x
            height: @size.y
            stroke: '#558893'
            strokeWidth: @wallSize.x
        }
        context.add @canvasObj

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    update: (msDiff) ->
        @lastP = @p
        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @p = @p.subtract moveVector

    render: (context) ->
        wallP = new Point (-@wallSize.x / 2), (-@wallSize.y / 2)

        # @canvasObj.set('left', 200)
        # context.add @canvasObj

    clear: (ctx) ->
        # The arbitrary looking -1 and +2 below is accounting for the rounding of the /2.
        origin = new Point -@wallSize.x - 1, -@wallSize.y - 1
        wallSize2 = new Point (@wallSize.x * 2) + 2, (@wallSize.y * 2) + 2

        ctx.fillStyle "#cccccc"
        ctx.fillRect origin, @size.add(wallSize2)

module.exports = Arena
