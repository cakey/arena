import _ from "lodash"
import Point from "./point"
import Projectile from "./projectile"
import CapturePoint from "./mechanics/capture-point"
import * as Barriers from "./mechanics/barriers"
import * as Mine from "./mechanics/mine"
import * as IceZone from "./mechanics/ice-zone"
import { generateGrid, findPath as pathfindingFindPath, PathGrid, getGridCellSize, PathError } from "./pathfinding"
import GameMap from "./map"
import Config from "./config"
import { aiDebugState } from "./ai"
import type { Skill } from "./skills"
import type { GamePlayer } from "./player"

export default class GameState {
  players: Record<string, GamePlayer> = {}
  teams: Record<string, { color: string; score: number }> = {}
  projectiles: Projectile[] = []
  map = new GameMap()
  deadPlayerIds: Record<string, number> = {}
  capturePoints: CapturePoint[] = []
  barriers: [Barriers.Rect | Barriers.LShape | Barriers.TShape | Barriers.PlusShape, number | null][] = []
  mines: [Mine.Circle, number][] = []
  iceZones: [IceZone.IceZone, number][] = []
  pathGrid: PathGrid = { width: 0, height: 0, cells: [] }

  constructor(public time: number) {
    // Capture points - left, center, right
    this.capturePoints.push(new CapturePoint(new Point(150, 350), 70))
    this.capturePoints.push(new CapturePoint(new Point(600, 350), 60))
    this.capturePoints.push(new CapturePoint(new Point(1050, 350), 70))

    // L-shaped walls around center capture point
    this.barriers.push([new Barriers.LShape(new Point(540, 180), 80, 30, "tl"), null])  // top-left L
    this.barriers.push([new Barriers.LShape(new Point(660, 180), 80, 30, "tr"), null])  // top-right L (mirror)
    this.barriers.push([new Barriers.LShape(new Point(540, 520), 80, 30, "bl"), null])  // bottom-left L
    this.barriers.push([new Barriers.LShape(new Point(660, 520), 80, 30, "br"), null])  // bottom-right L (mirror)

    // T-shaped lane dividers
    this.barriers.push([new Barriers.TShape(new Point(350, 80), 80, 60, 25, "down"), null])   // top-left T
    this.barriers.push([new Barriers.TShape(new Point(850, 80), 80, 60, 25, "down"), null])   // top-right T
    this.barriers.push([new Barriers.TShape(new Point(350, 620), 80, 60, 25, "up"), null])    // bottom-left T
    this.barriers.push([new Barriers.TShape(new Point(850, 620), 80, 60, 25, "up"), null])    // bottom-right T

    // Plus shapes as cover near center lanes
    this.barriers.push([new Barriers.PlusShape(new Point(440, 310), 40, 25), null])  // left of center
    this.barriers.push([new Barriers.PlusShape(new Point(440, 390), 40, 25), null])
    this.barriers.push([new Barriers.PlusShape(new Point(760, 310), 40, 25), null])  // right of center
    this.barriers.push([new Barriers.PlusShape(new Point(760, 390), 40, 25), null])

    // Small pillars near side capture points
    this.barriers.push([new Barriers.Rect(new Point(220, 300), new Point(260, 340)), null])
    this.barriers.push([new Barriers.Rect(new Point(220, 360), new Point(260, 400)), null])
    this.barriers.push([new Barriers.Rect(new Point(940, 300), new Point(980, 340)), null])
    this.barriers.push([new Barriers.Rect(new Point(940, 360), new Point(980, 400)), null])

    // Generate pathfinding grid
    this.pathGrid = generateGrid(this.map.size, this.barriers)
  }

  findPath(from: Point, to: Point, team: string = "", selfId: string = ""): { path: Point[], error: PathError } {
    // Extract player positions for collision avoidance
    const alivePlayers = Object.values(this.players)
      .filter(p => p.alive)
      .map(p => ({ p: p.p, radius: p.radius, id: p.id }))
    return pathfindingFindPath(from, to, this.pathGrid, this.barriers, this.mines, team, alivePlayers, selfId)
  }

  getGridCellSize(): number {
    return getGridCellSize()
  }

  addTeam(name: string, color: string) { this.teams[name] = { color, score: 0 } }
  addPlayer(player: GamePlayer) { this.players[player.id] = player }
  removePlayer(playerId: string) { delete this.players[playerId]; delete this.deadPlayerIds[playerId] }
  movePlayer(playerId: string, point: Point) { this.players[playerId].moveTo(point) }
  playerFire(playerId: string, destP: Point, skill: string) { this.players[playerId].fire(destP, skill) }

  killPlayer(playerId: string) {
    const player = this.players[playerId]
    if (!player.states["invulnerable"]) {
      this.deadPlayerIds[playerId] = this.time
      const respawnX = 300 + _.sample(_.range(0, 600, 20))!
      const respawnY = _.sample([-50, 750])!
      player.kill(new Point(respawnX, respawnY))
      return true
    }
    return false
  }

