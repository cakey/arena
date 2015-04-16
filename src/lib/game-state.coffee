_ = require 'lodash'

Point = require "./point"
Projectile = require "./projectile"
Map = require "./map"

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (@time) ->
        @players = {}
        @teams = {}
        @projectiles = []
        @map = new Map
        @newPlayers = []
        @toAddProjectiles = []
        @toRemoveProjectiles = []

    addTeam: (name, color) ->
        @teams[name] =
            color: color
            score: 0

    addPlayer: (player) ->
        @newPlayers.push player
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    movePlayer: (playerId, point) ->
        player = @players[playerId]
        player.moveTo point

    playerFire: (playerId, destP, skill) ->
        player = @players[playerId]
        player.fire destP, skill

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @toAddProjectiles.push p
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

        for id, player of @players
            player.update updateTime, @

        # Projectiles.
        newProjectiles = []
        for projectile in @projectiles
            alive = projectile.update updateTime
            withinMap = (
                projectile.p.x > 0 and
                projectile.p.y > 0 and
                projectile.p.x < @map.size.x and
                projectile.p.y < @map.size.y)
            if alive and withinMap
                if hitPlayer = @projectileCollide projectile
                    @toRemoveProjectiles.push projectile
                    skill = projectile.skill
                    @teams[projectile.team].score += skill.score
                    @teams[hitPlayer.team].score -= skill.score
                    if skill.hitPlayer?
                        skill.hitPlayer hitPlayer, projectile, @map
                    if skill.continue
                        newProjectiles.push projectile
                else
                    newProjectiles.push projectile
            else
                @toRemoveProjectiles.push projectile
        @projectiles = newProjectiles

        @time = updateTime

    toJSON: ->
        state = {}
        state.players = {}
        for id, player of @players
            playerState = {}
            playerState.p = player.p.toObject()
            playerState.destP = player.destP.toObject()
            playerState.team = player.team
            state.players[id] = playerState
        state.time = @time
        state.teams = {}
        for name, obj of @teams
            state.teams[name] = obj.score
        state.projectiles = @projectiles.length

        state

    sync: (newState) ->
        # tied closely with toJSON
        # TODO: use tick data to smooth

        for teamId, newScore of newState.teams
            @teams[teamId].score = newScore

        for playerId, playerState of newState.players
            @players[playerId].p = Point.fromObject playerState.p
            @players[playerId].destP = Point.fromObject playerState.destP

module.exports = GameState
