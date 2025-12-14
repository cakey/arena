import Point from "../point"
import Config from "../config"

export class Circle {
  constructor(public center: Point, public radius: number, public team: string) {}

  render(ctx: any) { ctx.filledCircle(this.center, this.radius, Config.colors.mineRed) }

  circleIntersect(center: Point, radius: number) {
    return this.center.distance(center) < this.radius + radius
  }

  toObject() { return { type: "Circle", center: this.center.toObject(), radius: this.radius, team: this.team } }
}

export function fromObject(obj: any) {
  if (obj.type === "Circle") return new Circle(Point.fromObject(obj.center)!, obj.radius, obj.team)
  return null
}
