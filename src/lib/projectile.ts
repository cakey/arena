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
    const isBomb = this.radius > 20

    if (isBomb) {
      // Bomb body - dark blue-gray bomb
      ctx.filledCircle(this.p, this.radius, "#4a5568")
      ctx.filledCircle(this.p, this.radius * 0.9, "#5a6578")

      // Highlight
      ctx.globalAlpha(0.4)
      ctx.filledCircle(this.p.add(new Point(-this.radius * 0.3, -this.radius * 0.3)), this.radius * 0.4, "#8899aa")
      ctx.globalAlpha(1)

      // Fuse on top
      const fuseBase = this.p.add(new Point(0, -this.radius * 0.8))
      const fuseTop = this.p.add(new Point(this.radius * 0.2, -this.radius * 1.2))
      ctx.beginPath(); ctx.moveTo(fuseBase); ctx.lineTo(fuseTop)
      ctx.lineWidth(4); ctx.strokeStyle("#8B4513"); ctx.stroke()

      // Sparking fuse tip
      const sparkle = 0.5 + 0.5 * Math.sin(this.time / 50)
      ctx.globalAlpha(0.6 + 0.4 * sparkle)
      ctx.filledCircle(fuseTop, 5 + sparkle * 3, "#ff6600")
      ctx.filledCircle(fuseTop, 3, "#ffff00")
      ctx.globalAlpha(1)

      // Worried X eyes (team colored)
      const eyeY = this.p.y - this.radius * 0.05
      const eyeSpacing = this.radius * 0.32
      ctx.lineWidth(3); ctx.strokeStyle(teamColor)
      // Left X
      ctx.beginPath()
      ctx.moveTo(new Point(this.p.x - eyeSpacing - 4, eyeY - 4))
      ctx.lineTo(new Point(this.p.x - eyeSpacing + 4, eyeY + 4)); ctx.stroke()
      ctx.beginPath()
      ctx.moveTo(new Point(this.p.x - eyeSpacing + 4, eyeY - 4))
      ctx.lineTo(new Point(this.p.x - eyeSpacing - 4, eyeY + 4)); ctx.stroke()
      // Right X
      ctx.beginPath()
      ctx.moveTo(new Point(this.p.x + eyeSpacing - 4, eyeY - 4))
      ctx.lineTo(new Point(this.p.x + eyeSpacing + 4, eyeY + 4)); ctx.stroke()
      ctx.beginPath()
      ctx.moveTo(new Point(this.p.x + eyeSpacing + 4, eyeY - 4))
      ctx.lineTo(new Point(this.p.x + eyeSpacing - 4, eyeY + 4)); ctx.stroke()
      // Wobbly worried mouth (team colored)
      ctx.beginPath()
      ctx.arc(new Point(this.p.x, this.p.y + this.radius * 0.4), this.radius * 0.2, Math.PI * 0.15, Math.PI * 0.85)
      ctx.lineWidth(3); ctx.strokeStyle(teamColor); ctx.stroke()
    } else {
      // Regular projectile
      ctx.filledCircle(this.p, this.radius, this.skill.color)
      // Cute highlight
      ctx.globalAlpha(0.5)
      ctx.filledCircle(this.p.add(new Point(-this.radius * 0.25, -this.radius * 0.25)), this.radius * 0.35, "#ffffff")
      ctx.globalAlpha(1)
      // Team color outline
      ctx.beginPath(); ctx.circle(this.p, this.radius)
      ctx.strokeStyle(teamColor); ctx.lineWidth(2); ctx.stroke()
    }
  }
}
