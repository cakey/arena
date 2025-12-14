import _ from "lodash"
import Point from "./point"
import Config from "./config"

export default class GameMap {
  size = new Point(Config.game.width, Config.game.height)
  wallSize = new Point(6, 6)

  randomPoint = () => new Point(_.random(0, this.size.x), _.random(0, this.size.y))

  render(ctx: any) {
    const borderColor = Config.colors.border
    // Warm cream background
    ctx.beginPath()
    ctx.fillStyle(Config.colors.background)
    ctx.fillRect(new Point(0, 0), this.size)
    // Simple border
    ctx.beginPath()
    ctx.lineWidth(10)
    ctx.strokeStyle(borderColor)
    ctx.strokeRect(new Point(-3, -3), this.size.add(new Point(6, 6)))
  }
}
