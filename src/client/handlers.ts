import Config from "../lib/config"
import { v4 as uuid } from "uuid"
import Point from "../lib/point"
import { GamePlayer, UIPlayer, AIPlayer } from "../lib/player"
import * as Renderers from "./renderers"
import type GameState from "../lib/game-state"
import type Canvas from "./canvas"
import type Camera from "./camera"

class PerfBuffer {
  i = 0; _arr: number[] = []
  constructor(public n: number) {}
  add(v: number) { if (this.i < this.n) this._arr[this.i++] = v; else { this.i = 0; this._arr[this.i] = v } }
  average() { return this._arr.length ? this._arr.reduce((a, b) => a + b, 0) / this._arr.length : 0 }
}

export class Client {
  host: string; ws: WebSocket; client_uuid: string; locallyProcessed: AIPlayer[] = []
  focusedUIPlayer: UIPlayer | null = null; time = 0; tickNo = 0
  debug = false
  private _ready: Promise<void>
  // Performance tracking
  updatePerfBuffer = new PerfBuffer(100)
  renderPerfBuffer = new PerfBuffer(100)
  totalPerfBuffer = new PerfBuffer(100)
  serverPerf: { total: string; ai: string; update: string } | null = null

  constructor(public gameState: GameState, public canvas: Canvas, public camera: Camera) {
    this.host = `ws://${location.hostname}:${Config.ws.port}`
    this.ws = new WebSocket(this.host)
    this.client_uuid = uuid()

    this._ready = new Promise((resolve) => {
      this.ws.onopen = () => {
        this.ws.send(JSON.stringify({ action: "register", id: this.client_uuid }))
        resolve()
      }
    })

    window.onbeforeunload = () => {
      this.ws.send(JSON.stringify({ action: "deregister", id: this.client_uuid }))
    }

    this.ws.onmessage = (unparsed) => {
      const message = JSON.parse(unparsed.data)
      const d = message.data
      switch (message.action) {
        case "control": {
          const position = Point.fromObject(d.actionPosition)!
          const player = this.gameState.players[d.playerId]
          if (!player) return
          if (d.action === "moveTo") this.gameState.movePlayer(d.playerId, position)
          else if (d.action === "fire") this.gameState.playerFire(d.playerId, position, d.skill)
          break
        }
        case "newPlayer": {
          const pos = Point.fromObject(d.playerPosition) || this.gameState.map.randomPoint()
          const player = new GamePlayer(this.gameState.time, pos, d.team, d.playerId)
          this.gameState.addPlayer(player)
          break
        }
        case "deletePlayer": this.gameState.removePlayer(d); break
        case "ping": this.ws.send(JSON.stringify(message)); break
        case "sync":
          this.gameState.sync(d)
          if (message.perf) this.serverPerf = message.perf
          break
      }
    }

    this.ws.onclose = () => { document.location.reload() }
  }

  ready() { return this._ready }

  registerLocal(player: UIPlayer | AIPlayer, ai = false) {
    this.ws.send(JSON.stringify({
      action: "newPlayer",
      data: { playerId: player.id, playerPosition: player.p.toObject(), team: player.team },
      id: this.client_uuid
    }))
    if (ai) this.locallyProcessed.push(player as AIPlayer)
  }

  triggerMoveTo(player: { id: string; team: string }, destP: Point) {
    this.ws.send(JSON.stringify({
      action: "control",
      data: { playerId: player.id, action: "moveTo", actionPosition: destP.toObject(), team: player.team },
      id: this.client_uuid
    }))
  }

  triggerFire(player: { id: string; team: string }, castP: Point, skillName: string) {
    this.ws.send(JSON.stringify({
      action: "control",
      data: { playerId: player.id, action: "fire", actionPosition: castP.toObject(), skill: skillName, team: player.team },
      id: this.client_uuid
    }))
  }

  startLoop() {
    this.time = Date.now()
    this.tickNo = 0
    this.loopTick()
  }

