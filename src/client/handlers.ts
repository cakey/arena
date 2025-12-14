import Config from "../lib/config"
import { v4 as uuid } from "uuid"
import Point from "../lib/point"
import { GamePlayer, UIPlayer, AIPlayer } from "../lib/player"
import * as Renderers from "./renderers"
import type GameState from "../lib/game-state"
import type Canvas from "./canvas"
import type Camera from "./camera"

export class Client {
  host: string; ws: WebSocket; client_uuid: string; locallyProcessed: AIPlayer[] = []
  focusedUIPlayer: UIPlayer | null = null; time = 0; tickNo = 0
  private _ready: Promise<void>

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
        case "sync": this.gameState.sync(d); break
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
    const newTime = Date.now()
    for (const player of this.locallyProcessed) player.update(newTime, this.gameState)
    this.camera.update(newTime - this.time)
    this.gameState.update(newTime)
    this.canvas.begin()
    Renderers.arena(this.gameState, this.canvas, this.camera, this.focusedUIPlayer)
    if (this.tickNo % 5 === 0) Renderers.ui(this.gameState, this.canvas, this.camera, this.focusedUIPlayer)
    this.canvas.end()
    this.time = newTime
  }
}
