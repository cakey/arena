Utils = require "../lib/utils"
Point = require "../lib/point"
Skills = require "../lib/skills"
# Config = require "../lib/config"

# pull out circle

_ = require 'lodash'
React = require "react/addons"

Circle = React.createClass
    render: ->
        style =
            width: "#{@props.radius * 2}px"
            height: "#{@props.radius * 2}px"
            left: @props.center.x
            top: @props.center.y
            position: "absolute"
            transform: "translate(-50%, -50%)"
            background: @props.color
            borderRadius: "50%"
        _.assign style, @props.extraStyle
        <div style={style}>
            {@props.children}
        </div>

Arc = React.createClass
    render: ->

        radius = @props.radius
        startAngle = (@props.angle) + Math.PI - (@props.cone / 2)

        arcS = []
        borderV = "solid #{radius}px #{@props.color}"
        # I would clean this up if this wasn't a stupid long term plan (Ben Shaw Jan 2015 ;P)
        if @props.cone < Math.PI / 2
            realCone = (Math.PI / 2) - @props.cone
            arcO0 =
                transform: "rotate(#{startAngle}rad) skewX(#{realCone}rad)"
            arcI0 =
                transform: "skewX(-#{realCone}rad)"
                border: borderV
            arcS.push [arcO0, arcI0]
        else if @props.cone < Math.PI
            arcO0 =
                transform: "rotate(#{startAngle}rad) skewX(0rad)"
            arcI0 =
                transform: "skewX(-0rad)"
                border: borderV
            arcS.push [arcO0, arcI0]

            realCone = Math.PI/2 - (@props.cone - Math.PI/2)
            arcO1 =
                transform: "rotate(#{startAngle + Math.PI/2 }rad) skewX(#{realCone}rad)"
            arcI1 =
                transform: "skewX(-#{realCone}rad)"
                border: borderV
            arcS.push [arcO1, arcI1]
        # else if > 180deg...

        <Circle radius={radius} center={@props.center} extraStyle={{zIndex: "-5"}}>
            { for [arcOuterStyle, arcInnerStyle], i in arcS
                <div style={arcOuterStyle} className="arcOuter" key={i} >
                    <div style={arcInnerStyle} className="arcInner" />
                </div>
            }
        </Circle>

Player = React.createClass
    render: ->
        player = @props.player
        <div>
            <Circle
                radius={player.radius}
                center={player.p}
                color={player.arena.teams[player.team].color}
            />
            {
                if player.startCastTime?
                    realCastTime = Utils.game.speedInverse(Skills[player.castedSkill].castTime)
                    radiusMs = player.radius / realCastTime
                    radius = (radiusMs * (player.time - player.startCastTime)) + player.radius

                    angle = angle = player.p.angle player.castP
                    cone = Skills[player.castedSkill].cone

                    <Arc
                        angle={angle}
                        cone={cone}
                        radius={radius}
                        color={Skills[player.castedSkill].color}
                        center={player.p}
                    />
            }

        </div>

Projectile = React.createClass
    render: ->
        p = @props.projectile
        extraStyle =
            borderWidth: 1
            borderStyle: "solid"
            borderColor: p.arena.teams[p.team].color

        <Circle
            radius={p.skill.radius}
            center={p.p}
            color={p.skill.color}
            extraStyle={extraStyle}
        />

ScoreBoard = React.createClass
    render: ->
        teamKeys = Object.keys(@props.teams)
        teamKeys.sort (a,b) => @props.teams[b].score - @props.teams[a].score

        <div className="scoreBox" >
            {teamKeys.map (teamKey, i) =>
                <div className="scoreRow" key={i} >
                    <span className="teamName" >
                        {teamKey}
                    </span>
                    <span className="scoreValue" >
                        {@props.teams[teamKey].score}
                    </span>
                </div>
            }
        </div>

ArenaMap = React.createClass
    render: ->

        style =
            left: @props.arena.map.p.x
            top: @props.arena.map.p.y
            width: @props.arena.map.size.x
            height: @props.arena.map.size.y
            position: "fixed"
            borderWidth: @props.arena.map.wallSize.x

        <div style={style} className="baseMap" >
            {for k, v of @props.arena.handler.players
                <Player player={v} key={k} />
            }
            {for k, v of @props.arena.projectiles
                <Projectile projectile={v} key={k} />
            }
        </div>


SkillUI = React.createClass
    render: ->
        rows = [
            ['1','2','3','4','5','6','7','8','9','0','-','=']
            ['q','w','e','r','t','y','u','i','o','p','[',']']
            ['a','s','d','f','g','h','j','k','l',';','\'']
            ['z','x','c','v','b','n','m',',','.','/']
        ]
        rowOffsets = [0,0.5,0.8,1.2]
        <div>
            { for row, ri in rows
                <div key={ri} style={{bottom: (rows.length - ri) *60, position: "fixed"}}>
                    { for k, ki in row
                        skillName = @props.UIplayer.keyBindings[k]
                        if skill = Skills[skillName]
                            <div key={ki} className="keyBox" style={{
                                left: (rowOffsets[ri]+ki)*(60+5), position: "absolute",
                                }}>
                                <Circle
                                    center={new Point 26,26}
                                    color={skill.color}
                                    radius={skill.radius}
                                />
                                <div className="keyText" > {k} </div>
                            </div>
                    }
                </div>
            }
        </div>

