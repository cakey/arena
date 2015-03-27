Utils = require "../lib/utils"
UIElement = require "../lib/ui-element"

class Projectile extends UIElement
    constructor: (@arena, @time, @p, dirP, @skill, @team) ->
        angle = @p.angle dirP
        @destP = @p.bearing angle, @skill.range
        @ele = new createjs.Shape()
        @ele.graphics.beginFill(@skill.color).
            beginStroke(@arena.teams[@team].color).
            setStrokeStyle(1).
            drawCircle(0, 0, @skill.radius)
        @ele.x = @p.x
        @ele.y = @p.y
        @arena.canvas.stage.addChild @ele

    update: (newTime) ->
        if @p.equal @destP
            return false

        msDiff = newTime - @time

        @p = @p.towards @destP, (Utils.game.speed(@skill.speed) * msDiff)

        @time = newTime
        return true

    render: ->
        # Location
        @ele.x = @p.x
        @ele.y = @p.y

module.exports = Projectile