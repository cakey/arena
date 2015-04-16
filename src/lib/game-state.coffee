_ = require 'lodash'

Point = require "./point"
Projectile = require "./projectile"
CapturePoint = require "./mechanics/capture-point"
Barriers = require "./mechanics/barriers"
Map = require "./map"
Config = require "./config"

# TODO pull out update parts of arena and player to allow running on the server
class GameState
    constructor: (@time) ->
        @players = {}
        @teams = {}
        @projectiles = []
        @map = new Map
        @deadPlayerIds = {}
        @capturePoints = []
        @barriers = []

        # Need to pull this stuff out into a map initialiser
        # and make it generic across different types of entities
        @capturePoints.push new CapturePoint(new Point(200, 250), 75)
        @capturePoints.push new CapturePoint(new Point(700, 250), 75)

        @barriers.push new Barriers.Rect(new Point(444, 100), new Point(456, 200))
        @barriers.push new Barriers.Rect(new Point(444, 300), new Point(456, 400))

    addTeam: (name, color) ->
        @teams[name] =
            color: color
            score: 0

    addPlayer: (player) ->
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    movePlayer: (playerId, point) ->
        player = @players[playerId]
        player.moveTo point

    playerFire: (playerId, destP, skill) ->
        player = @players[playerId]
        player.fire destP, skill


    killPlayer: (playerId) ->
        @deadPlayerIds[playerId] = @time
        player = @players[playerId]
        respawnX = 250 + (_.sample (x for x in [0..400] by 20))
        respawnY = _.sample [-50, 550]
        player.kill new Point respawnX, respawnY

    respawnPlayer: (playerId) ->
        delete @deadPlayerIds[playerId]
        player = @players[playerId]
        player.respawn()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    allowedMovement: (newP, player) ->

        # TODO: n^2? seriously?

        currentUnallowed = 0
        newUnallowed = 0

        # we calculate if the new position is at least as valid as our current position

        # player collisions
        for otherId, otherPlayer of @players
            if otherId isnt player.id
                if otherPlayer.alive
                    currentD = player.p.distance otherPlayer.p
                    newD = newP.distance otherPlayer.p
                    minimum = player.radius + otherPlayer.radius
                    if currentD < minimum
                        currentUnallowed += (minimum - currentD)
                    if newD < minimum
                        newUnallowed += (minimum - newD)

        # barrier collisions
        for barrier in @barriers
            if barrier.circleIntersect player.p, player.radius
                currentUnallowed += player.radius
            if barrier.circleIntersect newP, player.radius
                newUnallowed += player.radius

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
            if player.alive
                if p.team isnt player.team
                    if p.p.within player.p, p.skill.radius + player.radius
                        return {
                            player: player
                            type: "player"
                        }
        for barrier in @barriers
            if barrier.circleIntersect(p.p, p.skill.radius)
                return {
                    type: "barrier"
                }
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
                if hit = @projectileCollide projectile
                    if hit.type is "player"
                        hitPlayer = hit.player
                        skill = projectile.skill
                        @teams[projectile.team].score += skill.score
                        @teams[hitPlayer.team].score -= skill.score
                        if skill.hitPlayer?
                            skill.hitPlayer hitPlayer, projectile, @
                        if skill.continue
                            newProjectiles.push projectile
                     # else
                        # drop projectile
                else
                    newProjectiles.push projectile
        @projectiles = newProjectiles

        for cp in @capturePoints
            cp.update @

        for playerId, deathTime of @deadPlayerIds
            if updateTime - deathTime > Config.game.respawnTime
                @respawnPlayer playerId

        @time = updateTime

    toJSON: ->
        state = {}
        state.players = {}
        for id, player of @players
            playerState = {}
            playerState.p = player.p?.toObject()
            playerState.destP = player.destP?.toObject()
            playerState.team = player.team
            playerState.alive = player.alive
            state.players[id] = playerState
        state.time = @time
        state.teams = {}
        for name, obj of @teams
            state.teams[name] = obj.score
        state.projectiles = @projectiles.length

        state.capturePoints = (cp.current for cp in @capturePoints)

        state.deadPlayerIds = @deadPlayerIds

        state

    sync: (newState) ->
        # tied closely with toJSON
        # TODO: use tick data to smooth

        for teamId, newScore of newState.teams
            @teams[teamId].score = newScore

        for playerId, playerState of newState.players
            @players[playerId].p = Point.fromObject playerState.p
            @players[playerId].destP = Point.fromObject playerState.destP
            @players[playerId].alive = playerState.alive

        for cp, i in newState.capturePoints
            @capturePoints[i].current = cp

        @deadPlayerIds = newState.deadPlayerIds

module.exports = GameState
