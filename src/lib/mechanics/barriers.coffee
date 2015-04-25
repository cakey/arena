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

    toObject: ->
        return {
            type: "Rect"
            tl: @topleft.toObject()
            br: @bottomright.toObject()
        }

fromObject = (obj) ->
    if obj.type is "Rect"
        new Rect Point.fromObject(obj.tl), Point.fromObject(obj.br)


module.exports = {Rect, fromObject}
