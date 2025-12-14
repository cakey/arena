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

  render(ctx: any, teams: Record<string, { color: string }>, expiry: number, currentTime: number) {
    const timeRemaining = expiry - currentTime
    const pctRemaining = Math.max(0, Math.min(1, timeRemaining / 8000))  // 8000ms total duration

    ctx.beginPath()
    ctx.circle(this.center, this.currentRadius)
    ctx.globalAlpha(0.3 + 0.2 * pctRemaining)  // Fade out as it expires
    ctx.fillStyle("#88ccff")
    ctx.fill()
    ctx.globalAlpha(1)

    // Team color ring
    const teamColor = teams[this.team]?.color || "#888888"
    ctx.beginPath()
    ctx.circle(this.center, this.currentRadius - 3)
    ctx.lineWidth(4)
    ctx.strokeStyle(teamColor)
    ctx.stroke()

    // Expiry indicator - shrinking outer ring
    ctx.beginPath()
    ctx.circle(this.center, this.currentRadius * pctRemaining)
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
