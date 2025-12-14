import { v4 as uuid } from "uuid"
import { WebSocketServer, WebSocket } from "ws"
import Config from "../lib/config"
import GameState from "../lib/game-state"
import Point from "../lib/point"
import { GamePlayer, AIPlayer } from "../lib/player"

class FixedBuffer {
  i = 0; _arr: number[] = []
  constructor(public n: number) {}
  add(v: number) { if (this.i < this.n) this._arr[this.i++] = v; else { this.i = 0; this._arr[this.i] = v } }
  average() { return this._arr.reduce((a, b) => a + b, 0) / this._arr.length }
}

class GameHandler {
  SERVERID = "SERVER"; tick = 0; gameState!: GameState; locallyProccessed: AIPlayer[] = []
  loopTimeout: NodeJS.Timeout | null = null

  start() {
    console.log("Game Loop (start)")
    this.tick = 0
    this.gameState = new GameState(Date.now())
    this.gameState.addTeam("red", Config.colors.red)
    this.gameState.addTeam("blue", Config.colors.blue)
    if (Config.game.numAIs > 0) {
      this.gameState.addTeam("yellowAI", Config.colors.yellow)
      this.gameState.addTeam("greenAI", Config.colors.green)
    }
    this.locallyProccessed = []
    for (let a = 0; a < Config.game.numAIs; a++) {
      this.registerAI(new AIPlayer(this, this.gameState.map.randomPoint(), "yellowAI"))
      this.registerAI(new AIPlayer(this, this.gameState.map.randomPoint(), "greenAI"))
    }
    process.nextTick(this.loop)
  }

  loop = () => {
    this.loopTimeout = setTimeout(this.loop, Config.game.tickTime)
    const newTime = Date.now()
    for (const ai of this.locallyProccessed) ai.update(newTime, this.gameState)
    this.gameState.update(newTime)
    if (this.tick % 500 === 0) console.log(JSON.stringify(this.gameState, null, 4))
    if (this.tick % 200 === 0) {
      for (const [clientID] of Object.entries(clientHandler.clients)) {
        console.log(clientID, clientHandler.clientPings[clientID].average())
      }
    }
    if (this.tick % 10 === 0) clientHandler.sendPings()
    if (this.tick % 5 === 0) clientHandler.broadcast({ data: this.gameState, action: "sync" })
    this.tick++
  }

  newPlayer(d: any) {
    const playerPosition = Point.fromObject(d.playerPosition)!
    const player = new GamePlayer(this.gameState.time, playerPosition, d.team, d.playerId)
    this.gameState.addPlayer(player)
  }

  removePlayer(id: string) { this.gameState.removePlayer(id) }
  movePlayer(id: string, dest: Point) { this.gameState.movePlayer(id, dest) }
  playerFire(id: string, castP: Point, skillName: string) { this.gameState.playerFire(id, castP, skillName) }

  registerAI(ai: AIPlayer) {
    this.locallyProccessed.push(ai)
    clientHandler.newPlayer(null, {
      action: "newPlayer",
      data: { playerId: ai.id, playerPosition: ai.p.toObject(), team: ai.team },
      id: this.SERVERID
    })
  }

  triggerMoveTo(player: { id: string; team: string }, destP: Point) {
    clientHandler.control(null, {
      action: "control",
      data: { playerId: player.id, action: "moveTo", actionPosition: destP.toObject(), team: player.team },
      id: this.SERVERID
    })
  }

  triggerFire(player: { id: string; team: string }, castP: Point, skillName: string) {
    clientHandler.control(null, {
      action: "control",
      data: { playerId: player.id, action: "fire", actionPosition: castP.toObject(), skill: skillName, team: player.team },
      id: this.SERVERID
    })
  }

  stop() {
    console.log("Game Loop (end)")
    if (this.loopTimeout) clearTimeout(this.loopTimeout)
    this.gameState = null as any
    this.locallyProccessed = []
  }
}

class ClientHandler {
  messageCount = 0
  players: Record<string, Record<string, any>> = {}
  clients: Record<string, WebSocket> = {}
  pings: Record<string, { clientID: string; time: number }> = {}
  clientPings: Record<string, FixedBuffer> = {}

  constructor(public wss: WebSocketServer) {
    wss.on("connection", (ws) => {
      ws.on("message", (unparsed) => this.sprayMessage(ws, unparsed.toString()))
    })
  }

  send(clientID: string, json: string) {
    this.clients[clientID]?.send(json, (e) => { if (e) { console.log(e.message); this.deregister(null, { id: clientID }) } })
  }

  sprayMessage(ws: WebSocket, unparsed: string) {
    this.messageCount++
    if (this.messageCount % 100 === 0) console.log(this.messageCount)
    try {
      const message = JSON.parse(unparsed)
      switch (message.action) {
        case "register": this.register(ws, message); break
        case "deregister": this.deregister(ws, message); break
        case "control": this.control(ws, message); break
        case "newPlayer": this.newPlayer(ws, message); break
        case "ping": this.ping(ws, message); break
        default: console.log("Unsupported message action", message.action)
      }
    } catch (e: any) { console.log("EXCEPTION!", e.message, e.stack) }
  }

  broadcast(message: any) {
    const json = JSON.stringify(message)
    for (const clientID of Object.keys(this.clients)) this.send(clientID, json)
  }

  sendPings() {
    for (const clientID of Object.keys(this.clients)) {
      const pingID = uuid()
      this.pings[pingID] = { clientID, time: Date.now() }
      this.send(clientID, JSON.stringify({ data: pingID, action: "ping" }))
    }
  }

  register(ws: WebSocket, message: any) {
    console.log("register ---", message.id.slice(0, 8))
    this.clients[message.id] = ws
    this.clientPings[message.id] = new FixedBuffer(50)
    this.players[message.id] = {}
    if (Object.keys(this.clients).length === 1) {
      this.players[gameHandler.SERVERID] = {}
      gameHandler.start()
    }
    for (const [client_id, clientPs] of Object.entries(this.players)) {
      if (client_id !== message.id) {
        for (const p of Object.values(clientPs)) {
          this.send(message.id, JSON.stringify({ data: p, action: "newPlayer" }))
        }
      }
    }
  }

  deregister(ws: WebSocket | null, message: any) {
    console.log("deregister -", message.id.slice(0, 8))
    delete this.clients[message.id]
    for (const id of Object.keys(this.players[message.id] || {})) {
      this.broadcast({ data: id, action: "deletePlayer" })
      gameHandler.removePlayer(id)
    }
    delete this.players[message.id]
    if (Object.keys(this.clients).length === 0) {
      this.players = {}
      gameHandler.stop()
    }
  }

  control(ws: WebSocket | null, message: any) {
    this.broadcast(message)
    const { playerId, actionPosition, action, skill } = message.data
    const point = Point.fromObject(actionPosition)!
    if (action === "moveTo") gameHandler.movePlayer(playerId, point)
    else if (action === "fire") gameHandler.playerFire(playerId, point, skill)
  }

  newPlayer(ws: WebSocket | null, message: any) {
    gameHandler.newPlayer(message.data)
    this.players[message.id][message.data.playerId] = message.data
    this.broadcast(message)
  }

  ping(ws: WebSocket, message: any) {
    const ping = this.pings[message.data]
    if (ping) this.clientPings[ping.clientID].add(Date.now() - ping.time)
  }
}

const wss = new WebSocketServer({ port: Config.ws.port })
const gameHandler = new GameHandler()
const clientHandler = new ClientHandler(wss)
console.log(`WebSocket server listening on port ${Config.ws.port}`)
