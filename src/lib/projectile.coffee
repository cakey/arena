Utils = require "../lib/utils"
UIElement = require "../lib/ui-element"

class Projectile extends UIElement
    constructor: (@arena, @time, @p, dirP, @skill, @team) ->
        angle = @p.angle dirP
        @destP = @p.bearing angle, @skill.range

    update: (newTime) ->
        if @p.equal @destP
            return false

        msDiff = newTime - @time

        @p = @p.towards @destP, (Utils.game.speed(@skill.speed) * msDiff)

        @time = newTime
        return true

    render: ->
        super()

    clear: ->
        super()

module.exports = Projectile