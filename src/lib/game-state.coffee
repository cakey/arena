_ = require 'lodash'

Config = require "./config"
Point = require "./point"
Projectile = require "./projectile"
Map = require "./map"
Renderers = require "../client/renderers"

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (options) ->
        {@shouldRender, @canvas, @camera} = options
        @time = new Date().getTime()
        @players = {}
        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0

        @projectiles = []
        @map = new Map @canvas

    render: ->
        if @shouldRender
            # Clear the canvas.
            # @canvas.begin()

            # Render all the things.
            Renderers.arena @, @canvas

            # Nothing right now.
            # @canvas.end()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    allowedMovement: (newP, player) ->

        # TODO: n^2? seriously?

        currentUnallowed = 0
        newUnallowed = 0

        for otherId, otherPlayer of @players
            if otherId isnt player.id
                currentD = player.p.distance otherPlayer.p
                newD = newP.distance otherPlayer.p
                minimum = player.radius + otherPlayer.radius
                if currentD < minimum
                    currentUnallowed += (minimum - currentD)
                if newD < minimum
                    newUnallowed += (minimum - newD)

        allowed = newUnallowed <= currentUnallowed

        # stickiness parameter (less likely to get caught on an edge)
        if 0 < newUnallowed < 2
            return true

        return allowed

    projectileCollide: (p) ->
        # for each other team
        # check if projectile hits a player
        # if so increment owner of projectile score
        # otherwise add to newProjectiles
        for id, player of @players
            if p.team isnt player.team
                return player if p.p.within player.p, p.skill.radius + player.radius
        return false

    update: (updateTime) ->
        msDiff = updateTime - @time

        # Map.
        @camera.update msDiff

        for id, player of @players
            player.update updateTime

        # Projectiles.
        newProjectiles = []
        deadProjectiles = []
        for projectile in @projectiles
            alive = projectile.update updateTime
            withinMap = (
                projectile.p.x > 0 and
                projectile.p.y > 0 and
                projectile.p.x < @map.size.x and
                projectile.p.y < @map.size.y)
            if alive and withinMap
                if hitPlayer = @projectileCollide projectile
                    deadProjectiles.push projectile
                    skill = projectile.skill
                    @teams[projectile.team].score += skill.score
                    @teams[hitPlayer.team].score -= skill.score
                    if skill.hitPlayer?
                        skill.hitPlayer hitPlayer, projectile
                    if skill.continue
                        newProjectiles.push projectile
                else
                    newProjectiles.push projectile
            else
                deadProjectiles.push projectile

        for projectile in deadProjectiles
            @canvas.stage.removeChild projectile.ele
        @projectiles = newProjectiles

        @time = updateTime

module.exports = GameState
