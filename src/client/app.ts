import _ from "lodash"
import GameState from "../lib/game-state"
import Config from "../lib/config"
import Canvas from "./canvas"
import Camera from "./camera"
import { Client } from "./handlers"
import { UIPlayer } from "../lib/player"

document.addEventListener("contextmenu", (e) => e.preventDefault(), false)

const camera = new Camera()
const canvas = new Canvas("canvas")
const gameState = new GameState(Date.now())

const isSpectator = new URLSearchParams(window.location.search).has("spectate")

const handler = new Client(gameState, canvas, camera)
handler.ready().then(() => {
  try {
    gameState.addTeam("red", Config.colors.red)
    gameState.addTeam("blue", Config.colors.blue)
    if (!isSpectator) {
      const randomTeam = _.sample(Object.keys(gameState.teams))!
      handler.focusedUIPlayer = new UIPlayer(gameState, handler, gameState.map.randomPoint(), randomTeam)
      handler.registerLocal(handler.focusedUIPlayer)
    }
    if (Config.game.numAIs > 0) {
      gameState.addTeam("yellowAI", Config.colors.yellow)
      gameState.addTeam("greenAI", Config.colors.green)
    }
    handler.startLoop()
  } catch (e: any) {
    console.log(e.message)
    console.log(e.stack)
  }
})
