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
    const pctRemaining = Math.max(0, Math.min(1, timeRemaining / 8000))

    // Outer warning ring (pulsing)
    const pulse = 0.5 + 0.5 * Math.sin(currentTime / 200)
    ctx.globalAlpha(0.2 + 0.1 * pulse)
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius + 5)
    ctx.lineWidth(3); ctx.strokeStyle("#40a0d0"); ctx.stroke()

    // Ice fill with pattern
    ctx.globalAlpha(0.35 + 0.15 * pctRemaining)
    ctx.filledCircle(this.center, this.currentRadius, "#80d0f0")
    ctx.globalAlpha(1)

    // Inner rings for depth
    ctx.globalAlpha(0.3)
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius * 0.7)
    ctx.lineWidth(2); ctx.strokeStyle("#a0e0ff"); ctx.stroke()
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius * 0.4)
    ctx.lineWidth(2); ctx.strokeStyle("#c0f0ff"); ctx.stroke()
    ctx.globalAlpha(1)

    // Edge ring
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius - 2)
    ctx.lineWidth(4); ctx.strokeStyle("#50b8e0"); ctx.stroke()

    // Sparkles (more of them, rotating)
    ctx.globalAlpha(0.6 * pctRemaining)
    const sparkleOffset = (currentTime / 150) % (Math.PI * 2)
    for (let i = 0; i < 6; i++) {
      const angle = sparkleOffset + (i * Math.PI / 3)
      const sparkleP = this.center.bearing(angle, this.currentRadius * 0.6)
      ctx.filledCircle(sparkleP, 2.5, "#ffffff")
    }
    ctx.globalAlpha(1)
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
