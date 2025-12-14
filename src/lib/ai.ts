import Point from "./point"
import type GameState from "./game-state"
import type { GamePlayer } from "./player"
import type CapturePoint from "./mechanics/capture-point"

// Tunable difficulty constants
const AI_CONFIG = {
  aimInaccuracy: 15,        // Random offset in pixels
  gunRange: 120,
  bombRange: 250,
  threatDetectionRange: 150,
}

export interface AIDecision {
  move?: Point
  skill?: string
  castP?: Point
}

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
    // Check if ally is already on this point
    const allyOnPoint = allies.some(ally => ally.p.distance(cp.p) < cp.radius)

    // Score: prefer closer points, prefer points without allies
    const distance = self.p.distance(cp.p)
    const allyPenalty = allyOnPoint ? 500 : 0
    const score = -distance - allyPenalty

    if (score > bestScore) {
      bestScore = score
      bestPoint = cp
    }
  }

  return bestPoint
}

function getIncomingThreat(gameState: GameState, self: GamePlayer): { p: Point; velocity: Point } | null {
  // Check for incoming projectiles
  for (const proj of gameState.projectiles) {
    if (proj.team === self.team) continue

    const dist = self.p.distance(proj.p)
    if (dist > AI_CONFIG.threatDetectionRange) continue

    // Check if projectile is heading toward us
    const projAngle = proj.p.angle(proj.destP)
    const toSelfAngle = proj.p.angle(self.p)
    const angleDiff = Math.abs(projAngle - toSelfAngle)

    if (angleDiff < Math.PI / 4) {
      const velocity = new Point(
        Math.cos(projAngle) * proj.skill.speed,
        Math.sin(projAngle) * proj.skill.speed
      )
      return { p: proj.p, velocity }
    }
  }

  // Check for nearby mines
  for (const [mine] of gameState.mines) {
    if (mine.team === self.team) continue
    const dist = self.p.distance(mine.center)
    if (dist < mine.radius + 30) {
      return { p: mine.center, velocity: new Point(0, 0) }
    }
  }

  return null
}

// ============= Aiming =============

function aimAt(self: GamePlayer, target: GamePlayer, projectileSpeed: number): Point {
  // Simple prediction: where will target be when projectile arrives?
  const distance = self.p.distance(target.p)
  const timeToHit = distance / (projectileSpeed * 60) // Convert to approximate ms

  // Predict target movement
  const targetVelocity = target.destP.subtract(target.p)
  const targetSpeed = target.states["slow"] ? target.speed * 0.2 : target.speed
  const maxMove = targetSpeed * timeToHit

  let predictedP = target.p
  if (targetVelocity.x !== 0 || targetVelocity.y !== 0) {
    const moveDir = Math.atan2(targetVelocity.y, targetVelocity.x)
    predictedP = target.p.bearing(moveDir, Math.min(maxMove, target.p.distance(target.destP)))
  }

  return addInaccuracy(predictedP, AI_CONFIG.aimInaccuracy)
}

function addInaccuracy(p: Point, amount: number): Point {
  const offsetX = (Math.random() - 0.5) * 2 * amount
  const offsetY = (Math.random() - 0.5) * 2 * amount
  return new Point(p.x + offsetX, p.y + offsetY)
}

function dodgeDirection(self: GamePlayer, threat: { p: Point; velocity: Point }): Point {
  // Move perpendicular to threat direction
  const threatAngle = threat.p.angle(self.p)
  const perpAngle = threatAngle + Math.PI / 2 * (Math.random() > 0.5 ? 1 : -1)
  return self.p.bearing(perpAngle, 60)
}

// ============= Skill Checks =============

function canUseSkill(self: GamePlayer, skillName: string): boolean {
  return self.pctCooldown(skillName) >= 1 && !self.startCastTime
}

function isOnCapturePoint(gameState: GameState, self: GamePlayer): CapturePoint | null {
  for (const cp of gameState.capturePoints) {
    if (self.p.distance(cp.p) < cp.radius) return cp
  }
  return null
}

// ============= Main Decision Function =============

export function decideAction(gameState: GameState, self: GamePlayer): AIDecision {
  // Don't act if already casting
  if (self.startCastTime !== null) return {}

  const nearestEnemy = getNearestEnemy(gameState, self)

  // Priority 1: Survival - use invulnerable if low health
  if (self.gunHits >= 4 && canUseSkill(self, "invulnerable")) {
    return { skill: "invulnerable", castP: self.p }
  }

  // Priority 2: Threat avoidance - dodge incoming projectiles/mines
  const threat = getIncomingThreat(gameState, self)
  if (threat) {
    return { move: dodgeDirection(self, threat) }
  }

  // Priority 3: Combat - attack nearby enemies
  if (nearestEnemy) {
    // Gun range - fast projectile, direct aim
    if (nearestEnemy.distance < AI_CONFIG.gunRange && canUseSkill(self, "gun")) {
      return { skill: "gun", castP: aimAt(self, nearestEnemy.player, 0.2) }
    }

    // Bomb range - slow projectile, needs prediction
    if (nearestEnemy.distance < AI_CONFIG.bombRange && canUseSkill(self, "bomb")) {
      return { skill: "bomb", castP: aimAt(self, nearestEnemy.player, 0.03) }
    }
  }

  // Priority 4: Defense - if on capture point with approaching enemy, use defensive skills
  const onPoint = isOnCapturePoint(gameState, self)
  if (onPoint && nearestEnemy && nearestEnemy.distance < 200) {
    // Ice slick to slow approaching enemies
    if (canUseSkill(self, "iceslick")) {
      return { skill: "iceslick", castP: nearestEnemy.player.p }
    }
    // Barrier to block approach
    if (canUseSkill(self, "barrier")) {
      return { skill: "barrier", castP: nearestEnemy.player.p }
    }
  }

  // Priority 5: Objective - move toward best capture point
  const targetPoint = getBestCapturePoint(gameState, self)
  if (targetPoint) {
    const distToPoint = self.p.distance(targetPoint.p)
    // Only move if not already on the point
    if (distToPoint > targetPoint.radius * 0.5) {
      return { move: targetPoint.p }
    }
  }

  // Default: if on point and no threats, maybe place mine
  if (onPoint && canUseSkill(self, "mine") && Math.random() < 0.01) {
    return { skill: "mine", castP: self.p }
  }

  return {}
}
