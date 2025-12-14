import Point from "../point"
import Config from "../config"

export class Rect {
  velocity: Point = new Point(0, 0)

  constructor(public topleft: Point, public bottomright: Point, velocity?: Point) {
    if (velocity) this.velocity = velocity
  }

  update(msDiff: number) {
    if (this.velocity.x !== 0 || this.velocity.y !== 0) {
      const delta = new Point(this.velocity.x * msDiff, this.velocity.y * msDiff)
      this.topleft = this.topleft.add(delta)
      this.bottomright = this.bottomright.add(delta)
    }
  }

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

  toObject() { return { type: "Rect", tl: this.topleft.toObject(), br: this.bottomright.toObject(), v: this.velocity.toObject() } }
}

export function fromObject(obj: any) {
  if (obj.type === "Rect") return new Rect(Point.fromObject(obj.tl)!, Point.fromObject(obj.br)!, Point.fromObject(obj.v))
  return null
}
