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

  // Check if line segment p1-p2 intersects this rectangle
  lineIntersects(p1: Point, p2: Point): boolean {
    // Use separating axis theorem - check if line segment intersects rectangle
    const dx = p2.x - p1.x
    const dy = p2.y - p1.y

    // Check intersection with each edge
    const edges: [Point, Point][] = [
      [this.topleft, new Point(this.bottomright.x, this.topleft.y)],     // top
      [new Point(this.bottomright.x, this.topleft.y), this.bottomright], // right
      [this.bottomright, new Point(this.topleft.x, this.bottomright.y)], // bottom
      [new Point(this.topleft.x, this.bottomright.y), this.topleft],     // left
    ]

    for (const [e1, e2] of edges) {
      if (this.segmentsIntersect(p1, p2, e1, e2)) return true
    }

    // Also check if line is entirely inside rectangle
    if (p1.inside(this.topleft, this.bottomright) || p2.inside(this.topleft, this.bottomright)) {
      return true
    }

    return false
  }

  private segmentsIntersect(p1: Point, p2: Point, p3: Point, p4: Point): boolean {
    const d1 = this.crossProduct(p3, p4, p1)
    const d2 = this.crossProduct(p3, p4, p2)
    const d3 = this.crossProduct(p1, p2, p3)
    const d4 = this.crossProduct(p1, p2, p4)

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true
    }
    return false
  }

  private crossProduct(a: Point, b: Point, c: Point): number {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
  }

  toObject() { return { type: "Rect", tl: this.topleft.toObject(), br: this.bottomright.toObject(), v: this.velocity.toObject() } }
}

export function fromObject(obj: any) {
  if (obj.type === "Rect") return new Rect(Point.fromObject(obj.tl)!, Point.fromObject(obj.br)!, Point.fromObject(obj.v))
  return null
}