  respawnPlayer(playerId: string) {
    delete this.deadPlayerIds[playerId]
    this.players[playerId].respawn()
  }

  addProjectile(startP: Point, destP: Point, skill: Skill, team: string) {
    this.projectiles.push(new Projectile(this, Date.now(), startP, destP, skill, team))
  }

  createBarrier(barrier: Barriers.Rect, duration: number) { this.barriers.push([barrier, this.time + duration]) }
  createMine(mine: Mine.Circle, duration: number) { this.mines.push([mine, this.time + duration]) }
  createIceZone(zone: IceZone.IceZone, duration: number) { this.iceZones.push([zone, this.time + duration]) }

  castTargeted(originP: Point, castP: Point, skill: Skill, team: string) {
    if (originP.distance(castP) > skill.range) return
    let closestPlayer: GamePlayer | null = null, closestDistance = Infinity
    for (const player of Object.values(this.players)) {
      const sameTeam = player.team === team
      if ((skill.allies && sameTeam) || (skill.enemies && !sameTeam)) {
        const distance = player.p.distance(castP)
        if (distance < closestDistance) { closestDistance = distance; closestPlayer = player }
      }
    }
    if (closestPlayer && closestDistance < closestPlayer.radius + (skill.accuracyRadius || 0)) {
      skill.hitPlayer?.(closestPlayer, null as any, this)
    }
  }

  castGroundTargeted(originP: Point, castP: Point, skill: Skill, team: string) {
    skill.onLand?.(this, castP, originP, team)
  }

  allowedMovement(newP: Point, player: GamePlayer) {
    let currentUnallowed = 0, newUnallowed = 0
    for (const otherPlayer of Object.values(this.players)) {
      if (otherPlayer.id !== player.id && otherPlayer.alive) {
        const currentD = player.p.distance(otherPlayer.p)
        const newD = newP.distance(otherPlayer.p)
        const minimum = player.radius + otherPlayer.radius
        if (currentD < minimum) currentUnallowed += minimum - currentD
        if (newD < minimum) newUnallowed += minimum - newD
      }
    }
    for (const [barrier] of this.barriers) {
      const currentIntersect = barrier.circleIntersect(player.p, player.radius)
      const newIntersect = barrier.circleIntersect(newP, player.radius)
      // Block movement INTO a barrier
      if (!currentIntersect && newIntersect) return false
      if (currentIntersect) currentUnallowed += player.radius
      if (newIntersect) newUnallowed += player.radius
    }
    if (0 < newUnallowed && newUnallowed < 2) return true
    return newUnallowed <= currentUnallowed
  }

  projectileCollide(p: Projectile) {
    for (const player of Object.values(this.players)) {
      if (player.alive && p.team !== player.team && p.p.within(player.p, p.radius + player.radius)) {
        return { player, type: "player" as const }
      }
    }
    for (const [barrier] of this.barriers) {
      if (barrier.circleIntersect(p.p, p.radius)) return { type: "barrier" as const }
    }
    return false
  }

