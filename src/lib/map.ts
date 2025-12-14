import _ from "lodash"
import Point from "./point"
import Config from "./config"

export default class GameMap {
  size = new Point(Config.game.width, Config.game.height)
  wallSize = new Point(6, 6)

  randomPoint = () => new Point(_.random(0, this.size.x), _.random(0, this.size.y))

  render(ctx: any) {
    const wallP = new Point(-this.wallSize.x / 2, -this.wallSize.y / 2)
    ctx.beginPath()
    ctx.fillStyle("#f3f3f3")
    ctx.fillRect(new Point(0, 0), this.size)
    ctx.beginPath()
    ctx.lineWidth(this.wallSize.x)
    ctx.strokeStyle("#558893")
    ctx.strokeRect(wallP, this.size.add(this.wallSize))
  }
}
