import { v4 as uuid } from "uuid"
import Utils from "./utils"
import skills from "./skills"
import Point from "./point"
import Config from "./config"
import { decideAction } from "./ai"
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
  lastBarrierHit: { time: number; pushAngle: number; barrierVelocity: Point } | null = null
  iceSlowBuildup = 0  // 0-1, how much ice slow has built up
  // Jump state
  jumpStartTime: number | null = null
  jumpStartP: Point | null = null
  jumpEndP: Point | null = null
  private _lastCasted: Record<string, number> = {}
  private _shotCounts: Record<string, number> = {}

  constructor(initTime: number, public p: Point, public team: string, public id: string = uuid()) {
    this.time = initTime; this.destP = p
  }

  kill(spawnLocation: Point) {
    this.alive = false; this.p = this.destP = spawnLocation
    this.castP = null; this.startCastTime = null; this.states = {}; this.gunHits = 0
    this.lastBarrierHit = null
    this.iceSlowBuildup = 0
  }

  applyState(stateName: string, duration: number) { this.states[stateName] = this.time + duration }

  respawn() { this.alive = true; this.applyState("invulnerable", 1500) }

  moveTo(destP: Point) {
    if (this.alive && !this.isJumping()) this.destP = destP
  }

  isJumping() { return this.jumpStartTime !== null }

  startJump(targetP: Point, maxRange: number = 150) {
    if (this.isJumping()) return
    const dist = Math.min(this.p.distance(targetP), maxRange)
    const angle = this.p.angle(targetP)
    this.jumpStartTime = this.time
    this.jumpStartP = this.p
    this.jumpEndP = this.p.bearing(angle, dist)
  }

  getJumpProgress(): number {
    if (!this.jumpStartTime) return 0
    const duration = 350  // ms
    return Math.min((this.time - this.jumpStartTime) / duration, 1)
  }

  pctCooldown(castedSkill: string) {
    const skill = skills[castedSkill]
    if (!skill) return 0  // Skill doesn't exist
    const lastCasted = this._lastCasted[castedSkill]

    // Handle burst weapons (like gun) - short cooldown between shots, long cooldown after burst
    if (skill.shotsBeforeCooldown && skill.actualCooldown) {
      const shotCount = this._shotCounts[castedSkill] || 0
      if (shotCount >= skill.shotsBeforeCooldown) {
        // In long cooldown after burst
        const realCooldown = Utils.game.speedInverse(skill.actualCooldown)
        if (!lastCasted) return 1
        const pct = Math.min((this.time - lastCasted) / realCooldown, 1)
        if (pct >= 1) this._shotCounts[castedSkill] = 0  // Reset shot count
        return pct
      }
    }

    const realCooldown = Utils.game.speedInverse(skill.cooldown)
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
      // Handle jump movement
      if (this.isJumping()) {
        const progress = this.getJumpProgress()
        if (progress >= 1) {
          // Land
          this.p = this.jumpEndP!
          this.destP = this.jumpEndP!
          this.jumpStartTime = null
          this.jumpStartP = null
          this.jumpEndP = null
        } else {
          // Interpolate position
          this.p = this.jumpStartP!.towards(this.jumpEndP!, this.jumpStartP!.distance(this.jumpEndP!) * progress)
        }
      } else {
        // Normal movement with ice slow
        const slowMultiplier = 1 - (this.iceSlowBuildup * 0.8)  // 1.0 -> 0.2
        const speed = this.speed * slowMultiplier
        const newP = this.p.towards(this.destP, Utils.game.speed(speed) * msDiff)
        if (gameState.allowedMovement(newP, this)) this.p = newP
      }

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
            // Track shots for burst weapons
            if (skill.shotsBeforeCooldown) {
              this._shotCounts[this.castedSkill] = (this._shotCounts[this.castedSkill] || 0) + 1
            }
          } else if (skill.type === "targeted") {
            gameState.castTargeted(this.p, this.castP!, skill, this.team)
          } else if (skill.type === "ground_targeted") {
            gameState.castGroundTargeted(this.p, this.castP!, skill, this.team, this)
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
    if (this.iceSlowBuildup > 0.05) {
      ctx.globalAlpha(this.iceSlowBuildup * 0.6)
      ctx.beginPath(); ctx.circle(this.p, this.radius + 3); ctx.lineWidth(4)
      ctx.strokeStyle("#60c0e0"); ctx.stroke()
      ctx.globalAlpha(1)
    }
    if (this.alive) {
      const teamColor = gameState.teams[this.team]?.color || "#888888"
      const healthPct = (6 - this.gunHits) / 6
      let displayRadius = this.radius * (0.85 + 0.15 * healthPct)

      // Jump visual - scale up and show shadow
      let jumpScale = 1
      if (this.isJumping()) {
        const progress = this.getJumpProgress()
        // Arc: scale peaks at middle of jump (sin curve)
        jumpScale = 1 + 0.6 * Math.sin(progress * Math.PI)
        displayRadius *= jumpScale

        // Shadow on ground (at interpolated ground position)
        const groundP = this.jumpStartP!.towards(this.jumpEndP!, this.jumpStartP!.distance(this.jumpEndP!) * progress)
        const shadowScale = 1 - 0.3 * Math.sin(progress * Math.PI)  // Shadow shrinks as player rises
        ctx.globalAlpha(0.25)
        ctx.filledCircle(groundP, this.radius * shadowScale * 0.7, "#000000")
        ctx.globalAlpha(1)
      }

      // Body
      ctx.filledCircle(this.p, displayRadius, teamColor)
      // Highlight/shine
      ctx.globalAlpha(0.4)
      ctx.filledCircle(this.p.add(new Point(-5 * jumpScale, -5 * jumpScale)), displayRadius * 0.3, "#ffffff")
      ctx.globalAlpha(1)
      // Face - eyes look toward destination
      const lookAngle = this.p.angle(this.destP)
      const eyeDist = 6 * jumpScale
      const leftEyeBase = this.p.add(new Point(-eyeDist, -2 * jumpScale))
      const rightEyeBase = this.p.add(new Point(eyeDist, -2 * jumpScale))
      const pupilOffset = new Point(Math.cos(lookAngle) * 2 * jumpScale, Math.sin(lookAngle) * 2 * jumpScale)
      // Eye whites
      ctx.filledCircle(leftEyeBase, 5 * jumpScale, "#ffffff")
      ctx.filledCircle(rightEyeBase, 5 * jumpScale, "#ffffff")
      // Pupils - look toward movement (or excited during jump)
      if (this.gunHits >= 4) {
        // Worried X eyes when low health
        ctx.strokeStyle("#444444"); ctx.lineWidth(2)
        ctx.beginPath(); ctx.moveTo(leftEyeBase.add(new Point(-3, -3))); ctx.lineTo(leftEyeBase.add(new Point(3, 3))); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(leftEyeBase.add(new Point(3, -3))); ctx.lineTo(leftEyeBase.add(new Point(-3, 3))); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(rightEyeBase.add(new Point(-3, -3))); ctx.lineTo(rightEyeBase.add(new Point(3, 3))); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(rightEyeBase.add(new Point(3, -3))); ctx.lineTo(rightEyeBase.add(new Point(-3, 3))); ctx.stroke()
      } else if (this.isJumping()) {
        // Excited wide eyes during jump
        ctx.filledCircle(leftEyeBase.add(pupilOffset), 3 * jumpScale, "#444444")
        ctx.filledCircle(rightEyeBase.add(pupilOffset), 3 * jumpScale, "#444444")
      } else {
        ctx.filledCircle(leftEyeBase.add(pupilOffset), 2.5, "#444444")
        ctx.filledCircle(rightEyeBase.add(pupilOffset), 2.5, "#444444")
      }
      // Soft blush marks - subtle and blended
      ctx.globalAlpha(0.15)
      ctx.filledCircle(this.p.add(new Point(-9 * jumpScale, 5 * jumpScale)), 6 * jumpScale, "#e07878")
      ctx.filledCircle(this.p.add(new Point(9 * jumpScale, 5 * jumpScale)), 6 * jumpScale, "#e07878")
      ctx.globalAlpha(1)
    } else {
      const deathTime = gameState.deadPlayerIds[this.id]
      const pctRespawn = (this.time - deathTime) / Config.game.respawnTime
      const teamColor = gameState.teams[this.team]?.color || "#888888"
      // Ghost/respawning - faded with swirl eyes
      ctx.globalAlpha(0.4)
      ctx.filledCircle(this.p, this.radius, teamColor)
      ctx.globalAlpha(1)
      ctx.filledCircle(this.p, this.radius * pctRespawn, teamColor)
    }
    if (focused) ctx.filledCircle(this.p, 4, "#ffffff")
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
    if (!self?.alive) return

    const decision = decideAction(gameState, self)
    // Only send move if destination changed significantly
    if (decision.move && decision.move.distance(self.destP) > 10) {
      this.handler.triggerMoveTo(this, decision.move)
    }
    if (decision.skill && decision.castP) this.handler.triggerFire(this, decision.castP, decision.skill)
  }
}

export class UIPlayer extends BasePlayer {
  keyBindings: Record<string, string> = { q: "gun", w: "bomb", e: "barrier", a: "jump", s: "iceslick", d: "invulnerable" }
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
