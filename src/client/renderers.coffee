Utils = require "../lib/utils"
Point = require "../lib/point"
Skills = require "../lib/skills"

playerRenderer = (player, ctx) ->

    # Cast
    if player.startCastTime?
        radiusMs = player.radius / Utils.game.speedInverse(player.castedSkill.castTime)
        radius = (radiusMs * (player.time - player.startCastTime)) + player.radius

        angle = player.p.angle player.castP
        halfCone = player.castedSkill.cone / 2

        ctx.beginPath()
        ctx.moveTo player.p
        ctx.arc player.p, radius, angle - halfCone, angle + halfCone
        ctx.moveTo player.p
        ctx.fillStyle player.castedSkill.color
        ctx.fill()

    # Location
    ctx.filledCircle player.p, player.radius, player.arena.teams[player.team].color

    # casting circle

    ctx.beginPath()
    ctx.circle player.p, player.maxCastRadius
    ctx.lineWidth 1
    ctx.setLineDash [3,12]
    ctx.strokeStyle "#777777"
    ctx.stroke()
    ctx.setLineDash []

projectileRenderer = (projectile, ctx) ->

    # Location
    ctx.filledCircle projectile.p, projectile.skill.radius, projectile.skill.color

    ctx.beginPath()
    ctx.circle projectile.p, projectile.skill.radius - 1
    ctx.strokeStyle projectile.arena.teams[projectile.team].color
    ctx.lineWidth 1
    ctx.stroke()

arenaRenderer = (arena, canvas) ->

    # draw Map
    # Location

    ctx = canvas.mapContext(arena.map)
    staticCtx = canvas.context()

    map = arena.map

    wallP = new Point (-map.wallSize / 2), (-map.wallSize / 2)

    ctx.beginPath()
    ctx.fillStyle "#f3f3f3"
    ctx.fillRect wallP, map.width + map.wallSize, map.height + map.wallSize
    ctx.beginPath()
    ctx.lineWidth map.wallSize
    ctx.strokeStyle "#558893"
    ctx.strokeRect wallP, map.width + map.wallSize, map.height + map.wallSize


    staticCtx.fillStyle "#444466"
    staticCtx.font "20px verdana"

    x = 50
    for name, team of arena.teams
        staticCtx.fillText "#{name}: #{team.score}", new Point(x, window.innerHeight - 20)
        x += 150

    Renderers.ui arena.focusedUIPlayer, ctx, staticCtx

    for id, player of arena.handler.players
        Renderers.player player, ctx, staticCtx

    for p in arena.projectiles
        Renderers.projectile p, ctx, staticCtx

uiRenderer = (processor, ctx, staticCtx) ->

    upperRow = ['q','w','e','r','t','y','u','i','o','p','[',']']
    homeRow = ['a','s','d','f','g','h','j','k','l',';','\'']
    bottomRow = ['z','x','c','v','b','n','m',',','.','/']

    keySize = 50
    keyBorder = 20
    leftMargin = 50
    for key, index in homeRow
        if skill = Skills[processor.keyBindings[key]]
            staticCtx.beginPath()
            staticCtx.fillStyle "#f3f3f3"
            keyOffsetX = index * (keySize + keyBorder)
            keyP = new Point(leftMargin + keyOffsetX, window.innerHeight - 100)
            staticCtx.fillRect keyP, keySize, keySize
            staticCtx.beginPath()
            staticCtx.strokeStyle "#558893"
            staticCtx.lineWidth 2
            staticCtx.strokeRect keyP, 50, 50

            projectileOffset = new Point 24, 15
            staticCtx.filledCircle (keyP.add projectileOffset), skill.radius, skill.color

            staticCtx.fillStyle "#444466"
            staticCtx.font "16px verdana"
            textOffset = new Point 21, 45
            staticCtx.fillText key, (keyP.add textOffset)

Renderers =
    player: playerRenderer
    projectile: projectileRenderer
    arena: arenaRenderer
    ui: uiRenderer

module.exports = Renderers
