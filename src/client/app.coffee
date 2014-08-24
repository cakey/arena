# TODO: filter / map
# teams
# interrupt skill with cooldown
# UI for cooldown / skills
# refactor websocket stuff
# health
# heal
# shield / reversal

WebSocket = require 'ws'
uuid = require 'node-uuid'

Point = require "../lib/point"
Skills = require "../lib/skills"
Config = require "../lib/config"
Utils = require "../lib/utils"

Canvas = require "./canvas"

host = "ws://#{location.hostname}:#{Config.ws.port}"
ws = new WebSocket host

client_uuid = uuid.v4()

localPlayers = {}

registerPlayer = (player) ->
    localPlayers[player.id] = player
    player.arena.players.push player

ws.onopen = ->
    message =
        action: 'register'
        id: client_uuid
    ws.send JSON.stringify message

    canvas = new Canvas 'canvas'
    arena = new Arena canvas

window.onbeforeunload = ->
    message =
        action: 'deregister'
        id: client_uuid
    ws.send JSON.stringify message

ws.onmessage = (unparsed) ->
    message = JSON.parse unparsed.data
    d = message.data
    if message.action is "control"
        position = Point.fromObject d.actionPosition
        player = localPlayers[d.playerId]

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
        registerPlayer player
    else if message.action is "deletePlayer"
        delete localPlayers[d]
        arena.players = (p for p in arena.players when p.id isnt d)
    else
        console.log "unrecognised message"
        console.log message

ws.onclose = ->
    # Server crashed or connection dropped
    # TODO: more rebust, in the meantime, essentially live reload
    document.location.reload true

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

    draw: (ctx) ->

        # Cast
        if @startCastTime?
            radiusMs = @radius / Utils.game.speedInverse(@castedSkill.castTime)
            radius = (radiusMs * (@time - @startCastTime)) + @radius

            angle = @p.angle @castP
            halfCone = @castedSkill.cone / 2

            ctx.beginPath()
            ctx.moveTo @p
            ctx.arc @p, radius, angle - halfCone, angle + halfCone
            ctx.moveTo @p
            ctx.fillStyle @castedSkill.color
            ctx.fill()

        # Location
        ctx.filledCircle @p, @radius, @arena.teams[@team].color

        # casting circle

        ctx.beginPath()
        ctx.circle @p, @maxCastRadius
        ctx.lineWidth 1
        ctx.setLineDash [3,12]
        ctx.strokeStyle "#777777"
        ctx.stroke()
        ctx.setLineDash []

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

class AIPlayer extends Player

    update: (newTime) ->
        super newTime

        #if @arena.p1.startCastTime? and not @startCastTime?
        #    @fire @arena.p1.x, @arena.p1.y, skills.disrupt

        otherPs = (p for p in @arena.players when p.team isnt @team)

        if Math.random() < Utils.game.speed(0.005) and not @startCastTime?
            @handler.fire Utils.choice(otherPs).p, 'orb'

        chanceToMove = Math.random() < Utils.game.speed(0.03)
        if not @startCastTime? and (chanceToMove or @p.equal @destP)
            @handler.moveTo @arena.map.randomPoint()
            #@moveTo(
            #    ((@arena.p1.x+@x)/2)+utils.randInt(-250,250),
            #    ((@arena.p1.y+@y)/2)+utils.randInt(-250,250)
            #)

class UIPlayer extends Player

    constructor: ->
        super
        @keyBindings =
            g: 'orb'
            h: 'flame'
            b: 'gun'
            n: 'bomb'
            j: 'interrupt'
        addEventListener "mousedown", (event) =>
            topLeft = new Point @radius, @radius
            bottomRight = new Point(
                @arena.map.width - @radius,
                @arena.map.height - @radius)

            p = @arena.mouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                @handler.fire (@arena.mouseP.mapBound @p, @arena.map), skill
            else
                console.log event
                console.log event.which

    draw: (ctx) ->
        super
        # Draw the UI

        #



class LocalHandler

    constructor: (@player) ->

    moveTo: (p) ->
        @player.moveTo p

    fire: (p, skillName) ->
        @player.fire p, Skills[skillName]

