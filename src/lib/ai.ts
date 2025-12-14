import Point from "./point"
import type GameState from "./game-state"
import type { GamePlayer } from "./player"
import type CapturePoint from "./mechanics/capture-point"
import type Projectile from "./projectile"

const AI_CONFIG = {
  aimInaccuracy: 15,
  gunRange: 120,
  bombRange: 250,
  dodgeDistance: 60,
  threatDetectionRadius: 150,
  mineAvoidRadius: 80,
}

export interface AIDecision {
  move?: Point
  skill?: string
  castP?: Point
}

// Debug state - tracks what each AI is thinking
export const aiDebugState: Record<string, { targetPoint?: Point; action: string; fullPath?: Point[] }> = {}

// ============= Geometry Helpers =============

// Distance from point to line segment
function distanceToLineSegment(p: Point, lineStart: Point, lineEnd: Point): number {
  const dx = lineEnd.x - lineStart.x
  const dy = lineEnd.y - lineStart.y
  const lengthSq = dx * dx + dy * dy

  if (lengthSq === 0) return p.distance(lineStart)

  // Project point onto line, clamped to segment
  let t = ((p.x - lineStart.x) * dx + (p.y - lineStart.y) * dy) / lengthSq
  t = Math.max(0, Math.min(1, t))

  const projX = lineStart.x + t * dx
  const projY = lineStart.y + t * dy
  return p.distance(new Point(projX, projY))
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

function isOnCapturePoint(gameState: GameState, self: GamePlayer): CapturePoint | null {
  for (const cp of gameState.capturePoints) {
    if (self.p.distance(cp.p) < cp.radius) return cp
  }
  return null
}

// ============= Threat Detection =============

function getIncomingProjectiles(gameState: GameState, self: GamePlayer): Projectile[] {
  return gameState.projectiles.filter(p => {
    if (p.team === self.team) return false  // Friendly

    // Check if projectile is heading toward us (dot product)
    const toSelf = new Point(self.p.x - p.p.x, self.p.y - p.p.y)
    const toDestP = new Point(p.destP.x - p.p.x, p.destP.y - p.p.y)
    const dot = toSelf.x * toDestP.x + toSelf.y * toDestP.y
    if (dot < 0) return false  // Behind projectile

    // Distance from projectile path
    const closestDist = distanceToLineSegment(self.p, p.p, p.destP)
    return closestDist < self.radius + p.radius + 30  // Threat radius
  })
}

function getMostDangerousProjectile(gameState: GameState, self: GamePlayer): Projectile | null {
  const threats = getIncomingProjectiles(gameState, self)
  if (threats.length === 0) return null

  // Prioritize by danger: bombs are lethal, closer is more urgent
  let mostDangerous: Projectile | null = null
  let highestDanger = -Infinity

  for (const proj of threats) {
    const distance = self.p.distance(proj.p)
    const isBomb = proj.radius > 20  // Bombs have large radius
    let danger = 1000 - distance  // Closer = more dangerous
    if (isBomb) danger += 500  // Bombs are lethal
    if (danger > highestDanger) {
      highestDanger = danger
      mostDangerous = proj
    }
  }

  return mostDangerous
}

function getNearbyEnemyMines(gameState: GameState, self: GamePlayer): { center: Point; radius: number }[] {
  return gameState.mines
    .filter(([mine]) => mine.team !== self.team)
    .map(([mine]) => ({ center: mine.center, radius: mine.radius }))
    .filter(mine => mine.center.distance(self.p) < mine.radius + AI_CONFIG.mineAvoidRadius)
}

function getEnemiesApproaching(gameState: GameState, self: GamePlayer, capturePoint: CapturePoint): GamePlayer[] {
  return getEnemies(gameState, self).filter(enemy => {
    const distToPoint = enemy.p.distance(capturePoint.p)
    return distToPoint < 200  // Enemy is near or approaching the point
  })
}

// ============= Dodge Logic =============

function getDodgeDirection(self: GamePlayer, threat: Projectile, gameState: GameState): Point {
  // Move perpendicular to projectile path
  const projAngle = threat.p.angle(threat.destP)

  // Try both perpendicular directions, pick the one that's safer
  const perpAngle1 = projAngle + Math.PI / 2
  const perpAngle2 = projAngle - Math.PI / 2

  const dodge1 = self.p.bearing(perpAngle1, AI_CONFIG.dodgeDistance)
  const dodge2 = self.p.bearing(perpAngle2, AI_CONFIG.dodgeDistance)

  // Pick the one further from projectile destination
  const dist1 = dodge1.distance(threat.destP)
  const dist2 = dodge2.distance(threat.destP)

  // Also check map bounds
  const inBounds1 = dodge1.x > 20 && dodge1.y > 20 && dodge1.x < gameState.map.size.x - 20 && dodge1.y < gameState.map.size.y - 20
  const inBounds2 = dodge2.x > 20 && dodge2.y > 20 && dodge2.x < gameState.map.size.x - 20 && dodge2.y < gameState.map.size.y - 20

  if (!inBounds1 && inBounds2) return dodge2
  if (!inBounds2 && inBounds1) return dodge1

  return dist1 > dist2 ? dodge1 : dodge2
}

// ============= Line of Sight =============

function hasLineOfSight(gameState: GameState, from: Point, to: Point): boolean {
  for (const [barrier] of gameState.barriers) {
    if (barrier.lineIntersects(from, to)) return false
  }
  return true
}

// ============= Aiming =============

function aimAt(self: GamePlayer, target: GamePlayer): Point {
  const offsetX = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy
  const offsetY = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy
  return new Point(target.p.x + offsetX, target.p.y + offsetY)
}

// Lead target for slow projectiles like bombs
function leadTarget(self: GamePlayer, target: GamePlayer, projectileSpeed: number): Point {
  const distance = self.p.distance(target.p)
  const timeToHit = distance / (projectileSpeed * 10)  // Rough estimate

  // Estimate target movement direction
  const moveDir = new Point(target.destP.x - target.p.x, target.destP.y - target.p.y)
  const moveDist = Math.sqrt(moveDir.x * moveDir.x + moveDir.y * moveDir.y)

  if (moveDist < 1) return aimAt(self, target)  // Target stationary

  // Normalize and scale by predicted travel
  const targetSpeed = 0.06 * 10  // Approximate
  const leadX = target.p.x + (moveDir.x / moveDist) * targetSpeed * timeToHit
  const leadY = target.p.y + (moveDir.y / moveDist) * targetSpeed * timeToHit

  // Add inaccuracy
  const offsetX = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy
  const offsetY = (Math.random() - 0.5) * 2 * AI_CONFIG.aimInaccuracy

  return new Point(leadX + offsetX, leadY + offsetY)
}

// ============= Skill Checks =============

function canUseSkill(self: GamePlayer, skillName: string): boolean {
  return self.pctCooldown(skillName) >= 1 && !self.startCastTime
}

// ============= Main Decision Function =============

export function decideAction(gameState: GameState, self: GamePlayer): AIDecision {
  // Don't act if already casting
  if (self.startCastTime !== null) {
    aiDebugState[self.id] = { action: "casting" }
    return {}
  }

  const nearestEnemy = getNearestEnemy(gameState, self)
  const currentCapturePoint = isOnCapturePoint(gameState, self)

  // ========== Priority 1: DODGE incoming threats ==========
  const dangerousProjectile = getMostDangerousProjectile(gameState, self)
  if (dangerousProjectile) {
    const distToProjectile = self.p.distance(dangerousProjectile.p)

    // Use barrier to block incoming bomb if available
    if (dangerousProjectile.radius > 20 && canUseSkill(self, "barrier") && distToProjectile > 80) {
      const blockP = self.p.towards(dangerousProjectile.p, 40)
      aiDebugState[self.id] = { targetPoint: blockP, action: "barrier-block" }
      return { skill: "barrier", castP: blockP }
    }

    // Otherwise dodge
    const dodgePoint = getDodgeDirection(self, dangerousProjectile, gameState)
    aiDebugState[self.id] = { targetPoint: dodgePoint, action: "dodge" }
    return { move: dodgePoint }
  }

  // Avoid mines
  const nearbyMines = getNearbyEnemyMines(gameState, self)
  if (nearbyMines.length > 0) {
    // Move away from nearest mine
    const nearestMine = nearbyMines.reduce((a, b) =>
      a.center.distance(self.p) < b.center.distance(self.p) ? a : b
    )
    const awayAngle = nearestMine.center.angle(self.p)
    const fleePoint = self.p.bearing(awayAngle, 50)
    aiDebugState[self.id] = { targetPoint: fleePoint, action: "avoid-mine" }
    return { move: fleePoint }
  }

  // ========== Priority 2: SURVIVE - use invulnerable ==========
  if (self.gunHits >= 4 && canUseSkill(self, "invulnerable")) {
    aiDebugState[self.id] = { action: "invuln" }
    return { skill: "invulnerable", castP: self.p }
  }

  // ========== Priority 3: DEFEND capture point ==========
  if (currentCapturePoint) {
    const approachingEnemies = getEnemiesApproaching(gameState, self, currentCapturePoint)

    // Use barrier to block enemies approaching the point
    if (approachingEnemies.length > 0 && canUseSkill(self, "barrier")) {
      const nearestApproaching = approachingEnemies.reduce((a, b) =>
        a.p.distance(self.p) < b.p.distance(self.p) ? a : b
      )
      const blockP = self.p.towards(nearestApproaching.p, 80)
      aiDebugState[self.id] = { targetPoint: blockP, action: "barrier-defend" }
      return { skill: "barrier", castP: blockP }
    }

    // Use ice slick on the capture point to slow enemies
    if (approachingEnemies.length > 0 && canUseSkill(self, "iceslick")) {
      aiDebugState[self.id] = { targetPoint: currentCapturePoint.p, action: "iceslick" }
      return { skill: "iceslick", castP: currentCapturePoint.p }
    }
  }

  // ========== Priority 4: ATTACK nearby enemies ==========
  if (nearestEnemy) {
    // Gun - check line of sight first
    if (nearestEnemy.distance < AI_CONFIG.gunRange && canUseSkill(self, "gun")) {
      if (hasLineOfSight(gameState, self.p, nearestEnemy.player.p)) {
        aiDebugState[self.id] = { targetPoint: nearestEnemy.player.p, action: "gun" }
        return { skill: "gun", castP: aimAt(self, nearestEnemy.player) }
      }
    }

    // Bomb - lead target, check line of sight
    if (nearestEnemy.distance < AI_CONFIG.bombRange && canUseSkill(self, "bomb")) {
      if (hasLineOfSight(gameState, self.p, nearestEnemy.player.p)) {
        const leadP = leadTarget(self, nearestEnemy.player, 0.03)
        aiDebugState[self.id] = { targetPoint: leadP, action: "bomb" }
        return { skill: "bomb", castP: leadP }
      }
    }
  }

  // ========== Priority 5: CONTROL - place mine offensively ==========
  // Place mines toward contested points when safe
  if (canUseSkill(self, "mine")) {
    const noNearbyEnemies = !nearestEnemy || nearestEnemy.distance > 150
    if (noNearbyEnemies) {
      // Find a contested or enemy point to mine
      const contestedPoint = gameState.capturePoints.find(cp =>
        !cp.current.captured || cp.current.team !== self.team
      )
      if (contestedPoint && self.p.distance(contestedPoint.p) < 200) {
        // Place mine toward the contested point
        aiDebugState[self.id] = { action: "mine" }
        return { skill: "mine", castP: self.p }
      }
    }
  }

  // ========== Priority 6: MOVE to capture point ==========
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
