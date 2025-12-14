import _ from "lodash"
import { v4 as uuid } from "uuid"
import Utils from "./utils"
import skills from "./skills"
import Point from "./point"
import Config from "./config"
import type GameState from "./game-state"

class BasePlayer {
  id: string
  constructor(public p: Point, public team: string) { this.id = uuid() }
}

export class GamePlayer {
  time: number; radius = 20; maxCastRadius = 40; destP: Point; speed = 0.06
  startCastTime: number | null = null; castP: Point | null = null; alive = true
  states: Record<string, number> = {}; castedSkill: string = ""
  gunHits = 0
  private _lastCasted: Record<string, number> = {}

  constructor(initTime: number, public p: Point, public team: string, public id: string = uuid()) {
    this.time = initTime; this.destP = p
  }

  kill(spawnLocation: Point) {
    this.alive = false; this.p = this.destP = spawnLocation
    this.castP = null; this.startCastTime = null; this.states = {}; this.gunHits = 0
  }

  applyState(stateName: string, duration: number) { this.states[stateName] = this.time + duration }

  respawn() { this.alive = true; this.applyState("invulnerable", 1500) }

  moveTo(destP: Point) {
    if (this.alive) this.destP = destP
  }

  pctCooldown(castedSkill: string) {
    const realCooldown = Utils.game.speedInverse(skills[castedSkill].cooldown)
    const lastCasted = this._lastCasted[castedSkill]
    if (realCooldown === 0 || !lastCasted) return 1
    if (lastCasted === this.time) return 0
    return Math.min((this.time - lastCasted) / realCooldown, 1)
  }

  fire(castP: Point, castedSkill: string) {
    if (this.alive) {
      this.castP = castP; this.castedSkill = castedSkill
      if (this.pctCooldown(castedSkill) >= 1) this.startCastTime = this.time
    }
  }

  update(newTime: number, gameState: GameState) {
    const msDiff = newTime - this.time
    if (this.alive) {
      const speed = this.states["slow"] ? this.speed * 0.2 : this.speed
      const newP = this.p.towards(this.destP, Utils.game.speed(speed) * msDiff)
      if (gameState.allowedMovement(newP, this)) this.p = newP

      if (this.startCastTime !== null) {
        const skill = skills[this.castedSkill]
        const realCastTime = Utils.game.speedInverse(skill.castTime)
        if (newTime - this.startCastTime > realCastTime) {
          this.startCastTime = null
          const castAngle = this.p.angle(this.castP!)
          if (skill.type === "projectile") {
            const edgeP = this.p.bearing(castAngle, this.maxCastRadius)
            let destP = this.castP!
            if (this.castP!.within(this.p, this.maxCastRadius)) destP = edgeP.bearing(castAngle, 0.1)
            gameState.addProjectile(edgeP, destP, skill, this.team)
          } else if (skill.type === "targeted") {
            gameState.castTargeted(this.p, this.castP!, skill, this.team)
          } else if (skill.type === "ground_targeted") {
            gameState.castGroundTargeted(this.p, this.castP!, skill, this.team)
          }
        }
        this._lastCasted[this.castedSkill] = newTime
      }
      for (const [state, endTime] of Object.entries(this.states)) {
        if (endTime < newTime) delete this.states[state]
      }
    }
    this.time = newTime
  }

