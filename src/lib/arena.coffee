_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"

# TODO remove the "map" from the "@mapBlah" variables.
class Arena
    constructor: (canvas) ->
        @p = new Point 0, 0
        @size = new Point Config.game.width, Config.game.height
        @wallSize = new Point 6, 6

        @map = new createjs.Shape()
        @map.graphics.beginFill("#f3f3f3").beginStroke("#558893").
            setStrokeStyle(6).
            drawRect(0, 0, Config.game.width, Config.game.height)
        canvas.stage.addChild @map

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    update: (msDiff) ->

    render: (state) ->

module.exports = Arena
