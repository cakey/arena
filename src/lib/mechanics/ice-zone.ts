import Point from "../point"

export class IceZone {
  currentRadius: number

  constructor(
    public center: Point,
    public startRadius: number,
    public maxRadius: number,
    public expandRate: number,
    public team: string
  ) {
    this.currentRadius = startRadius
  }

  update(msDiff: number) {
    if (this.currentRadius < this.maxRadius) {
      this.currentRadius = Math.min(this.maxRadius, this.currentRadius + this.expandRate * msDiff)
    }
  }

  render(ctx: any) {
    ctx.beginPath()
    ctx.circle(this.center, this.currentRadius)
    ctx.globalAlpha(0.4)
    ctx.fillStyle("#88ccff")
    ctx.fill()
    ctx.globalAlpha(1)
    ctx.lineWidth(2)
    ctx.strokeStyle("#4488cc")
    ctx.stroke()
  }

  toObject() {
    return {
      type: "IceZone",
      center: this.center.toObject(),
      startRadius: this.startRadius,
      maxRadius: this.maxRadius,
      expandRate: this.expandRate,
      currentRadius: this.currentRadius,
      team: this.team
    }
  }
}

export function fromObject(obj: any) {
  if (obj.type === "IceZone") {
    const zone = new IceZone(
      Point.fromObject(obj.center)!,
      obj.startRadius,
      obj.maxRadius,
      obj.expandRate,
      obj.team
    )
    zone.currentRadius = obj.currentRadius
    return zone
  }
  return null
}
