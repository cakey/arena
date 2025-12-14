import Point from "../point"
import type GameState from "../game-state"

export default class CapturePoint {
  maxStrength = 500
  current = { captured: false, team: null as string | null, strength: 0 }
  decaptureProgress = 0  // 0-1, how much has been decaptured (for visual)

  constructor(public p: Point, public radius: number) {}

  render(ctx: any, teams: Record<string, { color: string }>) {
    const baseColor = "#e8e0d8"
    const baseBorder = "#d0c8c0"
    const teamColor = this.current.team && teams[this.current.team] ? teams[this.current.team].color : null
    const size = this.radius * 2
    const corner = this.radius * 0.4
    const topLeft = this.p.subtract(new Point(this.radius, this.radius))

    if (this.current.captured && teamColor) {
      // Fully captured - entire point is team colored with matching border
      ctx.filledRoundRect(topLeft.subtract(new Point(5, 5)), new Point(size + 10, size + 10), corner + 2, teamColor)
      ctx.filledRoundRect(topLeft, new Point(size, size), corner, teamColor)
      // Brighter inner to show it's "active"
      ctx.globalAlpha(0.3)
      ctx.filledRoundRect(topLeft.add(new Point(8, 8)), new Point(size - 16, size - 16), corner * 0.5, "#ffffff")
      ctx.globalAlpha(1)
      // Decapture visual - neutral color expanding from center
      if (this.decaptureProgress > 0) {
        const decapSize = size * this.decaptureProgress
        const decapTopLeft = this.p.subtract(new Point(decapSize / 2, decapSize / 2))
        ctx.filledRoundRect(decapTopLeft, new Point(decapSize, decapSize), corner * this.decaptureProgress, baseColor)
      }
    } else {
      // Not captured - neutral base with progress indicator
      ctx.filledRoundRect(topLeft.subtract(new Point(4, 4)), new Point(size + 8, size + 8), corner, baseBorder)
      ctx.filledRoundRect(topLeft, new Point(size, size), corner, baseColor)
      // Capture progress - fills from center outward
      if (teamColor) {
        const percent = this.current.strength / this.maxStrength
        const progressSize = size * percent
        const progressTopLeft = this.p.subtract(new Point(progressSize / 2, progressSize / 2))
        ctx.filledRoundRect(progressTopLeft, new Point(progressSize, progressSize), corner * percent, teamColor)
        // Decapture visual - neutral color expanding from center over the team color
        if (this.decaptureProgress > 0) {
          const decapSize = progressSize * this.decaptureProgress
          const decapTopLeft = this.p.subtract(new Point(decapSize / 2, decapSize / 2))
          ctx.filledRoundRect(decapTopLeft, new Point(decapSize, decapSize), corner * percent * this.decaptureProgress, baseColor)
        }
      }
    }
    // Highlight
    ctx.globalAlpha(0.2)
    ctx.filledRoundRect(topLeft.add(new Point(6, 6)), new Point(size * 0.4, size * 0.2), corner * 0.3, "#ffffff")
    ctx.globalAlpha(1)
  }

  update(gameState: GameState) {
    let beingDecaptured = false
    const strengthBefore = this.current.strength

    for (const player of Object.values(gameState.players)) {
      if (player.alive && this.p.distance(player.p) < this.radius + player.radius) {
        if (player.team === this.current.team) {
          this.current.strength = Math.min(this.maxStrength, this.current.strength + 1)
          if (this.current.strength === this.maxStrength) this.current.captured = true
        } else {
          this.current.strength = Math.max(0, this.current.strength - 1)
          beingDecaptured = true
          if (this.current.strength === 0) {
            this.current.captured = false
            this.current.team = player.team
            this.decaptureProgress = 0  // Reset on team change
          }
        }
      }
    }

    // Track decapture progress for visual - shows how much has been drained
    if (beingDecaptured && this.current.team) {
      // Progress = inverse of current strength (0 = full, 1 = empty)
      this.decaptureProgress = 1 - (this.current.strength / this.maxStrength)
    } else {
      // Fade out decapture visual when not being decaptured
      this.decaptureProgress = Math.max(0, this.decaptureProgress - 0.02)
    }

    if (this.current.captured && gameState.teams[this.current.team!]) gameState.teams[this.current.team!].score += 1
  }
}
