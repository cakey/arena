# TODO:
# interrupt skill with cooldown
# UI for cooldown / skills
# health
# heal
# shield / reversal
_ = require 'lodash'


Point = require "../lib/point"
Config = require "../lib/config"
Utils = require "../lib/utils"

Canvas = require "./canvas"
Renderers = require "./renderers"
Handlers = require "./handlers"
Player = require "../lib/player"
Engine = require "../lib/engine_core"

# Arena class containing client side code (window and event handling handling)
class UIArena

    constructor: (@canvas) ->
        @arena = new Engine.Arena

        addEventListener "mousemove", (event) =>
            @arena.mouseP = Point.fromObject event
            @arena.mapMouseP = @arena.mouseP.subtract(@arena.map.p)
                                            .subtract(@arena.map.wallSize)

        addEventListener "mousedown", (event) =>
            if event.which is 1
                @arena.mapToGo = @arena.mapMiddle.towards Point.fromObject(event), 100

        @handler = new Handlers.Network @arena
        @arena.handler = @handler
        readyPromise = @handler.ready()
        readyPromise.then =>
            @player = new UIPlayer @arena, @handler
            @arena.onReady @player, @render

    render: =>
        @canvas.begin()
        Renderers.arena @arena, @canvas, @player
        @canvas.end()


class UIPlayer

    constructor: (@arena, @handler, startP, team) ->
        @player = new Player(@arena, startP, team)

        @keyBindings =
            g: 'orb'
            h: 'flame'
            b: 'gun'
            n: 'bomb'
            j: 'interrupt'
        addEventListener "mousedown", (event) =>
            topLeft = new Point @player.radius, @player.radius
            bottomRight = @arena.map.size.subtract topLeft

            p = @arena.mapMouseP.bound topLeft, bottomRight

            if event.which is 3
                @handler.moveTo @player, p

        addEventListener "keypress", (event) =>

            if skill = @keyBindings[String.fromCharCode event.which]
                castP = @arena.mapMouseP.mapBound @player.p, @arena.map
                @handler.fire @player, castP, skill
            else
                console.log event
                console.log event.which

    update: (newTime) ->


document.addEventListener "contextmenu", ((e) -> e.preventDefault()), false

canvas = new Canvas 'canvas'
arena = new UIArena canvas
