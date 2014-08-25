# TODO:
# localhandler
# interrupt skill with cooldown
# UI for cooldown / skills
# refactor websocket stuff
# health
# heal
# shield / reversal

WebSocket = require 'ws'
uuid = require 'node-uuid'
RSVP = require 'rsvp'

Point = require "../lib/point"
Skills = require "../lib/skills"
Config = require "../lib/config"
Utils = require "../lib/utils"

Canvas = require "./canvas"
Renderers = require "./renderers"

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

class Player

    constructor: (@arena, @p, @team, @id) ->
        @time = @arena.time
        @radius = 20
        @maxCastRadius = @radius * 2
        @destP = @p
        @speed = 0.2 # pixels/ms
        @startCastTime = null
        @castP = null
        if not @id?
            @id = uuid.v4()

    moveTo: (@destP) ->
        if @startCastTime isnt null and @castedSkill.channeled
            @startCastTime = null

    fire: (@castP, @castedSkill) ->
        # stop moving to fire
        if @castedSkill.channeled
            @destP = @p
        @startCastTime = @time # needs to be passed through

    update: (newTime) ->
        msDiff = newTime - @time

        # Location

        newP = @p.towards @destP, (Utils.game.speed(@speed) * msDiff)
        if @arena.allowedMovement newP, @
            @p = newP

        # Cast

        if @startCastTime?
            if newTime - @startCastTime > Utils.game.speedInverse(@castedSkill.castTime)
                @startCastTime = null

                castAngle = @p.angle @castP

                edgeP = @p.bearing castAngle, @maxCastRadius

                # handle edgecase where castPoint was within casting circle
                if @castP.within @p, @maxCastRadius
                    @castP = edgeP.bearing castAngle, 0.1

                @arena.addProjectile edgeP, @castP, @castedSkill, @team

        @time = newTime

class AIPlayer

    constructor: (@arena, @handler, startP, team) ->
        @player = new Player @arena, startP, team

    update: (newTime) ->

        #if @arena.p1.startCastTime? and not @startCastTime?
        #    @fire @arena.p1.x, @arena.p1.y, skills.disrupt

        otherPs = (p for id, p of @handler.players when p.team isnt @player.team)

        if Math.random() < Utils.game.speed(0.005) and not @player.startCastTime?
            @handler.fire @player, Utils.choice(otherPs).p, 'orb'

        chanceToMove = Math.random() < Utils.game.speed(0.03)
        if not @player.startCastTime? and (chanceToMove or @player.p.equal @player.destP)
            @handler.moveTo @player, @arena.map.randomPoint()
            #@moveTo(
            #    ((@arena.p1.x+@x)/2)+utils.randInt(-250,250),
            #    ((@arena.p1.y+@y)/2)+utils.randInt(-250,250)
            #)

class UIPlayer

    constructor: (@arena, @handler, startP, team) ->
        @player = new Player @arena, startP, team

        @keyBindings =
            g: 'orb'
            h: 'flame'
            b: 'gun'
            n: 'bomb'
            j: 'interrupt'
        addEventListener "mousedown", (event) =>
            topLeft = new Point @player.radius, @player.radius
            bottomRight = new Point(
                @arena.map.width - @player.radius,
                @arena.map.height - @player.radius)

            p = @arena.mouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo @player, p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                castP = @arena.mouseP.mapBound @player.p, @arena.map
                @handler.fire @player, castP, skill
            else
                console.log event
                console.log event.which

    update: (newTime) ->

class LocalHandler
    constructor: ->
        @players = {}
        @locallyProcessed = []
        @_readyDeferred = RSVP.defer()
        @_readyDeferred.resolve()

    registerLocal: (processor) ->
        player = processor.player
        @players[player.id] = player
        @locallyProcessed.push processor

    register: (player) ->
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    moveTo: (player, destP) ->
        player.moveTo destP

    fire: (player, castP, skillName) ->
        player.fire castP, Skills[skillName]

    ready: -> @_readyDeferred.promise

