import assert from "assert"
import GameState from "../lib/game-state"
import { GamePlayer } from "../lib/player"
import Point from "../lib/point"

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
})
