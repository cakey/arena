Utils = require "../lib/utils"
Point = require "../lib/point"
Skills = require "../lib/skills"
Config = require "../lib/config"

_ = require 'lodash'
React = require "react/addons"

playerRenderer = (player, ctx) ->
    # Cast
    if player.startCastTime?
        realCastTime = Utils.game.speedInverse(Skills[player.castedSkill].castTime)
        radiusMs = player.radius / realCastTime
        radius = (radiusMs * (player.time - player.startCastTime)) + player.radius

        angle = player.p.angle player.castP
        halfCone = Skills[player.castedSkill].cone / 2

        ctx.beginPath()
        ctx.moveTo player.p
        ctx.arc player.p, radius, angle - halfCone, angle + halfCone
        ctx.moveTo player.p
        ctx.fillStyle Skills[player.castedSkill].color
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
    ctx.filledCircle projectile.p, projectile.skill.radius, projectile.skill.color

    ctx.beginPath()
    ctx.circle projectile.p, projectile.skill.radius - 1
    ctx.strokeStyle projectile.arena.teams[projectile.team].color
    ctx.lineWidth 1
    ctx.stroke()

arenaMapRenderer = (arena, ctx) ->
    map = arena.map

    wallP = new Point (-map.wallSize.x / 2), (-map.wallSize.y / 2)

    ctx.beginPath()
    ctx.fillStyle "#f3f3f3"
    ctx.fillRect wallP, map.size.add(map.wallSize)
    ctx.beginPath()
    ctx.lineWidth map.wallSize.x
    ctx.strokeStyle "#558893"
    ctx.strokeRect wallP, map.size.add(map.wallSize)

    for k, v of arena.handler.players
        playerRenderer v, ctx

    for k, v of arena.projectiles
        projectileRenderer v, ctx

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
        teamKeys = Object.keys(@props.teams)
        teamKeys.sort (a,b) => @props.teams[b].score - @props.teams[a].score

        <div className="scoreBox box" >
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
    getInitialState: ->
        hover: false
    mouseIn: ->
        @setState
            hover: true
    mouseOut: ->
        @setState
            hover: false
    render: ->
        <div style={{ left: @props.left, position: "absolute"}}>
            <div className="keyBox box" onMouseEnter={@mouseIn} onMouseLeave={@mouseOut} >
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
            {
                if @state.hover
                    overLayX = 200
                    fontSize = 16
                    maxChars = ((overLayX * 2) / fontSize) - 6
                    descLines = Utils.string.wordWrap @props.skill.description, maxChars
                    skillKeys = ["castTime", "speed", "range", "score", "cooldown"]

                    overLayY = (skillKeys.length + descLines.length/2 + 1) * fontSize * 2

                    overlaySize = new Point overLayX, overLayY
                    tooltipstyle =
                        width: overLayX
                        height: overLayY
                        position: "absolute"
                        top: -(overLayY+75)
                        left: -((overLayX/2))
                    <div className="skillTooltip box" style={tooltipstyle}>
                        <div style={color:@props.skill.color}>{@props.skillName}</div>
                        { for textType, i in skillKeys
                            <div key={i} >
                                <div style={color:"#444466", position:"absolute", top:fontSize*2*(i+2)}>{textType}</div>
                                <div style={color:"#009944", position:"absolute", top:fontSize*2*(i+2), left:overLayX}>{@props.skill[textType]}</div>
                            </div>
                        }
                        { for descLine, i in descLines
                            <div style={color:"#444466", position:"absolute", top:(fontSize*2*((i/2)+2+skillKeys.length)), left: 25} key={i}>{descLine}</div>
                        }
                    </div>
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
                    { for boundKey, ki in row
                        skillName = @props.UIplayer.keyBindings[boundKey]
                        if skill = Skills[skillName]
                            pctCooldown = @props.UIplayer.player.pctCooldown skillName
                            left = (rowOffsets[ri]+ki)*(60+5)
                            <SkillBoxUI
                                skill={skill}
                                skillName={skillName}
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
        ctx = @props.canvas.mapContext(@props.arena.map)
        arenaMapRenderer @props.arena, ctx
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
