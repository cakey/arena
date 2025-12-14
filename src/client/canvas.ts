import _ from "lodash"
import Point from "../lib/point"

export default class Canvas {
  canvas: HTMLCanvasElement
  ctx: CanvasRenderingContext2D

  constructor(id: string) {
    this.canvas = document.getElementById(id) as HTMLCanvasElement
    this.canvas.width = window.innerWidth
    this.canvas.height = window.innerHeight
    this.ctx = this.canvas.getContext("2d")!
    window.onresize = _.throttle(() => {
      this.canvas.width = window.innerWidth
      this.canvas.height = window.innerHeight
    }, 50)
  }

  mapContext(map: { p: Point }) {
    const o = this.ctx
    const tc = {
      moveTo: (p: Point) => { const mp = p.add(map.p); o.moveTo(mp.x, mp.y) },
      lineTo: (p: Point) => { const mp = p.add(map.p); o.lineTo(mp.x, mp.y) },
      arc: (p: Point, radius: number, startAngle: number, endAngle: number) => {
        const mp = p.add(map.p); o.arc(mp.x, mp.y, radius, startAngle, endAngle)
      },
      strokeRect: (p: Point, size: Point) => { const mp = p.add(map.p); o.strokeRect(mp.x, mp.y, size.x, size.y) },
      fillRect: (p: Point, size: Point) => { const mp = p.add(map.p); o.fillRect(mp.x, mp.y, size.x, size.y) },
      fillText: (arg: string, p: Point) => { const mp = p.add(map.p); o.fillText(arg, mp.x, mp.y) },
      strokeText: (arg: string, p: Point) => { const mp = p.add(map.p); o.strokeText(arg, mp.x, mp.y) },
      circle: (p: Point, radius: number) => tc.arc(p, radius, 0, 2 * Math.PI),
      filledCircle: (p: Point, radius: number, color: string) => {
        tc.beginPath(); tc.circle(p, radius); tc.fillStyle(color); tc.fill()
      },
      beginPath: () => o.beginPath(),
      fillStyle: (arg: string) => { o.fillStyle = arg },
      globalAlpha: (arg: number) => { o.globalAlpha = arg },
      fill: () => o.fill(),
      lineWidth: (arg: number) => { o.lineWidth = arg },
      setLineDash: (arg: number[]) => o.setLineDash(arg),
      stroke: () => o.stroke(),
      font: (arg: string) => { o.font = arg },
      strokeStyle: (arg: string) => { o.strokeStyle = arg }
    }
    return tc
  }

  begin() { this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height) }
  end() {}
  context() { return this.mapContext({ p: new Point(0, 0) }) }
}
