Point = require "../point"
Config = require "../config"

class Circle
    constructor: (@center, @radius, @team) ->

    render: (ctx) ->
        ctx.filledCircle @center, @radius, Config.colors.mineRed

    circleIntersect: (center, radius) ->
        @center.distance(center) < (@radius + radius)

    toObject: ->
        return {
            type: "Circle"
            center: @center.toObject()
            radius: @radius
            team: @team
        }

fromObject = (obj) ->
    if obj.type is "Circle"
        new Circle Point.fromObject(obj.center), obj.radius, obj.team


module.exports = {Circle, fromObject}
