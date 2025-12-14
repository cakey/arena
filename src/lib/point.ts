export default class Point {
  constructor(public x: number, public y: number) {}

  static fromObject(obj: { x: number; y: number } | null): Point | null {
    if (!obj) return null
    if (obj.x == null && obj.y == null) throw new Error("Point.fromObject requires x/y keys")
    return new Point(obj.x, obj.y)
  }

  toObject() { return { x: this.x, y: this.y } }

  angle(otherP: Point) { return Math.atan2(otherP.y - this.y, otherP.x - this.x) }

  equal(otherP: Point) { return this.x === otherP.x && this.y === otherP.y }

  towards(destP: Point, maxDistance: number) {
    const diffY = destP.y - this.y, diffX = destP.x - this.x
    const angle = Math.atan2(diffY, diffX)
    const maxYTravel = Math.sin(angle) * maxDistance
    const maxXTravel = Math.cos(angle) * maxDistance
    const x = maxXTravel > Math.abs(diffX) ? destP.x : this.x + maxXTravel
    const y = maxYTravel > Math.abs(diffY) ? destP.y : this.y + maxYTravel
    return new Point(x, y)
  }

  bearing(angle: number, distance: number) {
    return new Point(this.x + Math.cos(angle) * distance, this.y + Math.sin(angle) * distance)
  }

  distance(otherP: Point) {
    return Math.sqrt(Math.pow(this.x - otherP.x, 2) + Math.pow(this.y - otherP.y, 2))
  }

  within(center: Point, radius: number) { return this.distance(center) <= radius }

  bound(topLeft: Point, bottomRight: Point) {
    let x = this.x, y = this.y
    if (x < topLeft.x) x = topLeft.x
    else if (x > bottomRight.x) x = bottomRight.x
    if (y < topLeft.y) y = topLeft.y
    else if (y > bottomRight.y) y = bottomRight.y
    return new Point(x, y)
  }

  inside(topLeft: Point, bottomRight: Point) {
    return this.x >= topLeft.x && this.x <= bottomRight.x && this.y >= topLeft.y && this.y <= bottomRight.y
  }

  angleBound(from: Point, topLeft: Point, bottomRight: Point): Point {
    if (this.x > topLeft.x && this.x < bottomRight.x && this.y > topLeft.y && this.y < bottomRight.y) return this
    const angle = from.angle(this)
    let closest = from
    while (closest.x > topLeft.x && closest.x < bottomRight.x && closest.y > topLeft.y && closest.y < bottomRight.y) {
      closest = closest.bearing(angle, 1)
    }
    return closest
  }

  mapBound(from: Point, map: { size: Point }) {
    return this.angleBound(from, new Point(0, 0), map.size)
  }

  subtract(otherP: Point) { return new Point(this.x - otherP.x, this.y - otherP.y) }
  add(otherP: Point) { return new Point(this.x + otherP.x, this.y + otherP.y) }
}