  render(ctx: any, gameState: GameState, focused: boolean) {
    if (this.startCastTime !== null && this.alive) {
      const realCastTime = Utils.game.speedInverse(skills[this.castedSkill].castTime)
      const radiusMs = this.radius / realCastTime
      const radius = radiusMs * (this.time - this.startCastTime) + this.radius
      const angle = this.p.angle(this.castP!)
      const halfCone = skills[this.castedSkill].cone / 2
      ctx.beginPath(); ctx.moveTo(this.p); ctx.arc(this.p, radius, angle - halfCone, angle + halfCone)
      ctx.moveTo(this.p); ctx.fillStyle(skills[this.castedSkill].color); ctx.fill()
    }
    if (this.states["invulnerable"]) {
      const timeRemaining = this.states["invulnerable"] - this.time
      const pctRemaining = Math.max(0, Math.min(1, timeRemaining / 3500))
      const shieldRadius = this.radius + 5 + (15 * pctRemaining)
      ctx.beginPath(); ctx.circle(this.p, shieldRadius); ctx.lineWidth(4 + 4 * pctRemaining)
      ctx.strokeStyle(Config.colors.invulnerable); ctx.stroke()
    }
    if (this.states["slow"]) {
      ctx.beginPath(); ctx.circle(this.p, this.radius + 2); ctx.lineWidth(3)
      ctx.setLineDash([4, 2, 6, 2]); ctx.strokeStyle(Config.colors.barrierBrown); ctx.stroke(); ctx.setLineDash([])
    }
    if (this.alive) {
      const teamColor = gameState.teams[this.team]?.color || "#888888"
      ctx.filledCircle(this.p, this.radius, teamColor)
      // Health ring showing gun hits taken
      if (this.gunHits > 0) {
        const healthPct = (6 - this.gunHits) / 6
        const healthRadius = this.radius + 3 + (5 * healthPct)
        ctx.beginPath(); ctx.circle(this.p, healthRadius); ctx.lineWidth(2 + healthPct * 2)
        ctx.strokeStyle(healthPct > 0.5 ? "#44aa44" : healthPct > 0.2 ? "#aaaa44" : "#aa4444"); ctx.stroke()
      }
    } else {
      const deathTime = gameState.deadPlayerIds[this.id]
      const pctRespawn = (this.time - deathTime) / Config.game.respawnTime
      const teamColor = gameState.teams[this.team]?.color || "#888888"
      ctx.filledCircle(this.p, this.radius - 1, Config.colors.barrierBrown)
      ctx.filledCircle(this.p, this.radius * pctRespawn, teamColor)
    }
    if (focused) ctx.filledCircle(this.p, 3, "#000000")
    if (Config.UI.castingCircles) {
      ctx.beginPath(); ctx.circle(this.p, this.maxCastRadius); ctx.lineWidth(1)
      ctx.setLineDash([3, 12]); ctx.strokeStyle("#777777"); ctx.stroke(); ctx.setLineDash([])
    }
  }
}

export class AIPlayer extends BasePlayer {
  handler: any
  constructor(handler: any, startP: Point, team: string) { super(startP, team); this.handler = handler }

  update(newTime: number, gameState: GameState) {
    const self = gameState.players[this.id]
    if (!self) return
    if (self.alive) {
      let otherPs = _.reject(Object.values(gameState.players), { team: this.team })
      otherPs = _.reject(otherPs, { alive: false })
      if (otherPs.length > 0 && Math.random() < Utils.game.speed(0.015) && !self.startCastTime) {
        const skill = _.sample(["bomb", "gun", "invulnerable", "barrier", "mine", "iceslick"])!
        const castP = skills[skill].enemies ? _.sample(otherPs)!.p
          : skills[skill].allies ? self.p : _.sample(otherPs)!.p.towards(self.p, 50)
        this.handler.triggerFire(this, castP, skill)
      }
      const chanceToMove = Math.random() < Utils.game.speed(0.03)
      if (!self.startCastTime && (chanceToMove || self.p.equal(self.destP))) {
        this.handler.triggerMoveTo(this, gameState.map.randomPoint())
      }
    }
  }
}

export class UIPlayer extends BasePlayer {
  keyBindings: Record<string, string> = { q: "gun", w: "bomb", e: "barrier", a: "mine", s: "iceslick", d: "invulnerable" }
  gameState: GameState; handler: any

  constructor(gameState: GameState, handler: any, startP: Point, team: string) {
    super(startP, team); this.gameState = gameState; this.handler = handler
    addEventListener("mousedown", (event) => {
      if (event.which === 1) {
        const radius = this.gameState.players[this.id].radius
        const topLeft = new Point(radius, radius)
        const bottomRight = this.gameState.map.size.subtract(topLeft)
        const p = this.handler.camera.mapMouseP.bound(topLeft, bottomRight)
        this.handler.triggerMoveTo(this, p)
      }
    })
    addEventListener("keypress", (event) => {
      const skill = this.keyBindings[String.fromCharCode(event.which)]
      if (skill) {
        const castP = this.handler.camera.mapMouseP.mapBound(this.p, this.gameState.map)
        this.handler.triggerFire(this, castP, skill)
      }
    })
  }
}
