_ = require 'lodash'
React = require "react/addons"

Utils = require "../lib/utils"
Point = require "../lib/point"
Skills = require "../lib/skills"

# half this crap should just be css/html

# uiBoxRenderer = (topLeft, size, staticCtx) ->
#     # background
#     staticCtx.beginPath()
#     staticCtx.fillStyle "#f3f3f3"
#     staticCtx.fillRect topLeft, size

#     # border
#     staticCtx.beginPath()
#     staticCtx.strokeStyle "#558893"
#     staticCtx.lineWidth 1
#     staticCtx.strokeRect topLeft, size

# uiRenderer = (processor, teams, ctx, staticCtx) ->

#     # TODO: This needs a refactor!!

#     staticCtx.globalAlpha 0.8

#     backLoc = new Point (window.innerWidth - 220), 20
#     scoreBoxSize = new Point(200, (Object.keys(teams).length * 32) + 20)
#     uiBoxRenderer backLoc, scoreBoxSize, staticCtx

#     staticCtx.font "16px verdana"

#     teamKeys = Object.keys(teams)
#     teamKeys.sort (a,b) -> teams[b].score - teams[a].score

#     y = 50
#     for name in teamKeys
#         location = new Point(window.innerWidth - 200, y)

#         staticCtx.fillStyle "#222233"
#         staticCtx.fillText name, location

#         location = new Point(window.innerWidth - 100, y)

#         staticCtx.fillStyle "#444466"
#         staticCtx.fillText teams[name].score, location

#         y += 32

#     staticCtx.globalAlpha 1

#     # Draw skill icons

#     rows = [
#         ['1','2','3','4','5','6','7','8','9','0','-','=']
#         ['q','w','e','r','t','y','u','i','o','p','[',']']
#         ['a','s','d','f','g','h','j','k','l',';','\'']
#         ['z','x','c','v','b','n','m',',','.','/']
#     ]
#     rowOffsets = [0,35,50,90]

#     keySize = 48
#     keyBorder = 6
#     leftMargin = keySize
#     topMargin = window.innerHeight - (keySize * 4 + keyBorder * 5)
#     fontSize = 14
#     keySizeP = new Point(keySize, keySize)

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

#                 pctCooldown = processor.pctCooldown skillName
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
#         if processor.arena.map.mouseP.inside locs[0], locs[1]

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

ScoreBoard = React.createClass
    render: ->
        teams = @props.teams
        teamKeys = Object.keys(teams)
        teamKeys.sort (a,b) -> teams[b].score - teams[a].score

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

SkillBoxUI = React.createClass
    render: ->
        <div className="keyBox" style={{
            left: @props.left, position: "absolute",
            }}>
            <Circle
                center={new Point 26,26}
                color={@props.skill.color}
                radius={@props.skill.radius}
            />
            {
                if @props.pctCooldown < 1
                    cooldownStyle =
                        width: "100%"
                        left: "0%"
                        top: "#{(@props.pctCooldown) * 100}%"
                        height: "#{(1 - @props.pctCooldown) * 100}%"
                        background: "rgba(34,34,85,0.8)"
                        position: "absolute"
                    cooldownTextStyle =
                        position: "absolute"
                        textAlign: "center"
                        fontSize: "16px"
                        fontFamily: "Verdana"
                        color: "#ffffff"
                        width: "80%"
                        top: "30%"
                        background: "rgba(34,34,85,0.65)"

                    num = Math.round(@props.skill.cooldown * (1 - @props.pctCooldown) / 100)
                    point = num % 10
                    secs = Math.round(num / 10)
                    <div>
                        <div className="cooldown" style={cooldownStyle}></div>
                        <div style={cooldownTextStyle}>{"#{secs}.#{point}"}</div>
                    </div>
            }
            <div className="keyText" > {@props.boundKey} </div>
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
                    { for boundKey, ki in row
                        skillName = @props.UIplayer.keyBindings[boundKey]
                        if skill = Skills[skillName]
                            pctCooldown = @props.UIplayer.pctCooldown skillName
                            left = (rowOffsets[ri]+ki)*(60+5)
                            <SkillBoxUI
                                skill={skill}
                                boundKey={boundKey}
                                left={left}
                                key={ki}
                                pctCooldown={pctCooldown}
                            />
                    }
                </div>
            }
        </div>

Arena = React.createClass
    render: ->
        # ctx = @props.canvas.mapContext(@props.arena.map)
        # arenaMapRenderer @props.arena.props.arena, ctx
        # Get contexts for rendering.
        ctx = @props.arena.canvas.mapContext @props.arena.map
        staticCtx = @props.arena.canvas.context()

        # Render map.
        @props.arena.map.render ctx

        # Render Players.
        for id, player of @props.arena.handler.players
            player.render ctx

        # Render projectiles.
        for p in @props.arena.projectiles
            p.render ctx
        <div>
            <ScoreBoard teams={@props.arena.teams} />
            <SkillUI UIplayer={@props.arena.focusedUIPlayer}/>
        </div>

arenaRenderer = (arena, canvas) ->
    React.render(
        <Arena arena={arena} canvas={canvas} />
        document.getElementById('arena')
    )

Renderers =
    arena: arenaRenderer

module.exports = Renderers