  loopTick = () => {
    this.tickNo++
    setTimeout(this.loopTick, Config.game.tickTime)
    const loopStart = performance.now()
    const newTime = Date.now()

    const updateStart = performance.now()
    for (const player of this.locallyProcessed) player.update(newTime, this.gameState)
    this.camera.update(newTime - this.time)
    this.gameState.update(newTime)
    this.updatePerfBuffer.add(performance.now() - updateStart)

    const renderStart = performance.now()
    this.canvas.begin()
    Renderers.arena(this.gameState, this.canvas, this.camera, this.focusedUIPlayer, this.debug)
    if (this.tickNo % 5 === 0) Renderers.ui(this.gameState, this.canvas, this.camera, this.focusedUIPlayer)
    if (this.debug) this.renderPerfOverlay()
    this.canvas.end()
    this.renderPerfBuffer.add(performance.now() - renderStart)

    this.totalPerfBuffer.add(performance.now() - loopStart)
    this.time = newTime
  }

  renderPerfOverlay() {
    const ctx = this.canvas.ctx
    const px = 20, py = 20  // panel position
    const budget = Config.game.tickTime
    const barWidth = 120, barHeight = 8, rowHeight = 26
    const padding = 16

    const clientTotal = this.totalPerfBuffer.average()
    const clientUpdate = this.updatePerfBuffer.average()
    const clientRender = this.renderPerfBuffer.average()

    // Background panel
    const panelWidth = 200
    const panelHeight = this.serverPerf ? 250 : 130
    ctx.fillStyle = "rgba(20, 20, 30, 0.9)"
    ctx.beginPath()
    ctx.roundRect(px, py, panelWidth, panelHeight, 8)
    ctx.fill()

    const x = px + padding
    let y = py + padding + 4

    // Header with budget
    ctx.font = "bold 11px system-ui, sans-serif"
    ctx.fillStyle = "#667788"
    ctx.fillText(`PERFORMANCE (${budget}ms budget)`, x, y)
    y += 20

    // Client section
    ctx.fillStyle = "#99bbdd"
    ctx.fillText("CLIENT", x, y)
    y += 12
    this.drawPerfBar(ctx, x, y, barWidth, barHeight, clientTotal, budget, "total")
    y += rowHeight
    this.drawPerfBar(ctx, x, y, barWidth, barHeight, clientUpdate, budget, "update")
    y += rowHeight
    this.drawPerfBar(ctx, x, y, barWidth, barHeight, clientRender, budget, "render")
    y += rowHeight

    // Server section
    if (this.serverPerf) {
      y += 10
      ctx.fillStyle = "#99bbdd"
      ctx.fillText("SERVER", x, y)
      y += 12
      this.drawPerfBar(ctx, x, y, barWidth, barHeight, parseFloat(this.serverPerf.total), budget, "total")
      y += rowHeight
      this.drawPerfBar(ctx, x, y, barWidth, barHeight, parseFloat(this.serverPerf.ai), budget, "ai")
      y += rowHeight
      this.drawPerfBar(ctx, x, y, barWidth, barHeight, parseFloat(this.serverPerf.update), budget, "update")
    }
  }

  drawPerfBar(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, value: number, budget: number, label: string) {
    const pct = Math.min(value / budget, 1)
    const color = pct < 0.5 ? "#44dd66" : pct < 0.8 ? "#ddaa44" : "#dd4466"

    // Bar background
    ctx.fillStyle = "rgba(255,255,255,0.1)"
    ctx.beginPath()
    ctx.roundRect(x, y, w, h, 3)
    ctx.fill()

    // Bar fill
    ctx.fillStyle = color
    ctx.beginPath()
    ctx.roundRect(x, y, w * pct, h, 3)
    ctx.fill()

    // Label and value
    ctx.font = "10px system-ui, sans-serif"
    ctx.fillStyle = "#aabbcc"
    ctx.fillText(label, x, y + h + 10)
    ctx.fillStyle = "#ffffff"
    ctx.fillText(`${value.toFixed(1)}ms`, x + w + 8, y + h - 1)
  }
}
