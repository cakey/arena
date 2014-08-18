# TODO: filter / map
# teams


WebSocket = require 'ws'
uuid = require 'node-uuid'

Point = require "../lib/point"
Skills = require "../lib/skills"
Config = require "../lib/config"

host = "ws://#{location.hostname}:#{Config.ws.port}"
ws = new WebSocket host

client_uuid = uuid.v4()

Array::some ?= (f) ->
    (return true if f x) for x in @
    return false

Array::every ?= (f) ->
    (return false if not f x) for x in @
    return true

Array::choice ?= ->
    @[Math.floor(Math.random() * @length)]

localPlayers = {}

canvas = null
arena = null

registerPlayer = (player) ->
    localPlayers[player.id] = player
    player.arena.players.push player

ws.onopen = ->
    message =
        action: 'register'
        id: client_uuid
    ws.send JSON.stringify message

    canvas = new Canvas()
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
        position = new Point d.actionPosition.x, d.actionPosition.y
        player = localPlayers[d.playerId]

        playerPosition = new Point d.playerPosition.x, d.playerPosition.y
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
        playerPosition = new Point d.playerPosition.x, d.playerPosition.y
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

utils =
    randInt: (lower, upper = 0) ->
        start = Math.random()
        if not lower?
            [lower, upper] = [0, lower]
        if lower > upper
            [lower, upper] = [upper, lower]
        return Math.floor(start * (upper - lower + 1) + lower)

document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

speedup = 1

gameSpeed = (arg) ->
    arg * speedup

gameSpeedInverse = (arg) ->
    arg / speedup


class Canvas
    constructor: ->
        @canvas = document.getElementById 'canvas'
        @offscreenCanvas = document.createElement 'canvas'

        @canvas.width = window.innerWidth
        @canvas.height = window.innerHeight
        @offscreenCanvas.width = @canvas.width
        @offscreenCanvas.height = @canvas.height
        @ctx = @canvas.getContext '2d'
        @ctxOffscreen = @offscreenCanvas.getContext '2d'

    withMap: (map, drawFunc) ->
        =>
            @ctxOffscreen.clearRect 0, 0, @canvas.width, @canvas.height

            o = @ctxOffscreen

            # TODO: higher level...

            translatedContext =
                moveTo: (p) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.moveTo x, y
                arc: (p, args...) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.arc x, y, args...
                strokeRect: (p, args...) ->
                    x = p.x + map.p.x + map.wallSize
                    y = p.y + map.p.y + map.wallSize
                    o.strokeRect x, y, args...
                circle: (p, radius) -> translatedContext.arc p, radius, 0, 2 * Math.PI
                beginPath: -> o.beginPath()
                fillStyle: (arg) -> o.fillStyle = arg
                fill: o.fill.bind o
                lineWidth: (arg) -> o.lineWidth = arg
                setLineDash: o.setLineDash.bind o
                stroke: o.stroke.bind o
                fillText: o.fillText.bind o
                font: (arg) -> o.font = arg
                strokeStyle: (arg) -> o.strokeStyle = arg

            drawFunc translatedContext

            @ctx.clearRect 0, 0, @canvas.width, @canvas.height
            @ctx.drawImage @offscreenCanvas, 0, 0

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
            radiusMs = @radius / gameSpeedInverse(@castedSkill.castTime)
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
        ctx.beginPath()
        ctx.circle @p, @radius
        ctx.fillStyle @arena.teams[@team].color
        ctx.fill()

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

        newP = @p.towards @destP, (gameSpeed(@speed) * msDiff)
        if @arena.allowedMovement newP, @
            @p = newP

        # Cast

        if @startCastTime?
            if newTime - @startCastTime > gameSpeedInverse(@castedSkill.castTime)
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

        if Math.random() < gameSpeed(0.005) and not @startCastTime?
            @handler.fire otherPs.choice().p, 'orb'

        if not @startCastTime? and (Math.random() < gameSpeed(0.03) or (@p.equal @destP))
            @handler.moveTo @arena.map.randomPoint()
            #@moveTo(
            #    ((@arena.p1.x+@x)/2)+utils.randInt(-250,250),
            #    ((@arena.p1.y+@y)/2)+utils.randInt(-250,250)
            #)

class UIPlayer extends Player

    constructor: ->
        super
        addEventListener "mousedown", (event) =>
            topLeft = new Point @radius, @radius
            bottomRight = new Point(
                @arena.map.width - @radius,
                @arena.map.height - @radius)

            p = @arena.mouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo p

        addEventListener "keypress", (event) =>
            keyBindings =
                103: 'orb'
                104: 'disrupt'
                98: 'gun'
                110: 'slowgun'

            if skill = keyBindings[event.which]
                @handler.fire (@arena.mouseP.mapBound @p, @arena.map), skill
            else
                console.log event
                console.log event.which

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
                playerPosition:
                    x: @player.p.x
                    y: @player.p.y
                team: @player.team
            id: client_uuid
        ws.send JSON.stringify message

    moveTo: (p) ->
        message =
            action: 'control'
            data:
                playerId: @player.id
                action: 'moveTo'
                actionPosition:
                    x: p.x
                    y: p.y
                playerPosition:
                    x: @player.p.x
                    y: @player.p.y
                team: @player.team
            id: client_uuid
        ws.send JSON.stringify message

    fire: (p, skillName) ->
        message =
            action: 'control'
            data:
                playerId: @player.id
                action: 'fire'
                actionPosition:
                    x: p.x
                    y: p.y
                playerPosition:
                    x: @player.p.x
                    y: @player.p.y
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
        ctx.beginPath()
        ctx.circle @p, @skill.radius
        ctx.fillStyle @skill.color
        ctx.fill()

    update: (newTime) ->

        if @p.equal @destP
            return false

        msDiff = newTime - @time

        @p = @p.towards @destP, (gameSpeed(@skill.speed) * msDiff)

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
                new Point(utils.randInt(0, @map.width), utils.randInt(0, @map.height))

        @players = []

        @teams =
            red:
                color: "#aa3333"
                score: 0
            blue:
                color: "#3333aa"
                score: 0
        ###
        ai1:
            color: "#33aa33"
            players: []
            score: 0
        ai2:
            color: "#3333aa"
            players: []
            score: 0
        ###

        rp = @map.randomPoint()

        new NetworkUIPlayer @, rp, (name for name, r of @teams).choice()

        numais = 0

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
            ctx.beginPath()
            ctx.lineWidth @map.wallSize
            ctx.strokeStyle "#558893"
            wallP = new Point (-@map.wallSize / 2), (-@map.wallSize / 2)
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
                return player.team if p.p.within player.p, p.skill.radius + player.radius
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
        for p in @projectiles
            alive = p.update updateTime
            if alive
                if hitTeam = @projectileCollide p
                    @teams[p.team].score += 1
                    @teams[hitTeam].score -= 1

                else
                    newProjectiles.push p
        @projectiles = newProjectiles

        @time = updateTime
