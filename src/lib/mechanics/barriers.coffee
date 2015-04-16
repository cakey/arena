Point = require "../point"
Config = require "../config"

class Rect
    constructor: (@topleft, @bottomright) ->

    render: (ctx) ->
        ctx.beginPath()
        ctx.fillStyle Config.colors.barrierBrown
        ctx.fillRect @topleft, (@bottomright.subtract(@topleft))

    circleIntersect: (center, radius) ->
        if radius >= 20
            # stickiness
            radius -= 3
        rad = new Point radius, radius
        center.inside(@topleft.subtract(rad), @bottomright.add(rad))

module.exports = {Rect}