  update(updateTime: number) {
    const msDiff = updateTime - this.time
    this.barriers = this.barriers.filter(([, expiry]) => !expiry || expiry > this.time)
    this.mines = this.mines.filter(([, expiry]) => !expiry || expiry > this.time)
    this.iceZones = this.iceZones.filter(([, expiry]) => expiry > this.time)

    for (const [barrier] of this.barriers) barrier.update(msDiff)
    for (const [zone] of this.iceZones) zone.update(msDiff)

    // Push players out of barriers
    for (const player of Object.values(this.players)) {
      if (!player.alive) continue
      for (const [barrier] of this.barriers) {
        if (barrier.circleIntersect(player.p, player.radius)) {
          // Find barrier center and push player away from it
          const barrierCenter = new Point(
            (barrier.topleft.x + barrier.bottomright.x) / 2,
            (barrier.topleft.y + barrier.bottomright.y) / 2
          )
          const pushAngle = barrierCenter.angle(player.p)
          const pushDist = 5  // Push 5 pixels per tick
          const newP = player.p.bearing(pushAngle, pushDist)
          // Bound to map
          const radiusP = new Point(player.radius, player.radius)
          player.p = newP.bound(radiusP, this.map.size.subtract(radiusP))
          player.destP = player.p  // Stop movement
          // Record hit for AI to escape
          player.lastBarrierHit = {
            time: this.time,
            pushAngle,
            barrierVelocity: barrier.velocity || new Point(0, 0)
          }
        }
      }
    }

    for (const player of Object.values(this.players)) player.update(updateTime, this)

    for (const player of Object.values(this.players)) {
      for (let i = 0; i < this.mines.length; i++) {
        const [mine, d] = this.mines[i]
        if (d > 0 && player.team !== mine.team && mine.center.distance(player.p) < mine.radius + player.radius) {
          if (this.killPlayer(player.id)) {
            this.mines[i][1] = 0
            this.teams[mine.team].score += 1500
          }
        }
      }
      // Ice zone slow buildup - takes 3s to reach full slow
      let inIceZone = false
      for (const [zone] of this.iceZones) {
        if (zone.center.distance(player.p) < zone.currentRadius + player.radius) {
          inIceZone = true
          break
        }
      }
      if (inIceZone) {
        player.iceSlowBuildup = Math.min(1, player.iceSlowBuildup + msDiff / 3000)
      } else {
        player.iceSlowBuildup = Math.max(0, player.iceSlowBuildup - msDiff / 1000)  // Decay faster
      }
    }

    const newProjectiles: Projectile[] = []
    for (const projectile of this.projectiles) {
      const alive = projectile.update(updateTime)
      const withinMap = projectile.p.x > 0 && projectile.p.y > 0 && projectile.p.x < this.map.size.x && projectile.p.y < this.map.size.y
      if (alive && withinMap) {
        const hit = this.projectileCollide(projectile)
        if (hit && hit.type === "player") {
          this.teams[projectile.team].score += projectile.skill.score
          this.teams[hit.player.team].score -= projectile.skill.score
          projectile.skill.hitPlayer?.(hit.player, projectile, this)
          if (projectile.skill.continue) newProjectiles.push(projectile)
        } else if (hit && hit.type === "barrier") {
          // Bomb shrinks on wall hits instead of being destroyed
          if (projectile.skill === require("./skills").default.bomb) {
            projectile.radius -= 8
            if (projectile.radius > 5) newProjectiles.push(projectile)
          }
        } else if (!hit) {
          newProjectiles.push(projectile)
        }
      }
    }
    this.projectiles = newProjectiles

    for (const cp of this.capturePoints) cp.update(this)

    for (const [playerId, deathTime] of Object.entries(this.deadPlayerIds)) {
      if (updateTime - deathTime > Config.game.respawnTime) this.respawnPlayer(playerId)
    }
    this.time = updateTime
  }

  toJSON() {
    return {
      players: _.mapValues(this.players, (p) => ({
        p: p.p?.toObject(), destP: p.destP?.toObject(), team: p.team, alive: p.alive, states: p.states, gunHits: p.gunHits
      })),
      time: this.time,
      teams: _.mapValues(this.teams, (t) => t.score),
      projectiles: this.projectiles.length,
      capturePoints: this.capturePoints.map((cp) => cp.current),
      deadPlayerIds: this.deadPlayerIds,
      barriers: this.barriers.map(([b, d]) => [b.toObject(), d]),
      mines: this.mines.map(([m, d]) => [m.toObject(), d]),
      iceZones: this.iceZones.map(([z, d]) => [z.toObject(), d]),
      aiDebug: _.mapValues(aiDebugState, (d) => ({
        targetPoint: d.targetPoint ? { x: d.targetPoint.x, y: d.targetPoint.y } : null,
        action: d.action,
        fullPath: d.fullPath?.map(p => ({ x: p.x, y: p.y })) || []
      })),
      pathGrid: this.pathGrid
    }
  }

  sync(newState: any) {
    for (const [teamId, newScore] of Object.entries(newState.teams)) {
      if (this.teams[teamId]) this.teams[teamId].score = newScore as number
    }
    for (const [playerId, playerState] of Object.entries(newState.players) as [string, any][]) {
      const player = this.players[playerId]
      if (!player) continue
      player.p = Point.fromObject(playerState.p)!
      player.destP = Point.fromObject(playerState.destP)!
      player.alive = playerState.alive
      player.states = playerState.states
      player.gunHits = playerState.gunHits || 0
    }
    for (let i = 0; i < newState.capturePoints.length; i++) {
      this.capturePoints[i].current = newState.capturePoints[i]
    }
    this.barriers = newState.barriers.map(([obj, d]: [any, number]) => [Barriers.fromObject(obj)!, d])
    this.mines = newState.mines.map(([obj, d]: [any, number]) => [Mine.fromObject(obj)!, d])
    this.iceZones = (newState.iceZones || []).map(([obj, d]: [any, number]) => [IceZone.fromObject(obj)!, d])
    this.deadPlayerIds = newState.deadPlayerIds
    // Sync AI debug state
    if (newState.aiDebug) {
      for (const [id, debug] of Object.entries(newState.aiDebug) as [string, any][]) {
        aiDebugState[id] = {
          targetPoint: debug.targetPoint ? new Point(debug.targetPoint.x, debug.targetPoint.y) : undefined,
          action: debug.action,
          fullPath: debug.fullPath?.map((p: any) => new Point(p.x, p.y)) || []
        }
      }
    }
    // Sync path grid
    if (newState.pathGrid) {
      this.pathGrid = newState.pathGrid
    }
  }
}
