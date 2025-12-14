import Point from "../lib/point"

export default class Camera {
  p = new Point(25, 100)
  mapMouseP = new Point(0, 0)
  mouseP = new Point(0, 0)
  mapMiddle = new Point(window.innerWidth / 2, window.innerHeight / 2)
  mapToGo = this.mapMiddle
  cameraSpeed = 0.3

  constructor() {
    addEventListener("mousemove", (event) => {
      this.mouseP = new Point(event.clientX, event.clientY)
      this.mapMouseP = this.mouseP.subtract(this.p)
    })
    addEventListener("mousedown", (event) => {
      if (event.which === 1) {
        const p = new Point(event.clientX, event.clientY)
        this.mapToGo = this.mapMiddle.towards(p, 100)
      }
    })
  }

  update(msDiff: number) {
    this.mapMiddle = new Point(window.innerWidth / 2, window.innerHeight / 2)
    const newCamP = this.mapMiddle.towards(this.mapToGo, this.cameraSpeed * msDiff)
    const moveVector = newCamP.subtract(this.mapMiddle)
    this.mapToGo = this.mapToGo.subtract(moveVector)
    this.p = this.p.subtract(moveVector)
  }
}
