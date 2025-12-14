import _ from "lodash"
import Point from "./point"
import Config from "./config"

export default class GameMap {
  size = new Point(Config.game.width, Config.game.height)
  wallSize = new Point(6, 6)

  randomPoint = () => new Point(_.random(0, this.size.x), _.random(0, this.size.y))

  render(ctx: any) {
    const wallP = new Point(-this.wallSize.x / 2, -this.wallSize.y / 2)
    // Warm cream background
    ctx.beginPath()
    ctx.fillStyle(Config.colors.background)
    ctx.fillRect(new Point(0, 0), this.size)
    // Decorative border with rounded bumps
    const borderColor = Config.colors.border
    ctx.beginPath()
    ctx.lineWidth(12)
    ctx.strokeStyle(borderColor)
    ctx.strokeRect(wallP, this.size.add(this.wallSize))
    // Corner pillows
    const cornerSize = 25
    const corners = [
      new Point(0, 0),
      new Point(this.size.x, 0),
      new Point(0, this.size.y),
      new Point(this.size.x, this.size.y)
    ]
    for (const corner of corners) {
      ctx.filledCircle(corner, cornerSize, borderColor)
      ctx.globalAlpha(0.3)
      ctx.filledCircle(corner.add(new Point(-5, -5)), cornerSize * 0.4, "#ffffff")
      ctx.globalAlpha(1)
    }
    // Mid-edge bumps for visual interest
    const midBumps = [
      new Point(this.size.x / 2, -4),
      new Point(this.size.x / 2, this.size.y + 4),
      new Point(-4, this.size.y / 2),
      new Point(this.size.x + 4, this.size.y / 2)
    ]
    for (const bump of midBumps) {
      ctx.filledCircle(bump, 15, borderColor)
      ctx.globalAlpha(0.25)
      ctx.filledCircle(bump.add(new Point(-3, -3)), 6, "#ffffff")
      ctx.globalAlpha(1)
    }
  }
}