class NetworkHandler
    constructor: ->
        @players = {}
        @locallyProcessed = []

        @host = "ws://#{location.hostname}:#{Config.ws.port}"
        @ws = new WebSocket @host

        @client_uuid = uuid.v4()

        @_readyDeferred = RSVP.defer()

        @ws.onopen = =>
            message =
                action: 'register'
                id: @client_uuid
            @ws.send JSON.stringify message
            @_readyDeferred.resolve()

        window.onbeforeunload = =>
            message =
                action: 'deregister'
                id: @client_uuid
            @ws.send JSON.stringify message

        @ws.onmessage = (unparsed) =>
            message = JSON.parse unparsed.data
            d = message.data
            if message.action is "control"
                position = Point.fromObject d.actionPosition
                player = @players[d.playerId]

                playerPosition = Point.fromObject d.playerPosition
                if not player
                    console.log "unregistered player"
                    return

                if d.action is "moveTo"
                    # server corrects us
                    player.p = playerPosition
                    player.moveTo position
                else if d.action is "fire"
                    player.fire position, Skills[d.skill]
            else if message.action is "newPlayer"
                playerPosition = Point.fromObject d.playerPosition
                player = new Player arena, playerPosition, d.team, d.playerId
                @register player
            else if message.action is "deletePlayer"
                @removePlayer d
            else
                console.log "unrecognised message"
                console.log message

        @ws.onclose = ->
            # Server crashed or connection dropped
            # TODO: more rebust, in the meantime, essentially live reload
            document.location.reload true

    ready: -> @_readyDeferred.promise

    registerLocal: (processor) ->
        player = processor.player
        @players[player.id] = player
        @locallyProcessed.push processor

        message =
            action: 'newPlayer'
            data:
                playerId: player.id
                playerPosition: player.p.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    register: (player) ->
        @players[player.id] = player

    removePlayer: (playerId) ->
        delete @players[playerId]

    moveTo: (player, destP) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'moveTo'
                actionPosition: destP.toObject()
                playerPosition: player.p.toObject()
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

    fire: (player, castP, skillName) ->
        message =
            action: 'control'
            data:
                playerId: player.id
                action: 'fire'
                actionPosition: castP.toObject()
                playerPosition: player.p.toObject()
                skill: skillName
                team: player.team
            id: @client_uuid
        @ws.send JSON.stringify message

class Projectile

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

# TODO pull out update parts of arena and player to allow running on the server
class Arena

    constructor: (@canvas) ->
        @time = new Date().getTime()

        @map =
            p: new Point 25, 25
            width: Config.game.width
            height: Config.game.height
            wallSize: 10
            randomPoint: =>
                new Point(Utils.randInt(0, @map.width), Utils.randInt(0, @map.height))

        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0

        @projectiles = []
        @cameraSpeed = 0.3

        @mouseP = new Point 0, 0

        @mapMiddle = new Point window.innerWidth / 2, window.innerHeight / 2
        @mapToGo = @mapMiddle

        addEventListener "mousemove", (event) =>
            @mouseP = new Point(
                event.x - (@map.p.x + @map.wallSize),
                event.y - (@map.p.y + @map.wallSize))

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards new Point(event.x, event.y), 100

        # well this is ugly...
        @render = @canvas.withMap @map, (ctx) => Renderers.arena @, ctx

        @handler = new NetworkHandler()
        readyPromise = @handler.ready()
        readyPromise.then =>

            rp = @map.randomPoint()

            uip = new UIPlayer @, @handler, rp, Utils.choice(name for name, r of @teams)
            @handler.registerLocal uip

            numais = 1

            if numais > 0
                @teams.ai1 =
                    color: "#33aa33"
                    score: 0
                @teams.ai2 =
                    color: "#ddaa44"
                    score: 0

            for a in [0...numais]
                aip1 = new AIPlayer @, @handler, @map.randomPoint(), "ai1"
                @handler.registerLocal aip1
                aip2 = new AIPlayer @, @handler, @map.randomPoint(), "ai2"
                @handler.registerLocal aip2

            @loop()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    allowedMovement: (newP, player) ->

        # TODO: n^2? seriously?

        currentUnallowed = 0
        newUnallowed = 0

        for otherId, otherPlayer of @handler.players
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
        # if so increment owner of projechtile score
        # otherwise add to newProjectiles
        for id, player of @handler.players
            if p.team isnt player.team
                return player if p.p.within player.p, p.skill.radius + player.radius
        return false

    loop: =>
        setTimeout @loop, 5
        # TODO: A non sucky game loop...
        # Fixed time updates.
        @update()
        @render()

    update: ->
        updateTime = new Date().getTime()

        msDiff = updateTime - @time

        newCamP = @mapMiddle.towards @mapToGo, @cameraSpeed * msDiff

        moveVector = newCamP.subtract @mapMiddle
        @mapToGo = @mapToGo.subtract moveVector

        @map.p = @map.p.subtract moveVector

        for processor in @handler.locallyProcessed
            processor.update updateTime

        for id, player of @handler.players
            player.update updateTime

        newProjectiles = []
        for projectile in @projectiles
            alive = projectile.update updateTime
            withinMap = (
                projectile.p.x > 0 and
                projectile.p.y > 0 and
                projectile.p.x < @map.width and
                projectile.p.y < @map.height)
            if alive and withinMap
                if hitPlayer = @projectileCollide projectile
                    skill = projectile.skill
                    @teams[projectile.team].score += skill.score
                    @teams[hitPlayer.team].score -= skill.score
                    if skill.hitPlayer?
                        skill.hitPlayer hitPlayer, projectile
                    if skill.continue
                        newProjectiles.push projectile

                else
                    newProjectiles.push projectile
        @projectiles = newProjectiles

        @time = updateTime

#TODO:
canvas = new Canvas 'canvas'
arena = new Arena canvas
