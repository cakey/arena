import Point from "../point"
import Config from "../config"

// Simple rectangle barrier
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
    const size = this.bottomright.subtract(this.topleft)
    const radius = Math.min(size.x, size.y) * 0.3
    ctx.filledRoundRect(this.topleft, size, radius, Config.colors.barrierBrown)
    ctx.globalAlpha(0.25)
    ctx.filledRoundRect(this.topleft.add(new Point(3, 3)), new Point(size.x - 6, size.y * 0.35), radius * 0.5, "#ffffff")
    ctx.globalAlpha(1)
  }

  circleIntersect(center: Point, radius: number): boolean {
    const rad = new Point(radius, radius)
    return center.inside(this.topleft.subtract(rad), this.bottomright.add(rad))
  }

  lineIntersects(p1: Point, p2: Point): boolean {
    // Check if line is entirely inside
    if (p1.inside(this.topleft, this.bottomright) || p2.inside(this.topleft, this.bottomright)) return true
    // Check edges
    const edges: [Point, Point][] = [
      [this.topleft, new Point(this.bottomright.x, this.topleft.y)],
      [new Point(this.bottomright.x, this.topleft.y), this.bottomright],
      [this.bottomright, new Point(this.topleft.x, this.bottomright.y)],
      [new Point(this.topleft.x, this.bottomright.y), this.topleft],
    ]
    for (const [e1, e2] of edges) {
      const d1 = (e2.x - e1.x) * (p1.y - e1.y) - (e2.y - e1.y) * (p1.x - e1.x)
      const d2 = (e2.x - e1.x) * (p2.y - e1.y) - (e2.y - e1.y) * (p2.x - e1.x)
      const d3 = (p2.x - p1.x) * (e1.y - p1.y) - (p2.y - p1.y) * (e1.x - p1.x)
      const d4 = (p2.x - p1.x) * (e2.y - p1.y) - (p2.y - p1.y) * (e2.x - p1.x)
      if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) return true
    }
    return false
  }

  toObject() { return { type: "Rect", tl: this.topleft.toObject(), br: this.bottomright.toObject(), v: this.velocity.toObject() } }
}

// L-shaped barrier (corner: "tl", "tr", "bl", "br")
export class LShape {
  velocity: Point = new Point(0, 0)
  topleft: Point
  bottomright: Point
  private rects: Rect[] = []

  constructor(public center: Point, public armLength: number, public thickness: number, public corner: "tl" | "tr" | "bl" | "br") {
    this.updateBounds()
  }

  private updateBounds() {
    const { center: c, armLength: a, thickness: t, corner } = this
    if (corner === "tl") {
      this.rects = [new Rect(c, c.add(new Point(t, a))), new Rect(c, c.add(new Point(a, t)))]
      this.topleft = c; this.bottomright = c.add(new Point(a, a))
    } else if (corner === "tr") {
      this.rects = [new Rect(c.add(new Point(-t, 0)), c.add(new Point(0, a))), new Rect(c.add(new Point(-a, 0)), c.add(new Point(0, t)))]
      this.topleft = c.add(new Point(-a, 0)); this.bottomright = c.add(new Point(0, a))
    } else if (corner === "bl") {
      this.rects = [new Rect(c.add(new Point(0, -a)), c.add(new Point(t, 0))), new Rect(c.add(new Point(0, -t)), c.add(new Point(a, 0)))]
      this.topleft = c.add(new Point(0, -a)); this.bottomright = c.add(new Point(a, 0))
    } else {
      this.rects = [new Rect(c.add(new Point(-t, -a)), c), new Rect(c.add(new Point(-a, -t)), c)]
      this.topleft = c.add(new Point(-a, -a)); this.bottomright = c
    }
  }

  update(msDiff: number) {
    if (this.velocity.x !== 0 || this.velocity.y !== 0) {
      this.center = this.center.add(new Point(this.velocity.x * msDiff, this.velocity.y * msDiff))
      this.updateBounds()
    }
  }

  render(ctx: any) {
    for (const r of this.rects) r.render(ctx)
  }

  circleIntersect(center: Point, radius: number): boolean {
    return this.rects.some(r => r.circleIntersect(center, radius))
  }

  lineIntersects(p1: Point, p2: Point): boolean {
    return this.rects.some(r => r.lineIntersects(p1, p2))
  }

  toObject() { return { type: "LShape", c: this.center.toObject(), al: this.armLength, th: this.thickness, corner: this.corner, v: this.velocity.toObject() } }
}

// T-shaped barrier (direction: "up", "down", "left", "right")
export class TShape {
  velocity: Point = new Point(0, 0)
  topleft: Point
  bottomright: Point
  private rects: Rect[] = []

