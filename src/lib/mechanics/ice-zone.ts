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

    // Icy base - white-blue gradient effect
    ctx.globalAlpha(0.4 + 0.1 * pctRemaining)
    ctx.filledCircle(this.center, this.currentRadius, "#d0f0ff")
    ctx.globalAlpha(0.3)
    ctx.filledCircle(this.center, this.currentRadius * 0.8, "#e8f8ff")
    ctx.globalAlpha(1)

    // Crystalline inner pattern
    ctx.globalAlpha(0.25)
    for (let i = 0; i < 6; i++) {
      const angle = (i * Math.PI / 3)
      const inner = this.center.bearing(angle, this.currentRadius * 0.15)
      const outer = this.center.bearing(angle, this.currentRadius * 0.85)
      ctx.beginPath(); ctx.moveTo(inner); ctx.lineTo(outer)
      ctx.lineWidth(2); ctx.strokeStyle("#90d8ff"); ctx.stroke()
    }
    ctx.globalAlpha(1)

    // Frosty edge
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius - 2)
    ctx.lineWidth(5); ctx.strokeStyle("#a0e8ff"); ctx.stroke()
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius - 1)
    ctx.lineWidth(2); ctx.strokeStyle("#ffffff"); ctx.stroke()

    // Cute snowflake sparkles (rotating slowly)
    ctx.globalAlpha(0.7 * pctRemaining)
    const sparkleOffset = (currentTime / 400) % (Math.PI * 2)
    for (let i = 0; i < 5; i++) {
      const angle = sparkleOffset + (i * Math.PI * 2 / 5)
      const dist = this.currentRadius * (0.35 + (i % 2) * 0.25)
      const sparkleP = this.center.bearing(angle, dist)
      // Draw tiny snowflake
      ctx.filledCircle(sparkleP, 3, "#ffffff")
      for (let j = 0; j < 6; j++) {
        const armAngle = j * Math.PI / 3
        const armEnd = sparkleP.bearing(armAngle, 4)
        ctx.beginPath(); ctx.moveTo(sparkleP); ctx.lineTo(armEnd)
        ctx.lineWidth(1); ctx.strokeStyle("#ffffff"); ctx.stroke()
      }
    }
    ctx.globalAlpha(1)

    // Center sparkle
    const centerPulse = 0.5 + 0.5 * Math.sin(currentTime / 300)
    ctx.globalAlpha(0.4 * centerPulse * pctRemaining)
    ctx.filledCircle(this.center, 8, "#ffffff")
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
