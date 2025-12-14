import Point from "../point"
import Config from "../config"

export class Rect {
  constructor(public topleft: Point, public bottomright: Point) {}

  render(ctx: any) {
    ctx.beginPath()
    ctx.fillStyle(Config.colors.barrierBrown)
    ctx.fillRect(this.topleft, this.bottomright.subtract(this.topleft))
  }

  circleIntersect(center: Point, radius: number) {
    if (radius >= 20) radius -= 3
    const rad = new Point(radius, radius)
    return center.inside(this.topleft.subtract(rad), this.bottomright.add(rad))
  }

  toObject() { return { type: "Rect", tl: this.topleft.toObject(), br: this.bottomright.toObject() } }
}

export function fromObject(obj: any) {
  if (obj.type === "Rect") return new Rect(Point.fromObject(obj.tl)!, Point.fromObject(obj.br)!)
  return null
}
