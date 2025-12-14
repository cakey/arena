import Point from "../point"
import type GameState from "../game-state"

export default class CapturePoint {
  maxStrength = 500
  current = { captured: false, team: null as string | null, strength: 0 }

  constructor(public p: Point, public radius: number) {}

  render(ctx: any, teams: Record<string, { color: string }>) {
    const baseColor = "#e8e0d8"
    const teamColor = this.current.team && teams[this.current.team] ? teams[this.current.team].color : baseColor
    const size = this.radius * 2
    const corner = this.radius * 0.4
    const topLeft = this.p.subtract(new Point(this.radius, this.radius))
    // Soft platform base - rounded square
    ctx.filledRoundRect(topLeft.subtract(new Point(4, 4)), new Point(size + 8, size + 8), corner, "#d0c8c0")
    ctx.filledRoundRect(topLeft, new Point(size, size), corner, baseColor)
    // Capture progress - inner rounded square fills up
    if (this.current.team && teams[this.current.team]) {
      const percent = this.current.strength / this.maxStrength
      const innerSize = (size - 16) * percent
      const innerTopLeft = this.p.subtract(new Point(innerSize / 2, innerSize / 2))
      ctx.filledRoundRect(innerTopLeft, new Point(innerSize, innerSize), corner * 0.5, teamColor)
    }
    // Captured indicator - full inner square
    if (this.current.captured) {
      const innerSize = size - 20
      const innerTopLeft = this.p.subtract(new Point(innerSize / 2, innerSize / 2))
      ctx.filledRoundRect(innerTopLeft, new Point(innerSize, innerSize), corner * 0.4, teamColor)
    }
    // Cute highlight
    ctx.globalAlpha(0.25)
    ctx.filledRoundRect(topLeft.add(new Point(6, 6)), new Point(size * 0.5, size * 0.25), corner * 0.3, "#ffffff")
    ctx.globalAlpha(1)
  }

  update(gameState: GameState) {
    for (const player of Object.values(gameState.players)) {
      if (player.alive && this.p.distance(player.p) < this.radius + player.radius) {
        if (player.team === this.current.team) {
          this.current.strength = Math.min(this.maxStrength, this.current.strength + 1)
          if (this.current.strength === this.maxStrength) this.current.captured = true
        } else {
          this.current.strength = Math.max(0, this.current.strength - 1)
          if (this.current.strength === 0) {
            this.current.captured = false
            this.current.team = player.team
          }
        }
      }
    }
    if (this.current.captured && gameState.teams[this.current.team!]) gameState.teams[this.current.team!].score += 1
  }
}
