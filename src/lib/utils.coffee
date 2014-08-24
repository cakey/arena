Config = require "../lib/config"

Utils =
    randInt: (lower, upper = 0) ->
        start = Math.random()
        if not lower?
            throw new "randInt expected at least 1 argument"
        if lower > upper
            [lower, upper] = [upper, lower]
        return Math.floor(start * (upper - lower + 1) + lower)


    some: (arr, f) ->
        (return true if f x) for x in arr
        return false

    every: (arr, f) ->
        (return false if not f x) for x in arr
        return true

    choice: (arr) ->
        arr[Math.floor(Math.random() * arr.length)]

    game:
        speed: (arg, speedup = Config.game.speedup) ->
            arg * speedup

        speedInverse: (arg, speedup = Config.game.speedup) ->
            arg / speedup


module.exports = Utils
