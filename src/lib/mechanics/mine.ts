import Point from "../point"
import Config from "../config"

export class Circle {
  constructor(public center: Point, public radius: number, public team: string) {}

  render(ctx: any, teams: Record<string, { color: string }>, expiry: number, currentTime: number) {
    const timeRemaining = expiry - currentTime
    const pctRemaining = Math.max(0, Math.min(1, timeRemaining / 6000))  // 6000ms total duration

    // Fill with mine color - fade out as it expires
    ctx.beginPath()
    ctx.circle(this.center, this.radius)
    ctx.globalAlpha(0.5 + 0.3 * pctRemaining)
    ctx.fillStyle(Config.colors.mineRed)
    ctx.fill()
    ctx.globalAlpha(1)

    // Team color ring - shrinks as expiry indicator
    const teamColor = teams[this.team]?.color || "#888888"
    const ringRadius = (this.radius - 3) * pctRemaining
    ctx.beginPath()
    ctx.circle(this.center, ringRadius)
    ctx.strokeStyle(teamColor)
    ctx.lineWidth(4)
    ctx.stroke()
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
