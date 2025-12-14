import Point from "./point"
import Config from "./config"
import * as Barriers from "./mechanics/barriers"
import * as Mine from "./mechanics/mine"
import { IceZone } from "./mechanics/ice-zone"
import type GameState from "./game-state"
import type { GamePlayer } from "./player"
import type Projectile from "./projectile"

export interface Skill {
  cone: number; radius: number; castTime: number; speed: number; range: number
  color: string; channeled: boolean; score: number; description: string; cooldown: number
  type: "projectile" | "targeted" | "ground_targeted"
  enemies?: boolean; allies?: boolean; accuracyRadius?: number; continue?: boolean
  hitPlayer?: (player: GamePlayer, projectile: Projectile, gameState: GameState) => void
  onLand?: (gameState: GameState, castP: Point, originP: Point, team: string) => void
}

const skills: Record<string, Skill> = {
  gun: {
    cone: Math.PI / 2, radius: 6, castTime: 1, speed: 0.2, range: 120,
    color: "#990099", channeled: false, score: 0, description: "6 hits to kill. Knockback increases per hit.",
    cooldown: 0, enemies: true, type: "projectile",
    hitPlayer: (hitPlayer, projectile, gameState) => {
      if (!hitPlayer.states["invulnerable"]) {
        hitPlayer.gunHits++
        if (hitPlayer.gunHits >= 6) {
          gameState.killPlayer(hitPlayer.id)
        } else {
          const knockback = 40 + hitPlayer.gunHits * 25
          const angle = projectile.p.angle(hitPlayer.p)
          const knockbackP = hitPlayer.p.bearing(angle, knockback)
          const radiusP = new Point(hitPlayer.radius, hitPlayer.radius)
          const limitP = gameState.map.size.subtract(radiusP)
          hitPlayer.p = knockbackP.bound(radiusP, limitP)
          hitPlayer.startCastTime = null
          hitPlayer.destP = hitPlayer.p
        }
      }
    }
  },
  bomb: {
    cone: Math.PI / 1.5, radius: 50, castTime: 1, speed: 0.03, range: 300,
    color: "#00bbbb", channeled: false, score: 0, description: "Slow heavy projectile. Shrinks on wall hits.",
    cooldown: 3000, enemies: true, type: "projectile",
    hitPlayer: (p, proj, gs) => gs.killPlayer(p.id)
  },
  interrupt: {
    cone: Math.PI / 8, radius: 4, castTime: 1, speed: 1.5, range: 1000,
    color: "#aa0077", channeled: false, score: 0, description: "Instant projectile that interrupts targets. No damage.",
    cooldown: 6000, type: "projectile", enemies: true,
    hitPlayer: (p) => { p.startCastTime = null }
  },
  invulnerable: {
    castTime: 50, radius: 5, cone: Math.PI * 2, color: Config.colors.invulnerable, range: 1000,
    channeled: false, score: 0, description: "Makes targeted ally invulnerable.", cooldown: 12000,
    type: "targeted", accuracyRadius: 100, allies: true, enemies: false, speed: 0,
    hitPlayer: (p) => { p.applyState("invulnerable", 3500) }
  },
  barrier: {
    castTime: 1, type: "ground_targeted", radius: 8, color: Config.colors.barrierBrown, range: 1000,
    channeled: false, score: 0, description: "Moving barrier wall", cooldown: 8000, cone: Math.PI, speed: 0,
    onLand: (gameState, castP, originP) => {
      const moveAngle = originP.angle(castP)
      const velocity = new Point(Math.cos(moveAngle) * 0.08, Math.sin(moveAngle) * 0.08)
      const barrierAngle = moveAngle + Math.PI / 2
      for (let i = -5; i <= 5; i++) {
        const loc = originP.bearing(barrierAngle, 18 * i)
        const tl = loc.subtract(new Point(8, 8))
        const br = loc.add(new Point(8, 8))
        gameState.createBarrier(new Barriers.Rect(tl, br, velocity), 4000 - Math.abs(i) * 100)
      }
    }
  },
  iceslick: {
    castTime: 1, type: "ground_targeted", radius: 8, color: "#88ccff", range: 1000,
    channeled: false, score: 0, description: "Ice zone that slows enemies.", cooldown: 15000, cone: Math.PI * 2, speed: 0,
    onLand: (gameState, castP, originP, team) => {
      gameState.createIceZone(new IceZone(castP, 10, 80, 0.015, team), 8000)
    }
  },
  mine: {
    castTime: 1000, type: "ground_targeted", radius: 66, color: Config.colors.mineRed,
    channeled: true, score: 15, description: "Mine that one hit kills.", cooldown: 10000, cone: Math.PI * 2, range: 0, speed: 0,
    onLand: (gameState, castP, originP, team) => {
      for (const [x, y] of [[-40, -40], [40, -40], [-40, 40], [40, 40]]) {
        const center = originP.add(new Point(x, y))
        gameState.createMine(new Mine.Circle(center, 44, team), 5000)
      }
    }
  }
}

export default skills
