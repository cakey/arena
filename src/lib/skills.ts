import Point from "./point"
import Config from "./config"
import * as Barriers from "./mechanics/barriers"
import * as Mine from "./mechanics/mine"
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
  orb: {
    cone: Math.PI / 5, radius: 7, castTime: 750, speed: 0.6, range: 400,
    color: "#aa0000", channeled: true, score: 0, description: "Standard range projectile, all rounder.",
    cooldown: 0, enemies: true, type: "projectile"
  },
  gun: {
    cone: Math.PI / 10, radius: 2, castTime: 10, speed: 1, range: 800,
    color: "#000000", channeled: false, score: 0, description: "High rate, low damage, long range machine gun.",
    cooldown: 0, enemies: true, type: "projectile",
    hitPlayer: (p, proj, gs) => gs.killPlayer(p.id)
  },
  bomb: {
    cone: Math.PI / 1.5, radius: 12, castTime: 600, speed: 0.15, range: 300,
    color: "#00bbbb", channeled: false, score: 0, description: "One hit kill.",
    cooldown: 3000, enemies: true, type: "projectile",
    hitPlayer: (p, proj, gs) => gs.killPlayer(p.id)
  },
  flame: {
    cone: Math.PI / 2, radius: 6, castTime: 150, speed: 0.4, range: 250,
    color: "#990099", channeled: false, score: 0, description: "Close range, low damage. Knocks back targets.",
    cooldown: 2000, enemies: true, type: "projectile",
    hitPlayer: (hitPlayer, projectile, gameState) => {
      if (!hitPlayer.states["invulnerable"]) {
        const angle = projectile.p.angle(hitPlayer.p)
        const knockbackP = hitPlayer.p.bearing(angle, 100)
        const radiusP = new Point(hitPlayer.radius, hitPlayer.radius)
        const limitP = gameState.map.size.subtract(radiusP)
        hitPlayer.p = knockbackP.bound(radiusP, limitP)
        hitPlayer.startCastTime = null
        hitPlayer.destP = hitPlayer.p
      }
    }
  },
  interrupt: {
    cone: Math.PI / 8, radius: 4, castTime: 1, speed: 3, range: 1000,
    color: "#aa0077", channeled: false, score: 0, description: "Instant projectile that interrupts targets. No damage.",
    cooldown: 6000, type: "projectile", enemies: true,
    hitPlayer: (p) => { p.startCastTime = null }
  },
  invulnerable: {
    castTime: 50, radius: 5, cone: Math.PI * 2, color: Config.colors.invulnerable, range: 1000,
    channeled: false, score: 0, description: "Makes targeted ally invulnerable.", cooldown: 8000,
    type: "targeted", accuracyRadius: 100, allies: true, enemies: false, speed: 0,
    hitPlayer: (p) => { p.applyState("invulnerable", 2000) }
  },
  barrier: {
    castTime: 150, type: "ground_targeted", radius: 4, color: Config.colors.barrierBrown, range: 1000,
    channeled: false, score: 0, description: "Create a ground barrier", cooldown: 8000, cone: Math.PI, speed: 0,
    onLand: (gameState, castP, originP) => {
      const barrierAngle = castP.angle(originP) + Math.PI / 2
      for (let i = -6; i <= 6; i++) {
        const loc = castP.bearing(barrierAngle, 12 * i)
        const tl = loc.subtract(new Point(4, 4))
        const br = loc.add(new Point(4, 4))
        gameState.createBarrier(new Barriers.Rect(tl, br), 3250 - Math.abs(i) * 80)
      }
    }
  },
  hamstring: {
    castTime: 250, type: "targeted", radius: 12, color: Config.colors.barrierBrown, range: 100,
    channeled: false, score: 0, description: "Melee slow.", cooldown: 10000, cone: Math.PI * 2,
    allies: false, enemies: true, accuracyRadius: 50, speed: 0,
    hitPlayer: (p) => { p.applyState("slow", 5000) }
  },
  mine: {
    castTime: 1000, type: "ground_targeted", radius: 22, color: Config.colors.mineRed,
    channeled: true, score: 15, description: "Mine that one hit kills.", cooldown: 10000, cone: Math.PI * 2, range: 0, speed: 0,
    onLand: (gameState, castP, originP, team) => {
      for (const [x, y] of [[-13, -13], [13, -13], [-13, 13], [13, 13]]) {
        const center = originP.add(new Point(x, y))
        gameState.createMine(new Mine.Circle(center, 15, team), 5000)
      }
    }
  }
}

export default skills
