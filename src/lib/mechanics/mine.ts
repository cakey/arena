import Point from "../point"
import Config from "../config"

export class Circle {
  constructor(public center: Point, public radius: number, public team: string) {}

  render(ctx: any, teams: Record<string, { color: string }>, expiry: number, currentTime: number) {
    const timeRemaining = expiry - currentTime
    const pctRemaining = Math.max(0, Math.min(1, timeRemaining / 6000))
    const teamColor = teams[this.team]?.color || "#888888"
    // Soft danger puff
    ctx.globalAlpha(0.3 + 0.3 * pctRemaining)
    ctx.filledCircle(this.center, this.radius, Config.colors.mineRed)
    ctx.globalAlpha(1)
    // Team color ring
    ctx.beginPath(); ctx.circle(this.center, this.radius * pctRemaining)
    ctx.lineWidth(3); ctx.strokeStyle(teamColor); ctx.stroke()
    // Warning pattern - cute dots
    ctx.globalAlpha(0.5 * pctRemaining)
    const dotOffset = (currentTime / 300) % (Math.PI * 2)
    for (let i = 0; i < 6; i++) {
      const angle = dotOffset + (i * Math.PI / 3)
      const dotP = this.center.bearing(angle, this.radius * 0.6)
      ctx.filledCircle(dotP, 4, "#ffffff")
    }
    ctx.globalAlpha(1)
    // Center highlight
    ctx.globalAlpha(0.4)
    ctx.filledCircle(this.center.add(new Point(-8, -8)), 10, "#ffffff")
    ctx.globalAlpha(1)
  }

  circleIntersect(center: Point, radius: number) {
    return this.center.distance(center) < this.radius + radius
  }

  toObject() { return { type: "Circle", center: this.center.toObject(), radius: this.radius, team: this.team } }
}

export function fromObject(obj: any) {
  if (obj.type === "Circle") return new Circle(Point.fromObject(obj.center)!, obj.radius, obj.team)
  return null
}
