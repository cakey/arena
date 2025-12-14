import Point from "../point"
import type GameState from "../game-state"

export default class CapturePoint {
  maxStrength = 500
  current = { captured: false, team: null as string | null, strength: 0 }

  constructor(public p: Point, public radius: number) {}

  render(ctx: any, teams: Record<string, { color: string }>) {
    if (this.current.team && teams[this.current.team]) {
      const percent = this.current.strength / this.maxStrength
      ctx.beginPath()
      ctx.moveTo(this.p)
      ctx.arc(this.p, this.radius + 10, -Math.PI / 2, 2 * Math.PI * percent - Math.PI / 2)
      ctx.fillStyle(teams[this.current.team].color)
      ctx.fill()
    }
    const color = this.current.captured && teams[this.current.team!] ? teams[this.current.team!].color : "#ffffff"
    ctx.beginPath()
    ctx.moveTo(this.p)
    ctx.arc(this.p, this.radius + 3, 0, 2 * Math.PI)
    ctx.fillStyle(color)
    ctx.fill()
    ctx.filledCircle(this.p, this.radius, "#bbbbbb")
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
