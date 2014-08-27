
class Point

    # Immutable point.
    constructor: (@x,@y) ->

    @fromObject: (object) ->
        if not object.x? and not object.y?
            throw new Error "Point.fromObject constructor requires x/y keys"

        new Point object.x, object.y

    toObject: ->
        x: @x
        y: @y

    angle: (otherP) ->
        diffY = otherP.y - @y
        diffX = otherP.x - @x
        angle = Math.atan2 diffY, diffX
        return angle

    equal: (otherP) ->
        @x is otherP.x and @y is otherP.y

    towards: (destP, maxDistance) ->

        diffY = destP.y - @y
        diffX = destP.x - @x
        angle = Math.atan2 diffY, diffX
        maxYTravel = Math.sin(angle) * maxDistance
        maxXTravel = Math.cos(angle) * maxDistance

        if maxXTravel > Math.abs diffX
            x = destP.x
        else
            x = @x + maxXTravel

        if maxYTravel > Math.abs diffY
            y = destP.y
        else
            y = @y + maxYTravel

        new Point x,y

    bearing: (angle, distance) ->
        x = @x + Math.cos(angle) * distance
        y = @y + Math.sin(angle) * distance
        new Point x,y

    distance: (otherP) ->
        Math.sqrt(
            Math.pow(@x - otherP.x, 2) +
            Math.pow(@y - otherP.y, 2)
        )

    within: (center, radius) ->
        return @distance(center) <= radius

    bound: (topLeft, bottomRight) ->
        x = @x
        y = @y
        if x < topLeft.x
            x = topLeft.x
        else if x > bottomRight.x
            x = bottomRight.x

        if y < topLeft.y
            y = topLeft.y
        else if y > bottomRight.y
            y = bottomRight.y

        new Point x, y

    inside: (topLeft, bottomRight) ->
        ((@x >= topLeft.x) and
            (@x <= bottomRight.x) and
            (@y >= topLeft.y) and
            (@y <= bottomRight.y))

    angleBound: (from, topLeft, bottomRight) ->
        # if @ is outside the boundingBox, then return
        # where it intersects, otherwise just return @

        if (
            @x > topLeft.x and
            @x < bottomRight.x and
            @y > topLeft.y and
            @y < bottomRight.y)
            return @

        angle = from.angle @

        # TODO: Maths
        # :( :(

        closest = from

        while (
            closest.x > topLeft.x and
            closest.x < bottomRight.x and
            closest.y > topLeft.y and
            closest.y < bottomRight.y)
            closest = closest.bearing angle, 1

        return closest

    mapBound: (from, map) ->
        topLeft = new Point 0, 0
        bottomRight = new Point map.width, map.height

        return @angleBound from, topLeft, bottomRight

    subtract: (otherP) ->
        new Point (@x - otherP.x), (@y - otherP.y)

    add: (otherP) ->
        new Point (@x + otherP.x), (@y + otherP.y)

module.exports = Point
