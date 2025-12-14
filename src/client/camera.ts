import Point from "../lib/point"
import Config from "../lib/config"

export default class Camera {
  p = new Point(0, 0)
  mapMouseP = new Point(0, 0)

  constructor() {
    this.updatePosition()
    addEventListener("resize", () => this.updatePosition())
    addEventListener("mousemove", (event) => {
      this.mapMouseP = new Point(event.clientX, event.clientY).subtract(this.p)
    })
  }

  updatePosition() {
    // Center the board on screen
    this.p = new Point(
      (window.innerWidth - Config.game.width) / 2,
      (window.innerHeight - Config.game.height) / 2
    )
  }

  update(msDiff: number) {}
}
