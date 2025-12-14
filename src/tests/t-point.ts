import assert from "assert"
import Point from "../lib/point"

describe("Points", () => {
  const p = new Point(0, 0)

  it("should have x and y initialised correctly", () => {
    assert.strictEqual(p.x, 0)
    assert.strictEqual(p.y, 0)
  })

  it("should have an object constructor", () => {
    const objP = Point.fromObject({ x: 3, y: 7 })!
    assert.strictEqual(objP.x, 3)
    assert.strictEqual(objP.y, 7)
  })

  it("should have an object generator", () => {
    const obj = p.toObject()
    assert.strictEqual(typeof obj, "object")
    assert.strictEqual(obj.x, 0)
    assert.strictEqual(obj.y, 0)
  })

  it("should be able to add", () => {
    const newP = p.add(new Point(4, 5))
    assert.strictEqual(newP.x, 4)
    assert.strictEqual(newP.y, 5)
  })

  it("should be able to subtract", () => {
    const newP = p.subtract(new Point(4, 5))
    assert.strictEqual(newP.x, -4)
    assert.strictEqual(newP.y, -5)
  })

  it("should have equality operators", () => {
    assert.strictEqual(p.equal(new Point(0, 0)), true)
    assert.strictEqual(p.equal(new Point(1, 1)), false)
  })

  it("should have angle functions", () => {
    assert.strictEqual(p.angle(new Point(-1, 0)), Math.PI)
    assert.strictEqual(p.angle(new Point(1, 1)), Math.PI / 4)
    assert.strictEqual(p.angle(new Point(0, 1)), Math.PI / 2)
  })

  it("should have towards functions", () => {
    const newP = p.towards(new Point(3, 4), 2.5)
    assert(newP.x > 1.49999 && newP.x < 1.50001)
    assert(newP.y > 1.99999 && newP.y < 2.00001)
  })

  it("should be able to go on a bearing", () => {
    const newP = p.bearing(0, 10)
    assert.strictEqual(newP.x, 10)
    assert.strictEqual(newP.y, 0)
  })

  it("should have proximity functions", () => {
    const withinP = new Point(1, 1)
    assert.strictEqual(p.within(withinP, 2), true)
    assert.strictEqual(p.within(withinP, 1), false)
  })

  it("should have distance functions", () => {
    assert.strictEqual(p.distance(new Point(3, 4)), 5)
  })

  it("should have inside functions", () => {
    const pt = new Point(2, 7)
    assert.strictEqual(pt.inside(new Point(0, 5), new Point(1, 6)), false)
    assert.strictEqual(pt.inside(new Point(0, 5), new Point(3, 8)), true)
  })
})
