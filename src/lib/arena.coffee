_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"

# TODO remove the "map" from the "@mapBlah" variables.
class Arena
    constructor: () ->
        @origin = new Point 0, 0
        @p = new Point 0, 0
        @size = new Point Config.game.width, Config.game.height
        @wallSize = new Point 6, 6

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    boundPoint: (point) ->
        point.bound @origin, @size

    update: (msDiff) ->

module.exports = Arena
