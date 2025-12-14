import Point from "./point"
import type GameState from "./game-state"
import type { GamePlayer } from "./player"
import type CapturePoint from "./mechanics/capture-point"

const AI_CONFIG = {
  aimInaccuracy: 15,
  gunRange: 120,
  bombRange: 250,
}

export interface AIDecision {
  move?: Point
  skill?: string
  castP?: Point
}

// Debug state - tracks what each AI is thinking
export const aiDebugState: Record<string, { targetPoint?: Point; action: string; fullPath?: Point[] }> = {}

// ============= Awareness Helpers =============

function getEnemies(gameState: GameState, self: GamePlayer): GamePlayer[] {
  return Object.values(gameState.players).filter(
    p => p.team !== self.team && p.alive
  )
}

function getAllies(gameState: GameState, self: GamePlayer): GamePlayer[] {
  return Object.values(gameState.players).filter(
    p => p.team === self.team && p.alive && p.id !== self.id
  )
}

function getNearestEnemy(gameState: GameState, self: GamePlayer): { player: GamePlayer; distance: number } | null {
  const enemies = getEnemies(gameState, self)
  if (enemies.length === 0) return null

  let nearest: GamePlayer | null = null
  let nearestDist = Infinity

  for (const enemy of enemies) {
    const dist = self.p.distance(enemy.p)
    if (dist < nearestDist) {
      nearestDist = dist
      nearest = enemy
    }
  }

  return nearest ? { player: nearest, distance: nearestDist } : null
}

function getBestCapturePoint(gameState: GameState, self: GamePlayer): CapturePoint | null {
  const allies = getAllies(gameState, self)
  let bestPoint: CapturePoint | null = null
  let bestScore = -Infinity

  for (const cp of gameState.capturePoints) {
    const distance = self.p.distance(cp.p)
    const allyOnPoint = allies.some(ally => ally.p.distance(cp.p) < cp.radius)
    const isCapturedByUs = cp.current.captured && cp.current.team === self.team

    let score = -distance
    if (allyOnPoint) score -= 400
    if (isCapturedByUs) score -= 500

    if (score > bestScore) {
      bestScore = score
      bestPoint = cp
    }
  }

  return bestPoint
}

// ============= Aiming =============

function aimAt(self: GamePlayer, target: GamePlayer): Point {
  const offsetX = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy
  const offsetY = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy
  return new Point(target.p.x + offsetX, target.p.y + offsetY)
}

// ============= Skill Checks =============

function canUseSkill(self: GamePlayer, skillName: string): boolean {
  return self.pctCooldown(skillName) >= 1 && !self.startCastTime
}

function isOnCapturePoint(gameState: GameState, self: GamePlayer): boolean {
  for (const cp of gameState.capturePoints) {
    if (self.p.distance(cp.p) < cp.radius) return true
  }
  return false
}

// ============= Main Decision Function =============

export function decideAction(gameState: GameState, self: GamePlayer): AIDecision {
  // Don't act if already casting
  if (self.startCastTime !== null) {
    aiDebugState[self.id] = { action: "casting" }
    return {}
  }

  const nearestEnemy = getNearestEnemy(gameState, self)

  // Priority 1: Survival - use invulnerable if low health
  if (self.gunHits >= 4 && canUseSkill(self, "invulnerable")) {
    aiDebugState[self.id] = { action: "invuln" }
    return { skill: "invulnerable", castP: self.p }
  }

  // Priority 2: Combat - attack nearby enemies
  if (nearestEnemy) {
    if (nearestEnemy.distance < AI_CONFIG.gunRange && canUseSkill(self, "gun")) {
      aiDebugState[self.id] = { targetPoint: nearestEnemy.player.p, action: "gun" }
      return { skill: "gun", castP: aimAt(self, nearestEnemy.player) }
    }
    if (nearestEnemy.distance < AI_CONFIG.bombRange && canUseSkill(self, "bomb")) {
      aiDebugState[self.id] = { targetPoint: nearestEnemy.player.p, action: "bomb" }
      return { skill: "bomb", castP: aimAt(self, nearestEnemy.player) }
    }
  }

  // Priority 3: Move toward best capture point
  const targetPoint = getBestCapturePoint(gameState, self)
  if (targetPoint) {
    const distToPoint = self.p.distance(targetPoint.p)
    if (distToPoint > 30) {
      // Use pathfinding to navigate around barriers
      const path = gameState.findPath(self.p, targetPoint.p)
      const nextWaypoint = path[0] || targetPoint.p
      const pathLen = path.length
      // Store full path for debug visualization
      aiDebugState[self.id] = { targetPoint: nextWaypoint, action: `move(${pathLen})`, fullPath: path }
      return { move: nextWaypoint }
    }
    aiDebugState[self.id] = { action: "on point", fullPath: [] }
  } else {
    aiDebugState[self.id] = { action: "no target", fullPath: [] }
  }

  return {}
}