Arena = React.createClass
    render: ->
        <div>
            <ArenaMap arena={@props.arena} />
            <ScoreBoard teams={@props.arena.teams} />
            <SkillUI UIplayer={@props.arena.focusedUIPlayer}/>
        </div>

arenaRenderer = (arena) ->
    React.render(
        <Arena arena={arena} />
        document.getElementById('arena')
    )


# uiRenderer = (processor, ctx, staticCtx) ->

#     # TODO: This needs a refactor!!

#     # Draw skill icons

#     rowOffsets = [0,35,50,90]


#     iconsLocations = {} # Skill: [topleft, bottomright]

#     for row, rIndex in rows
#         for key, cIndex in row
#             skillName = processor.keyBindings[key]
#             if skill = Skills[skillName]
#                 keyOffsetX = cIndex * (keySize + keyBorder)
#                 keyX = leftMargin + keyOffsetX + rowOffsets[rIndex]
#                 keyOffsetY = rIndex * (keySize + keyBorder)
#                 keyY = topMargin + keyOffsetY
#                 keyP = new Point keyX, keyY
#                 iconsLocations[skillName] = [keyP, keyP.add keySizeP]

#                 staticCtx.globalAlpha 0.8

#                 uiBoxRenderer keyP, keySizeP, staticCtx

#                 # projectile
#                 projectileOffset = new Point (keySize / 2), (keySize / 3)
#                 projectileLocation = keyP.add projectileOffset
#                 staticCtx.filledCircle projectileLocation, skill.radius, skill.color

#                 # text
#                 staticCtx.fillStyle "#444477"
#                 staticCtx.font "#{fontSize}px verdana"
#                 textOffset = new Point(
#                     ((keySize / 2) - fontSize / 4),
#                     (keySize - fontSize / 2)
#                 )
#                 staticCtx.fillText key, (keyP.add textOffset)

#                 staticCtx.globalAlpha 1

#                 # draw cooldown if necessary

#                 pctCooldown = processor.player.pctCooldown skillName
#                 if pctCooldown < 1
#                     # background
#                     staticCtx.globalAlpha 0.8
#                     staticCtx.beginPath()
#                     staticCtx.fillStyle "#222255"
#                     ySize = keySize * (1 - pctCooldown)

#                     staticCtx.fillRect(
#                         new Point(keyX, keyY + (keySize - ySize)),
#                         new Point keySize, ySize
#                     )


#                     # text
#                     num = Math.round(skill.cooldown * (1 - pctCooldown) / 100)
#                     point = num % 10
#                     secs = Math.round(num / 10)
#                     txt = "#{secs}.#{point}"

#                     staticCtx.fillStyle "#ffffff"
#                     staticCtx.strokeStyle "#222255"
#                     staticCtx.font "16px verdana"
#                     textOffset = new Point(
#                         keySize / 2 - 8 * (txt.length) / 2,
#                         keySize / 2 + 8
#                     )
#                     staticCtx.lineWidth 3
#                     staticCtx.strokeText txt, (keyP.add textOffset)
#                     staticCtx.globalAlpha 1
#                     staticCtx.fillText txt, (keyP.add textOffset)


#     # Draw skill overlay if hovered.
#     for skillName, locs of iconsLocations
#         if processor.arena.mouseP.inside locs[0], locs[1]

#             skill = Skills[skillName]

#             overLayX = 220

#             # need to calculate description length for Y size of overlay
#             maxChars = ((overLayX * 2) / fontSize) - 6
#             descLines = Utils.string.wordWrap skill.description, maxChars
#             skillKeys = ["castTime", "speed", "range", "score", "cooldown"]

#             overLayY = (skillKeys.length + descLines.length + 2) * fontSize * 2

#             overlaySize = new Point overLayX, overLayY
#             border = new Point 0, keyBorder

#             staticCtx.globalAlpha 0.8

#             topLeft = locs[0]
#                 .subtract(new Point (overlaySize.x / 2), overlaySize.y)
#                 .add(new Point (keySize / 2), 0)
#                 .subtract(border)

#             uiBoxRenderer topLeft, overlaySize, staticCtx

#             staticCtx.font "#{fontSize}px verdana"
#             labelOffset = new Point(
#                 fontSize
#                 fontSize * 2
#             )
#             staticCtx.fillStyle skill.color
#             staticCtx.fillText skillName, (topLeft.add labelOffset)

#             # text
#             for textType, i in skillKeys
#                 staticCtx.font "#{fontSize}px verdana"
#                 labelOffset = new Point(
#                     fontSize
#                     fontSize * 2 * (i + 2)
#                 )
#                 staticCtx.fillStyle "#444466"
#                 staticCtx.fillText textType, (topLeft.add labelOffset)
#                 numberOffset = new Point(
#                     overLayX - fontSize * 4
#                     fontSize * 2 * (i + 2)
#                 )
#                 staticCtx.fillStyle "#009944"
#                 staticCtx.fillText skill[textType], (topLeft.add numberOffset)

#             # description
#             for line, i in descLines
#                 staticCtx.font "#{fontSize}px verdana"
#                 labelOffset = new Point(
#                     fontSize
#                     fontSize * 2 * (i + 2 + skillKeys.length)
#                 )
#                 staticCtx.fillStyle "#444466"
#                 staticCtx.fillText line, (topLeft.add labelOffset)

#             staticCtx.globalAlpha 1

#     return # stupid implicit returns

Renderers =
    arena: arenaRenderer

module.exports = Renderers