class NetworkHandler

    constructor: (@player) ->
        registerPlayer @player
        message =
            action: 'newPlayer'
            data:
                playerId: @player.id
                playerPosition: @player.p.toObject()
                team: @player.team
            id: client_uuid
        ws.send JSON.stringify message

    moveTo: (p) ->
        message =
            action: 'control'
            data:
                playerId: @player.id
                action: 'moveTo'
                actionPosition: p.toObject()
                playerPosition: @player.p.toObject()
                team: @player.team
            id: client_uuid
        ws.send JSON.stringify message

    fire: (p, skillName) ->
        message =
            action: 'control'
            data:
                playerId: @player.id
                action: 'fire'
                actionPosition: p.toObject()
                playerPosition: @player.p.toObject()
                skill: skillName
                team: @player.team
            id: client_uuid
        ws.send JSON.stringify message

# TODO: refactor
class LocalAIPlayer extends AIPlayer

    constructor: ->
        super
        @handler = new LocalHandler @

class LocalUIPlayer extends UIPlayer

    constructor: ->
        super
        @handler = new LocalHandler @

class NetworkAIPlayer extends AIPlayer

    constructor: ->
        super
        @handler = new NetworkHandler @

class NetworkUIPlayer extends UIPlayer

    constructor: ->
        super
        @handler = new NetworkHandler @

class Projectile

    constructor: (@arena, @time, @p, dirP, @skill, @team) ->
        angle = @p.angle dirP
        @destP = @p.bearing angle, @skill.range

    draw: (ctx) ->

        # Location
        ctx.filledCircle @p, @skill.radius, @skill.color

        ctx.beginPath()
        ctx.circle @p, @skill.radius - 1
        ctx.strokeStyle @arena.teams[@team].color
        ctx.lineWidth 1
        ctx.stroke()

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

        @players = []

        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0

        rp = @map.randomPoint()

        new NetworkUIPlayer @, rp, Utils.choice(name for name, r of @teams)

        numais = 1

        if numais > 0
            @teams.ai1 =
                color: "#33aa33"
                score: 0
            @teams.ai2 =
                color: "#ddaa44"
                score: 0

        for a in [0...numais]
            new NetworkAIPlayer @, @map.randomPoint(), "ai2"
            new NetworkAIPlayer @, @map.randomPoint(), "ai1"

        @projectiles = []
        @cameraSpeed = 0.3

        @mouseP = new Point 0, 0


        @mapMiddle = @mapToGo = new Point window.innerWidth / 2, window.innerHeight / 2

        addEventListener "mousemove", (event) =>
            @mouseP = new Point(
                event.x - (@map.p.x + @map.wallSize),
                event.y - (@map.p.y + @map.wallSize))

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @mapToGo = @mapMiddle.towards new Point(event.x, event.y), 100

        # well this is ugly...
        @render = @canvas.withMap @map, (ctx) =>

            # draw Map
            # Location
            wallP = new Point (-@map.wallSize / 2), (-@map.wallSize / 2)

            ctx.beginPath()
            ctx.fillStyle "#f3f3f3"
            ctx.fillRect wallP, @map.width + @map.wallSize, @map.height + @map.wallSize
            ctx.beginPath()
            ctx.lineWidth @map.wallSize
            ctx.strokeStyle "#558893"
            ctx.strokeRect wallP, @map.width + @map.wallSize, @map.height + @map.wallSize


            ctx.fillStyle "#444466"
            ctx.font "20px verdana"

            x = 50
            for name, team of @teams
                ctx.fillText "#{name}: #{team.score}", x, window.innerHeight - 20
                x += 150

            for player in @players
                player.draw ctx

            for p in @projectiles
                p.draw ctx

        @loop()

    addProjectile: (startP, destP, skill, team) ->
        p = new Projectile @, new Date().getTime(), startP, destP, skill, team
        @projectiles.push p

    allowedMovement: (newP, player) ->

        # TODO: n^2? seriously?

        currentUnallowed = 0
        newUnallowed = 0
        for otherPlayer in @players
            if otherPlayer.id isnt player.id
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
        for player in @players
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

        for player in @players
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
