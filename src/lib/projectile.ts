import Utils from "./utils"
import Point from "./point"
import type { Skill } from "./skills"
import type GameState from "./game-state"

export default class Projectile {
  destP: Point
  radius: number

  constructor(public arena: GameState, public time: number, public p: Point, dirP: Point, public skill: Skill, public team: string) {
    const angle = this.p.angle(dirP)
    this.destP = this.p.bearing(angle, skill.range)
    this.radius = skill.radius
  }

  update(newTime: number) {
    if (this.p.equal(this.destP)) return false
    const msDiff = newTime - this.time
    this.p = this.p.towards(this.destP, Utils.game.speed(this.skill.speed) * msDiff)
    this.time = newTime
    return true
  }

  render(ctx: any) {
    const teamColor = this.arena.teams[this.team]?.color || "#888888"
    // Soft body
    ctx.filledCircle(this.p, this.radius, this.skill.color)
    // Cute highlight
    ctx.globalAlpha(0.5)
    ctx.filledCircle(this.p.add(new Point(-this.radius * 0.25, -this.radius * 0.25)), this.radius * 0.35, "#ffffff")
    ctx.globalAlpha(1)
    // Team color outline
    ctx.beginPath(); ctx.circle(this.p, this.radius)
    ctx.strokeStyle(teamColor); ctx.lineWidth(this.radius > 20 ? 3 : 2); ctx.stroke()
  }
}
