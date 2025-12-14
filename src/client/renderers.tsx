import _ from "lodash"
import React, { useState } from "react"
import { createRoot } from "react-dom/client"
import { flushSync } from "react-dom"
import Utils from "../lib/utils"
import Point from "../lib/point"
import skills from "../lib/skills"
import { aiDebugState } from "../lib/ai"
import type GameState from "../lib/game-state"
import type Canvas from "./canvas"
import type Camera from "./camera"
import type { UIPlayer } from "../lib/player"

const Circle: React.FC<{ radius: number; center: Point; color: string; extraStyle?: React.CSSProperties; children?: React.ReactNode }> =
  ({ radius, center, color, extraStyle, children }) => (
    <div style={{
      width: `${radius * 2}px`, height: `${radius * 2}px`, left: center.x, top: center.y, position: "absolute",
      transform: "translate(-50%, -50%)", background: color, borderRadius: "50%", ...extraStyle
    }}>{children}</div>
  )

const Arc: React.FC<{ radius: number; center: Point; angle: number; cone: number; color: string }> =
  ({ radius, center, angle, cone, color }) => {
    const startAngle = angle + Math.PI - cone / 2
    const arcS: [React.CSSProperties, React.CSSProperties][] = []
    const borderV = `solid ${radius}px ${color}`
    if (cone < Math.PI / 2) {
      const realCone = Math.PI / 2 - cone
      arcS.push([{ transform: `rotate(${startAngle}rad) skewX(${realCone}rad)` },
                 { transform: `skewX(-${realCone}rad)`, border: borderV }])
    } else if (cone < Math.PI) {
      arcS.push([{ transform: `rotate(${startAngle}rad) skewX(0rad)` }, { transform: "skewX(-0rad)", border: borderV }])
      const realCone = Math.PI / 2 - (cone - Math.PI / 2)
      arcS.push([{ transform: `rotate(${startAngle + Math.PI / 2}rad) skewX(${realCone}rad)` },
                 { transform: `skewX(-${realCone}rad)`, border: borderV }])
    }
    return (
      <Circle radius={radius} center={center} color="" extraStyle={{ zIndex: -5 }}>
        {arcS.map(([outer, inner], i) => (
          <div key={i} style={outer} className="arcOuter"><div style={inner} className="arcInner" /></div>
        ))}
      </Circle>
    )
  }

const ScoreBoard: React.FC<{ teams: Record<string, { color: string; score: number }> }> = ({ teams }) => {
  const teamKeys = Object.keys(teams).sort((a, b) => teams[b].score - teams[a].score)
  return (
    <div className="scoreBox box">
      {teamKeys.map((teamKey, i) => (
        <div className="scoreRow" key={i}>
          <span style={{ color: teams[teamKey].color }} className="teamName">{teamKey}</span>
          <span className="scoreValue">{Math.floor(teams[teamKey].score / 100)}</span>
        </div>
      ))}
    </div>
  )
}

const SkillBoxUI: React.FC<{ skill: any; skillName: string; boundKey: string; left: number; pctCooldown: number }> =
  ({ skill, skillName, boundKey, left, pctCooldown }) => {
    const [hover, setHover] = useState(false)
    const displayRadius = Math.min(skill.radius, 22)
    const center = new Point(34, 34)
    return (
      <div style={{ left, position: "absolute" }}>
        <div className="keyBox box" onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}>
          <div className="skillLabel">{skillName}</div>
          {skill.type === "projectile" && (
            <Circle center={center} color={skill.color} radius={displayRadius} />
          )}
          {skill.type === "ground_targeted" && (
            <div style={{ position: "absolute", left: center.x - displayRadius, top: center.y - displayRadius,
              width: displayRadius * 2, height: displayRadius * 2, background: skill.color, opacity: 0.7,
              border: `2px solid ${skill.color}`, borderRadius: "4px" }} />
          )}
          {skill.type === "targeted" && (
            <Circle center={center} color={skill.color} radius={displayRadius} extraStyle={{ border: `3px dashed ${skill.color}`, background: "transparent" }} />
          )}
          {pctCooldown < 1 && (
            <div>
              <div className="cooldown" style={{
                width: "100%", left: "0%", top: `${pctCooldown * 100}%`, height: `${(1 - pctCooldown) * 100}%`,
                background: "rgba(34,34,85,0.8)", position: "absolute"
              }} />
              <div style={{
                position: "absolute", textAlign: "center", fontSize: 14, fontFamily: "Verdana",
                color: "#ffffff", width: "100%", top: "35%", background: "rgba(34,34,85,0.65)"
              }}>
                {`${Math.floor(Math.round(skill.cooldown * (1 - pctCooldown) / 100) / 10)}.${Math.round(skill.cooldown * (1 - pctCooldown) / 100) % 10}`}
              </div>
            </div>
          )}
          <div className="keyText">{boundKey.toUpperCase()}</div>
        </div>
        {hover && (() => {
          const overLayX = 200, fontSize = 16
          const maxChars = (overLayX * 2) / fontSize - 6
          const descLines = Utils.string.wordWrap(skill.description, maxChars)
          const skillKeys = ["castTime", "speed", "range", "score", "cooldown"]
          const overLayY = (skillKeys.length + descLines.length / 2 + 1) * fontSize * 2
          const tooltipLeft = Math.max(-left, -(overLayX / 2))
          return (
            <div className="skillTooltip box" style={{ width: overLayX, height: overLayY, position: "absolute", top: -(overLayY + 75), left: tooltipLeft }}>
              <div style={{ color: skill.color }}>{skillName}</div>
              {skillKeys.map((textType, i) => (
                <div key={i}>
                  <div style={{ color: "#444466", position: "absolute", top: fontSize * 2 * (i + 2) }}>{textType}</div>
                  <div style={{ color: "#009944", position: "absolute", top: fontSize * 2 * (i + 2), left: overLayX }}>{skill[textType]}</div>
                </div>
              ))}
              {descLines.map((descLine, i) => (
                <div key={i} style={{ color: "#444466", position: "absolute", top: fontSize * 2 * (i / 2 + 2 + skillKeys.length), left: 25 }}>{descLine}</div>
              ))}
            </div>
          )
        })()}
      </div>
    )
  }

