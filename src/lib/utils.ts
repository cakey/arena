import Config from "./config"

export default {
  game: {
    speed: (arg: number, speedup = Config.game.speedup) => arg * speedup,
    speedInverse: (arg: number, speedup = Config.game.speedup) => arg / speedup
  },
  string: {
    wordWrap(str: string, maxChars: number): string[] {
      const words = str.split(" ")
      const wrappedLines: string[] = []
      let currentLine = ""
      for (let word of words) {
        while (word.length > maxChars) {
          if (maxChars - currentLine.length < 3) {
            wrappedLines.push(currentLine)
          } else if (currentLine.length === 0) {
            wrappedLines.push(word.slice(0, maxChars - 1) + "-")
            word = word.slice(maxChars - 1)
          } else {
            const availableChars = maxChars - currentLine.length - 2
            wrappedLines.push(" " + word.slice(0, availableChars) + "-")
            word = word.slice(availableChars)
          }
          currentLine = ""
        }
        if (word.length > 0) {
          if (currentLine.length + 1 + word.length > maxChars) {
            if (currentLine.length > 0) wrappedLines.push(currentLine)
            currentLine = word
          } else {
            if (currentLine.length > 0) currentLine += " "
            currentLine += word
          }
        }
      }
      wrappedLines.push(currentLine)
      return wrappedLines
    }
  }
}