  constructor(public center: Point, public width: number, public stemLength: number, public thickness: number, public direction: "up" | "down" | "left" | "right") {
    this.updateBounds()
  }

  private updateBounds() {
    const { center: c, width: w, stemLength: s, thickness: t, direction: d } = this
    const hw = w / 2, ht = t / 2
    if (d === "down") {
      this.rects = [new Rect(c.add(new Point(-hw, 0)), c.add(new Point(hw, t))), new Rect(c.add(new Point(-ht, 0)), c.add(new Point(ht, s)))]
      this.topleft = c.add(new Point(-hw, 0)); this.bottomright = c.add(new Point(hw, s))
    } else if (d === "up") {
      this.rects = [new Rect(c.add(new Point(-hw, -t)), c.add(new Point(hw, 0))), new Rect(c.add(new Point(-ht, -s)), c.add(new Point(ht, 0)))]
      this.topleft = c.add(new Point(-hw, -s)); this.bottomright = c.add(new Point(hw, 0))
    } else if (d === "right") {
      this.rects = [new Rect(c.add(new Point(0, -hw)), c.add(new Point(t, hw))), new Rect(c.add(new Point(0, -ht)), c.add(new Point(s, ht)))]
      this.topleft = c.add(new Point(0, -hw)); this.bottomright = c.add(new Point(s, hw))
    } else {
      this.rects = [new Rect(c.add(new Point(-t, -hw)), c.add(new Point(0, hw))), new Rect(c.add(new Point(-s, -ht)), c.add(new Point(0, ht)))]
      this.topleft = c.add(new Point(-s, -hw)); this.bottomright = c.add(new Point(0, hw))
    }
  }

  update(msDiff: number) {
    if (this.velocity.x !== 0 || this.velocity.y !== 0) {
      this.center = this.center.add(new Point(this.velocity.x * msDiff, this.velocity.y * msDiff))
      this.updateBounds()
    }
  }

  render(ctx: any) {
    for (const r of this.rects) r.render(ctx)
  }

  circleIntersect(center: Point, radius: number): boolean {
    return this.rects.some(r => r.circleIntersect(center, radius))
  }

  lineIntersects(p1: Point, p2: Point): boolean {
    return this.rects.some(r => r.lineIntersects(p1, p2))
  }

  toObject() { return { type: "TShape", c: this.center.toObject(), w: this.width, sl: this.stemLength, th: this.thickness, dir: this.direction, v: this.velocity.toObject() } }
}

// Plus/Cross shaped barrier
export class PlusShape {
  velocity: Point = new Point(0, 0)
  topleft: Point
  bottomright: Point
  private rects: Rect[] = []

  constructor(public center: Point, public armLength: number, public thickness: number) {
    this.updateBounds()
  }

  private updateBounds() {
    const { center: c, armLength: a, thickness: t } = this
    const ht = t / 2
    this.rects = [
      new Rect(c.add(new Point(-a, -ht)), c.add(new Point(a, ht))),
      new Rect(c.add(new Point(-ht, -a)), c.add(new Point(ht, a)))
    ]
    this.topleft = c.add(new Point(-a, -a))
    this.bottomright = c.add(new Point(a, a))
  }

  update(msDiff: number) {
    if (this.velocity.x !== 0 || this.velocity.y !== 0) {
      this.center = this.center.add(new Point(this.velocity.x * msDiff, this.velocity.y * msDiff))
      this.updateBounds()
    }
  }

  render(ctx: any) {
    for (const r of this.rects) r.render(ctx)
  }

  circleIntersect(center: Point, radius: number): boolean {
    return this.rects.some(r => r.circleIntersect(center, radius))
  }

  lineIntersects(p1: Point, p2: Point): boolean {
    return this.rects.some(r => r.lineIntersects(p1, p2))
  }

  toObject() { return { type: "PlusShape", c: this.center.toObject(), al: this.armLength, th: this.thickness, v: this.velocity.toObject() } }
}

export function fromObject(obj: any) {
  if (obj.type === "Rect") return new Rect(Point.fromObject(obj.tl)!, Point.fromObject(obj.br)!, Point.fromObject(obj.v))
  if (obj.type === "LShape") return new LShape(Point.fromObject(obj.c)!, obj.al, obj.th, obj.corner)
  if (obj.type === "TShape") return new TShape(Point.fromObject(obj.c)!, obj.w, obj.sl, obj.th, obj.dir)
  if (obj.type === "PlusShape") return new PlusShape(Point.fromObject(obj.c)!, obj.al, obj.th)
  return null
}
