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

    string:
        wordWrap: (str, maxChars) ->
            words = str.split " "
            wrappedLines = []
            currentLine = ""
            for word in words
                # handle words larger than maxChars
                while word.length > maxChars
                    if maxChars - currentLine.length < 3 # " -c"
                        # no space left on the line
                        wrappedLines.push currentLine
                    else if currentLine.length is 0
                        # empty line
                        wrappedLines.push "#{word[...(maxChars - 1)]}-"
                        word = word[(maxChars - 1)..]
                    else
                        # squeeze as much of the word as you can on the line
                        availableChars = maxChars - currentLine.length - 2
                        wrappedLines.push " #{word[...availableChars]}-"
                        word = word[availableChars..]
                    currentLine = ""

                if word.length > 0
                    if currentLine.length + 1 + word.length > maxChars
                        if currentLine.length > 0
                            wrappedLines.push currentLine
                        currentLine = word
                    else
                        if currentLine.length > 0
                            currentLine += " "
                        currentLine += word
                        currentLine.length += word.length + 1

            wrappedLines.push currentLine
            return wrappedLines

module.exports = Utils
