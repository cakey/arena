Point = require "../point"

class CapturePoint
    constructor: (@p, @radius) ->
        @maxStrength = 500
        @current =
            captured: false
            team: null
            strength: 0

    render: (ctx, teams) ->

        if @current.team?
            percent = @current.strength / @maxStrength
            ctx.beginPath()
            ctx.moveTo @p
            ctx.arc @p, (@radius+10), (-Math.PI/2), (2 * Math.PI * percent)-(Math.PI/2)
            color = teams[@current.team].color
            ctx.fillStyle color
            ctx.fill()

        if @current.captured
            ctx.beginPath()
            ctx.moveTo @p
            ctx.arc @p, (@radius+3), 0, (2 * Math.PI)
            color = "#000000"
            ctx.fillStyle color
            ctx.fill()

        ctx.filledCircle @p, @radius, "#bbbbbb"

    update: (gameState) ->
        for id, player of gameState.players
            if @p.distance(player.p) < (@radius + player.radius)
                if player.team is @current.team
                    @current.strength = Math.min(@maxStrength, @current.strength + 1)
                    if @current.strength is @maxStrength
                        @current.captured = true
                else
                    @current.strength = Math.max(0, @current.strength - 1)
                    if @current.strength is 0
                        @current.captured = false
                        @current.team = player.team

        if @current.captured
            gameState.teams[@current.team].score += 1


module.exports = CapturePoint
