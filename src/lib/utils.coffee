Config = require "../lib/config"

Utils =
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
