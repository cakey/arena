Utils = require "../lib/utils"
Point = require "../lib/point"
Skills = require "../lib/skills"
Config = require "../lib/config"

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
    if Config.UI.castingCircles
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


    for id, player of arena.handler.players
        Renderers.player player, ctx, staticCtx

    for p in arena.projectiles
        Renderers.projectile p, ctx, staticCtx

    Renderers.ui arena.focusedUIPlayer, ctx, staticCtx

    staticCtx.globalAlpha 0.8

    backLoc = new Point (window.innerWidth - 220), 20

    # background
    staticCtx.beginPath()
    staticCtx.fillStyle "#f3f3f3"
    staticCtx.fillRect backLoc, 200, (Object.keys(arena.teams).length * 32) + 20

    # border
    staticCtx.beginPath()
    staticCtx.strokeStyle "#558893"
    staticCtx.lineWidth 1
    staticCtx.strokeRect backLoc, 200, (Object.keys(arena.teams).length * 32) + 20

    staticCtx.font "16px verdana"

    teamKeys = Object.keys(arena.teams)
    teamKeys.sort (a,b) -> arena.teams[b].score - arena.teams[a].score

    y = 50
    for name in teamKeys
        location = new Point(window.innerWidth - 200, y)

        staticCtx.fillStyle "#222233"
        staticCtx.fillText name, location

        location = new Point(window.innerWidth - 100, y)

        staticCtx.fillStyle "#444466"
        staticCtx.fillText arena.teams[name].score, location

        y += 32

    staticCtx.globalAlpha 1

uiRenderer = (processor, ctx, staticCtx) ->

    # TODO: This needs a refactor!!

    # Draw skill icons

    rows = [
        ['1','2','3','4','5','6','7','8','9','0','-','=']
        ['q','w','e','r','t','y','u','i','o','p','[',']']
        ['a','s','d','f','g','h','j','k','l',';','\'']
        ['z','x','c','v','b','n','m',',','.','/']
    ]
    rowOffsets = [0,35,50,90]

    keySize = 48
    keyBorder = 6
    leftMargin = keySize
    topMargin = window.innerHeight - (keySize * 4 + keyBorder * 5)
    fontSize = 14

    iconsLocations = {} # Skill: [topleft, bottomright]

    for row, rIndex in rows
        for key, cIndex in row
            skillName = processor.keyBindings[key]
            if skill = Skills[skillName]
                keyOffsetX = cIndex * (keySize + keyBorder)
                keyX = leftMargin + keyOffsetX + rowOffsets[rIndex]
                keyOffsetY = rIndex * (keySize + keyBorder)
                keyY = topMargin + keyOffsetY
                keyP = new Point keyX, keyY
                iconsLocations[skillName] = [keyP, keyP.add(new Point keySize, keySize)]

                staticCtx.globalAlpha 0.8

                # background
                staticCtx.beginPath()
                staticCtx.fillStyle "#f3f3f3"
                staticCtx.fillRect keyP, keySize, keySize

                # projectile
                projectileOffset = new Point (keySize / 2), (keySize / 3)
                projectileLocation = keyP.add projectileOffset
                staticCtx.filledCircle projectileLocation, skill.radius, skill.color

                staticCtx.globalAlpha 1

                # border
                staticCtx.beginPath()
                staticCtx.strokeStyle "#558893"
                staticCtx.lineWidth 1
                staticCtx.strokeRect keyP, keySize, keySize

                # text
                staticCtx.fillStyle "#444466"
                staticCtx.font "#{fontSize}px verdana"
                textOffset = new Point(
                    ((keySize / 2) - fontSize / 4),
                    (keySize - fontSize / 2)
                )
                staticCtx.fillText key, (keyP.add textOffset)

    # Draw skill overlay if hovered.
    for skillName, locs of iconsLocations
        if processor.arena.mouseP.inside locs[0], locs[1]

            skill = Skills[skillName]

            overLayX = 220

            # need to calculate description length for Y size of overlay
            maxChars = ((overLayX * 2) / fontSize) - 6
            descLines = Utils.string.wordWrap skill.description, maxChars
            skillKeys = ["castTime", "speed", "range", "score"]

            overLayY = (skillKeys.length + descLines.length + 2) * fontSize * 2

            overlaySize = new Point overLayX, overLayY
            border = new Point 0, keyBorder

            staticCtx.globalAlpha 0.8

            topLeft = locs[0]
                .subtract(new Point (overlaySize.x / 2), overlaySize.y)
                .add(new Point (keySize / 2), 0)
                .subtract(border)

            # background
            staticCtx.beginPath()
            staticCtx.fillStyle "#f3f3f3"
            staticCtx.fillRect topLeft, overlaySize.x, overlaySize.y

            staticCtx.globalAlpha 1

            staticCtx.font "#{fontSize}px verdana"
            labelOffset = new Point(
                fontSize
                fontSize * 2
            )
            staticCtx.fillStyle skill.color
            staticCtx.fillText skillName, (topLeft.add labelOffset)

            # text
            for textType, i in skillKeys
                staticCtx.font "#{fontSize}px verdana"
                labelOffset = new Point(
                    fontSize
                    fontSize * 2 * (i + 2)
                )
                staticCtx.fillStyle "#444466"
                staticCtx.fillText textType, (topLeft.add labelOffset)
                numberOffset = new Point(
                    overLayX - fontSize * 4
                    fontSize * 2 * (i + 2)
                )
                staticCtx.fillStyle "#009944"
                staticCtx.fillText skill[textType], (topLeft.add numberOffset)

            # description
            for line, i in descLines
                staticCtx.font "#{fontSize}px verdana"
                labelOffset = new Point(
                    fontSize
                    fontSize * 2 * (i + 2 + skillKeys.length)
                )
                staticCtx.fillStyle "#444466"
                staticCtx.fillText line, (topLeft.add labelOffset)

            # border
            staticCtx.beginPath()
            staticCtx.strokeStyle "#558893"
            staticCtx.lineWidth 1
            staticCtx.strokeRect topLeft, overlaySize.x, overlaySize.y


    return # stupid implicit returns

Renderers =
    player: playerRenderer
    projectile: projectileRenderer
    arena: arenaRenderer
    ui: uiRenderer

module.exports = Renderers
