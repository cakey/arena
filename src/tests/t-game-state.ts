import assert from "assert"
import GameState from "../lib/game-state"
import { GamePlayer } from "../lib/player"
import Point from "../lib/point"
import * as Barriers from "../lib/mechanics/barriers"

describe("GameState", () => {
  it("should add teams", () => {
    const gs = new GameState(0)
    gs.addTeam("red", "#ff0000")
    gs.addTeam("blue", "#0000ff")
    assert.strictEqual(Object.keys(gs.teams).length, 2)
    assert.strictEqual(gs.teams.red.score, 0)
  })

  it("should add and remove players", () => {
    const gs = new GameState(0)
    gs.addTeam("red", "#ff0000")
    const player = new GamePlayer(0, new Point(100, 100), "red", "player1")
    gs.addPlayer(player)
    assert.strictEqual(Object.keys(gs.players).length, 1)
    gs.removePlayer("player1")
    assert.strictEqual(Object.keys(gs.players).length, 0)
  })

  it("should run update loop without crashing", () => {
    const gs = new GameState(0)
    gs.addTeam("red", "#ff0000")
    gs.addTeam("blue", "#0000ff")
    const p1 = new GamePlayer(0, new Point(100, 100), "red")
    const p2 = new GamePlayer(0, new Point(200, 200), "blue")
    gs.addPlayer(p1)
    gs.addPlayer(p2)
    
    // Run 100 ticks
    for (let i = 1; i <= 100; i++) {
      gs.update(i * 10)
    }
    assert.strictEqual(gs.time, 1000)
  })

  it("should handle player movement", () => {
    const gs = new GameState(0)
    gs.addTeam("red", "#ff0000")
    const player = new GamePlayer(0, new Point(100, 100), "red")
    gs.addPlayer(player)
    gs.movePlayer(player.id, new Point(200, 200))
    assert.strictEqual(player.destP.x, 200)
    assert.strictEqual(player.destP.y, 200)
  })

  it("should find paths that don't go through barriers", () => {
    const gs = new GameState(0)
    // There's a barrier near center - path from left to right should go around it
    const from = new Point(100, 350)  // Left side
    const to = new Point(700, 350)    // Right side (past center barriers)

    const { path, error } = gs.findPath(from, to)

    // Path should exist and have multiple waypoints (not direct)
    assert(!error, `Should not have path error, got ${error}`)
    assert(path.length > 0, "Path should not be empty")

    // Check that no point along the path intersects any barrier
    for (const waypoint of path) {
      for (const [barrier] of gs.barriers) {
        const intersects = barrier.circleIntersect(waypoint, 20) // player radius
        assert(!intersects, `Path waypoint (${waypoint.x}, ${waypoint.y}) intersects barrier`)
      }
    }
  })

  it("should not block cells where players can stand", () => {
    const gs = new GameState(0)
    // Test various positions that should be walkable
    const walkablePositions = [
      new Point(100, 100),   // Top-left area
      new Point(600, 100),   // Top-center
      new Point(1100, 100),  // Top-right
      new Point(100, 600),   // Bottom-left
    ]

    for (const pos of walkablePositions) {
      const { path, error } = gs.findPath(pos, new Point(600, 350))
      assert(!error, `Should not have path error from (${pos.x}, ${pos.y}), got ${error}`)
      assert(path.length > 0, `Should find path from (${pos.x}, ${pos.y})`)
    }
  })

  it("should block movement into barriers", () => {
    const gs = new GameState(0)
    gs.addTeam("red", "#ff0000")
    const player = new GamePlayer(0, new Point(100, 350), "red")
    gs.addPlayer(player)

    // Find a barrier center
    const [barrier] = gs.barriers[0]
    const barrierCenter = new Point(
      (barrier.topleft.x + barrier.bottomright.x) / 2,
      (barrier.topleft.y + barrier.bottomright.y) / 2
    )

    // Verify circleIntersect returns true for barrier center
    assert(barrier.circleIntersect(barrierCenter, player.radius),
      `Barrier center should intersect with player radius`)

    // Movement into barrier should be blocked
    const allowed = gs.allowedMovement(barrierCenter, player)
    assert(!allowed, `Movement into barrier center should be blocked`)
  })

  it("Rect.circleIntersect should work correctly", () => {
    const rect = new Barriers.Rect(new Point(100, 100), new Point(200, 200))

    // Center of rect - should intersect
    assert(rect.circleIntersect(new Point(150, 150), 20), "Center should intersect")

    // Just inside - should intersect
    assert(rect.circleIntersect(new Point(120, 120), 20), "Just inside should intersect")

    // Just outside by radius - should intersect (circle reaches rect)
    assert(rect.circleIntersect(new Point(90, 150), 20), "Edge of circle touching should intersect")

    // Far outside - should NOT intersect
    assert(!rect.circleIntersect(new Point(50, 50), 20), "Far outside should NOT intersect")
  })
})