const SkillUI: React.FC<{ UIPlayer: UIPlayer; gameState: GameState }> = ({ UIPlayer, gameState }) => {
  const rows = [["1","2","3","4","5","6","7","8","9","0","-","="], ["q","w","e","r","t","y","u","i","o","p","[","]"],
    ["a","s","d","f","g","h","j","k","l",";","'"], ["z","x","c","v","b","n","m",",",".","/"]
  ]
  const rowOffsets = [0, 0.5, 0.8, 1.2]
  return (
    <div>
      {rows.map((row, ri) => (
        <div key={ri} style={{ bottom: (rows.length - ri) * 75, position: "fixed" }}>
          {row.map((boundKey, ki) => {
            const skillName = UIPlayer.keyBindings[boundKey]
            const skill = skillName && skills[skillName]
            if (!skill) return null
            const pctCooldown = gameState.players[UIPlayer.id]?.pctCooldown(skillName) ?? 1
            return <SkillBoxUI key={ki} skill={skill} skillName={skillName} boundKey={boundKey} left={(rowOffsets[ri] + ki) * 75} pctCooldown={pctCooldown} />
          })}
        </div>
      ))}
    </div>
  )
}

const Arena: React.FC<{ gameState: GameState; UIPlayer: UIPlayer | null; tick: number }> = ({ gameState, UIPlayer }) => (
  <div>
    <ScoreBoard teams={gameState.teams} />
    {UIPlayer && <SkillUI UIPlayer={UIPlayer} gameState={gameState} />}
  </div>
)

export function arena(gameState: GameState, canvas: Canvas, camera: Camera, focusedUIPlayer: UIPlayer | null, debug = false) {
  const ctx = canvas.mapContext(camera)
  gameState.map.render(ctx)
  for (const cp of gameState.capturePoints) cp.render(ctx, gameState.teams)
  for (const [z] of gameState.iceZones) z.render(ctx)
  for (const [b] of gameState.barriers) b.render(ctx)
  for (const [m] of gameState.mines) m.render(ctx, gameState.teams)
  for (const [id, player] of Object.entries(gameState.players)) player.render(ctx, gameState, focusedUIPlayer ? id === focusedUIPlayer.id : false)
  for (const p of gameState.projectiles) p.render(ctx)

  // Debug visualization (only when ?debug is in URL)
  if (debug) {
    // Draw pathfinding grid
    const cellSize = gameState.getGridCellSize()
    if (gameState.pathGrid?.cells) {
      for (let gx = 0; gx < gameState.pathGrid.width; gx++) {
        for (let gy = 0; gy < gameState.pathGrid.height; gy++) {
          const walkable = gameState.pathGrid.cells[gx]?.[gy]
          if (!walkable) {
            // Draw blocked cells in red
            ctx.fillStyle("#ff000033")
            ctx.fillRect(
              new Point(gx * cellSize, gy * cellSize),
              new Point(cellSize, cellSize)
            )
          } else {
            // Draw walkable cell borders faintly
            ctx.strokeStyle("#00ff0011")
            ctx.lineWidth(1)
            ctx.strokeRect(
              new Point(gx * cellSize, gy * cellSize),
              new Point(cellSize, cellSize)
            )
          }
        }
      }
    }

    // AI debug visualization
    for (const [id, player] of Object.entries(gameState.players)) {
      const debug = aiDebugState[id]
      if (debug) {
        // Draw full path through all waypoints
        if (debug.fullPath && debug.fullPath.length > 0) {
          ctx.beginPath()
          ctx.moveTo(player.p)
          for (const waypoint of debug.fullPath) {
            ctx.lineTo(waypoint)
            // Draw waypoint dot
            ctx.stroke()
            ctx.filledCircle(waypoint, 4, "#ff6600")
            ctx.beginPath()
            ctx.moveTo(waypoint)
          }
          ctx.strokeStyle("#ff000088")
          ctx.lineWidth(2)
          ctx.stroke()
        }
        // Draw action label
        ctx.fillStyle("#000000")
        ctx.fillText(debug.action, new Point(player.p.x - 20, player.p.y - 30))
      }
    }
  }
}

let root: ReturnType<typeof createRoot> | null = null
let tick = 0
export function ui(gameState: GameState, canvas: Canvas, camera: Camera, focusedUIPlayer: UIPlayer | null) {
  const el = document.getElementById("arena")!
  if (!root) root = createRoot(el)
  tick++
  flushSync(() => {
    root!.render(<Arena gameState={gameState} UIPlayer={focusedUIPlayer} tick={tick} />)
  })
}
