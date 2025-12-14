import _ from "lodash"
import Point from "./point"
import Projectile from "./projectile"
import CapturePoint from "./mechanics/capture-point"
import * as Barriers from "./mechanics/barriers"
import * as Mine from "./mechanics/mine"
import * as IceZone from "./mechanics/ice-zone"
import GameMap from "./map"
import Config from "./config"
import type { Skill } from "./skills"
import type { GamePlayer } from "./player"

export default class GameState {
  players: Record<string, GamePlayer> = {}
  teams: Record<string, { color: string; score: number }> = {}
  projectiles: Projectile[] = []
  map = new GameMap()
  deadPlayerIds: Record<string, number> = {}
  capturePoints: CapturePoint[] = []
  barriers: [Barriers.Rect, number | null][] = []
  mines: [Mine.Circle, number][] = []
  iceZones: [IceZone.IceZone, number][] = []

  constructor(public time: number) {
    // Capture points on far left and right sides
    this.capturePoints.push(new CapturePoint(new Point(150, 350), 70))
    this.capturePoints.push(new CapturePoint(new Point(1050, 350), 70))

    // Central cross structure - creates 4 paths around it
    this.barriers.push([new Barriers.Rect(new Point(550, 300), new Point(650, 400)), null])  // center block
    this.barriers.push([new Barriers.Rect(new Point(580, 200), new Point(620, 300)), null])  // top arm
    this.barriers.push([new Barriers.Rect(new Point(580, 400), new Point(620, 500)), null])  // bottom arm

    // Diagonal cover near center (creates interesting angles)
    this.barriers.push([new Barriers.Rect(new Point(420, 280), new Point(470, 320)), null])
    this.barriers.push([new Barriers.Rect(new Point(420, 380), new Point(470, 420)), null])
    this.barriers.push([new Barriers.Rect(new Point(730, 280), new Point(780, 320)), null])
    this.barriers.push([new Barriers.Rect(new Point(730, 380), new Point(780, 420)), null])

    // Lane dividers (top and bottom corridors)
    this.barriers.push([new Barriers.Rect(new Point(300, 100), new Point(400, 130)), null])
    this.barriers.push([new Barriers.Rect(new Point(800, 100), new Point(900, 130)), null])
    this.barriers.push([new Barriers.Rect(new Point(300, 570), new Point(400, 600)), null])
    this.barriers.push([new Barriers.Rect(new Point(800, 570), new Point(900, 600)), null])

    // Cover pillars near capture points
    this.barriers.push([new Barriers.Rect(new Point(250, 300), new Point(290, 340)), null])
    this.barriers.push([new Barriers.Rect(new Point(250, 360), new Point(290, 400)), null])
    this.barriers.push([new Barriers.Rect(new Point(910, 300), new Point(950, 340)), null])
    this.barriers.push([new Barriers.Rect(new Point(910, 360), new Point(950, 400)), null])
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
      if (barrier.circleIntersect(player.p, player.radius)) currentUnallowed += player.radius
      if (barrier.circleIntersect(newP, player.radius)) newUnallowed += player.radius
    }
    if (0 < newUnallowed && newUnallowed < 2) return true
    return newUnallowed <= currentUnallowed
  }

  projectileCollide(p: Projectile) {
    for (const player of Object.values(this.players)) {
      if (player.alive && p.team !== player.team && p.p.within(player.p, p.skill.radius + player.radius)) {
        return { player, type: "player" as const }
      }
    }
    for (const [barrier] of this.barriers) {
      if (barrier.circleIntersect(p.p, p.skill.radius)) return { type: "barrier" as const }
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
      for (const [zone] of this.iceZones) {
        if (player.team !== zone.team && zone.center.distance(player.p) < zone.currentRadius + player.radius) {
          player.applyState("slow", 500)
        }
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
        p: p.p?.toObject(), destP: p.destP?.toObject(), team: p.team, alive: p.alive, states: p.states
      })),
      time: this.time,
      teams: _.mapValues(this.teams, (t) => t.score),
      projectiles: this.projectiles.length,
      capturePoints: this.capturePoints.map((cp) => cp.current),
      deadPlayerIds: this.deadPlayerIds,
      barriers: this.barriers.map(([b, d]) => [b.toObject(), d]),
      mines: this.mines.map(([m, d]) => [m.toObject(), d]),
      iceZones: this.iceZones.map(([z, d]) => [z.toObject(), d])
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
    }
    for (let i = 0; i < newState.capturePoints.length; i++) {
      this.capturePoints[i].current = newState.capturePoints[i]
    }
    this.barriers = newState.barriers.map(([obj, d]: [any, number]) => [Barriers.fromObject(obj)!, d])
    this.mines = newState.mines.map(([obj, d]: [any, number]) => [Mine.fromObject(obj)!, d])
    this.iceZones = (newState.iceZones || []).map(([obj, d]: [any, number]) => [IceZone.fromObject(obj)!, d])
    this.deadPlayerIds = newState.deadPlayerIds
  }
}
