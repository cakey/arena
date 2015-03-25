_ = require 'lodash'

Point = require "../lib/point"
Config = require "../lib/config"

# TODO remove the "map" from the "@mapBlah" variables.
class Map
    constructor: ->
        @size = new Point Config.game.width, Config.game.height
        @wallSize = new Point 6, 6

    randomPoint: =>
        new Point _.random(0, @size.x), _.random(0, @size.y)

    render: (ctx) ->
        wallP = new Point (-@wallSize.x / 2), (-@wallSize.y / 2)

        ctx.beginPath()
        ctx.fillStyle "#f3f3f3"
        ctx.fillRect new Point(0,0), @size
        ctx.beginPath()
        ctx.lineWidth @wallSize.x
        ctx.strokeStyle "#558893"
        ctx.strokeRect wallP, @size.add(@wallSize)

module.exports = Map
