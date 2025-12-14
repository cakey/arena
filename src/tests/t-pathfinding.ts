import assert from "assert"
import Point from "../lib/point"
import * as Barriers from "../lib/mechanics/barriers"
import { generateGrid, findPath, PathGrid } from "../lib/pathfinding"

// Helper to visualize grid (for debugging)
function visualizeGrid(grid: PathGrid, startX?: number, startY?: number, goalX?: number, goalY?: number): string {
  let result = ""
  for (let y = 0; y < Math.min(grid.height, 50); y++) {
    let row = ""
    for (let x = 0; x < Math.min(grid.width, 80); x++) {
      if (x === startX && y === startY) row += "S"
      else if (x === goalX && y === goalY) row += "G"
      else row += grid.cells[x]?.[y] ? "." : "#"
    }
    result += row + "\n"
  }
  return result
}

describe("Pathfinding", () => {
  const mapSize = new Point(500, 500)

  it("should path around a simple Rect barrier", () => {
    const barrier = new Barriers.Rect(new Point(200, 200), new Point(300, 300))
    const barriers: [Barriers.Rect, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const from = new Point(100, 250)
    const to = new Point(400, 250)
    const { path, error } = findPath(from, to, grid, barriers)

    console.log("Rect barrier path:", path.map(p => `(${p.x.toFixed(0)},${p.y.toFixed(0)})`).join(" -> "))

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length > 1, `Path should have multiple waypoints, got ${path.length}`)

    for (const p of path) {
      assert(!barrier.circleIntersect(p, 20), `Waypoint (${p.x},${p.y}) is inside barrier`)
    }
  })

  it("should path around an LShape barrier", () => {
    const barrier = new Barriers.LShape(new Point(250, 250), 80, 30, "tl")
    const barriers: [Barriers.LShape, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const from = new Point(100, 100)
    const to = new Point(400, 400)
    const { path, error } = findPath(from, to, grid, barriers)

    console.log("LShape barrier path:", path.map(p => `(${p.x.toFixed(0)},${p.y.toFixed(0)})`).join(" -> "))

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length > 1, `Path should have multiple waypoints, got ${path.length}`)

    for (const p of path) {
      assert(!barrier.circleIntersect(p, 20), `Waypoint (${p.x},${p.y}) is inside LShape`)
    }
  })

  it("should path around a PlusShape barrier", () => {
    const barrier = new Barriers.PlusShape(new Point(250, 250), 60, 30)
    const barriers: [Barriers.PlusShape, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const from = new Point(50, 250)
    const to = new Point(450, 250)
    const { path, error } = findPath(from, to, grid, barriers)

    console.log("PlusShape barrier path:", path.map(p => `(${p.x.toFixed(0)},${p.y.toFixed(0)})`).join(" -> "))

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length > 1, `Path should have multiple waypoints, got ${path.length}`)

    for (const p of path) {
      assert(!barrier.circleIntersect(p, 20), `Waypoint (${p.x},${p.y}) is inside PlusShape`)
    }
  })

  it("should path around a TShape barrier", () => {
    const barrier = new Barriers.TShape(new Point(250, 200), 100, 80, 30, "down")
    const barriers: [Barriers.TShape, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const from = new Point(50, 250)
    const to = new Point(450, 250)
    const { path, error } = findPath(from, to, grid, barriers)

    console.log("TShape barrier path:", path.map(p => `(${p.x.toFixed(0)},${p.y.toFixed(0)})`).join(" -> "))

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length > 1, `Path should have multiple waypoints, got ${path.length}`)

    for (const p of path) {
      assert(!barrier.circleIntersect(p, 20), `Waypoint (${p.x},${p.y}) is inside TShape`)
    }
  })

  it("should mark barrier cells as blocked in the grid", () => {
    const barrier = new Barriers.Rect(new Point(200, 200), new Point(300, 300))
    const barriers: [Barriers.Rect, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    // Cell size is 20, barrier center is at 250,250
    const centerCellX = Math.floor(250 / 20)
    const centerCellY = Math.floor(250 / 20)

    assert(!grid.cells[centerCellX][centerCellY],
      `Cell (${centerCellX},${centerCellY}) at center of barrier should be blocked`)
  })

  it("should NOT block cells outside barriers", () => {
    const barrier = new Barriers.Rect(new Point(200, 200), new Point(300, 300))
    const barriers: [Barriers.Rect, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const farCellX = Math.floor(50 / 20)
    const farCellY = Math.floor(50 / 20)

    assert(grid.cells[farCellX][farCellY],
      `Cell (${farCellX},${farCellY}) far from barrier should be walkable`)
  })

  it("should find a path when one exists", () => {
    const barrier = new Barriers.Rect(new Point(240, 240), new Point(260, 260))
    const barriers: [Barriers.Rect, null][] = [[barrier, null]]
    const grid = generateGrid(mapSize, barriers)

    const from = new Point(50, 50)
    const to = new Point(450, 450)
    const { path, error } = findPath(from, to, grid, barriers)

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length >= 1, "Should find a path")
  })

  it("should work with GameState-like barrier configuration", () => {
    const gameMapSize = new Point(1200, 700)
    const barriers: [Barriers.Rect | Barriers.LShape | Barriers.TShape | Barriers.PlusShape, null][] = []

    barriers.push([new Barriers.LShape(new Point(540, 180), 80, 30, "tl"), null])
    barriers.push([new Barriers.LShape(new Point(660, 180), 80, 30, "tr"), null])
    barriers.push([new Barriers.LShape(new Point(540, 520), 80, 30, "bl"), null])
    barriers.push([new Barriers.LShape(new Point(660, 520), 80, 30, "br"), null])

    barriers.push([new Barriers.TShape(new Point(350, 80), 80, 60, 25, "down"), null])
    barriers.push([new Barriers.TShape(new Point(850, 80), 80, 60, 25, "down"), null])
    barriers.push([new Barriers.TShape(new Point(350, 620), 80, 60, 25, "up"), null])
    barriers.push([new Barriers.TShape(new Point(850, 620), 80, 60, 25, "up"), null])

    barriers.push([new Barriers.PlusShape(new Point(440, 310), 40, 25), null])
    barriers.push([new Barriers.PlusShape(new Point(440, 390), 40, 25), null])
    barriers.push([new Barriers.PlusShape(new Point(760, 310), 40, 25), null])
    barriers.push([new Barriers.PlusShape(new Point(760, 390), 40, 25), null])

    barriers.push([new Barriers.Rect(new Point(220, 300), new Point(260, 340)), null])
    barriers.push([new Barriers.Rect(new Point(220, 360), new Point(260, 400)), null])
    barriers.push([new Barriers.Rect(new Point(940, 300), new Point(980, 340)), null])
    barriers.push([new Barriers.Rect(new Point(940, 360), new Point(980, 400)), null])

    const grid = generateGrid(gameMapSize, barriers)

    const from = new Point(100, 100)
    const to = new Point(600, 350)

    const startX = Math.floor(from.x / 20)
    const startY = Math.floor(from.y / 20)
    const goalX = Math.floor(to.x / 20)
    const goalY = Math.floor(to.y / 20)

    console.log("\nGrid visualization (. = walkable, # = blocked, S = start, G = goal):")
    console.log(visualizeGrid(grid, startX, startY, goalX, goalY))
    console.log(`Start cell (${startX}, ${startY}) walkable:`, grid.cells[startX]?.[startY])
    console.log(`Goal cell (${goalX}, ${goalY}) walkable:`, grid.cells[goalX]?.[goalY])

    const { path, error } = findPath(from, to, grid, barriers)
    console.log("Path:", path.map(p => `(${p.x.toFixed(0)},${p.y.toFixed(0)})`).join(" -> "))

    assert(!error, `Should not have error, got ${error}`)
    assert(path.length > 1, `Should find a real path, not direct. Got ${path.length} waypoints`)
  })
})
