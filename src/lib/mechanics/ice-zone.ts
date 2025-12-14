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
    const teamColor = teams[this.team]?.color || "#888888"
    // Soft puddle
    ctx.globalAlpha(0.25 + 0.2 * pctRemaining)
    ctx.filledCircle(this.center, this.currentRadius, "#b8e0f0")
    ctx.globalAlpha(1)
    // Team color soft ring
    ctx.beginPath(); ctx.circle(this.center, this.currentRadius - 3)
    ctx.lineWidth(3); ctx.strokeStyle(teamColor); ctx.stroke()
    // Cute sparkles
    ctx.globalAlpha(0.4 * pctRemaining)
    const sparkleOffset = (currentTime / 200) % (Math.PI * 2)
    for (let i = 0; i < 4; i++) {
      const angle = sparkleOffset + (i * Math.PI / 2)
      const sparkleP = this.center.bearing(angle, this.currentRadius * 0.5)
      ctx.filledCircle(sparkleP, 3, "#ffffff")
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
