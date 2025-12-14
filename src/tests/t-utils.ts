import assert from "assert"
import Utils from "../lib/utils"

describe("wordWrap", () => {
  it("should wrap on a word with max characters per line", () => {
    const testString = "should wrap on a word with max characters per line"
    const resultArr = Utils.string.wordWrap(testString, 12)
    assert.deepStrictEqual(resultArr, ["should wrap", "on a word", "with max", "characters", "per line"])
  })

  it("should break wordsthataretoolonginto separatelinestoavoid overflow", () => {
    const testString = "should break wordsthataretoolonginto separatelinestoavoid overflow"
    const resultArr = Utils.string.wordWrap(testString, 12)
    assert.deepStrictEqual(resultArr, ["should break", "wordsthatar-", "etoolonginto", "separatelin-", "estoavoid", "overflow"])
  })

  it("not have a trailing empty string if last overflowed word is flush to a line", () => {
    const testString = "should break wordsthataretoolonginto"
    const resultArr = Utils.string.wordWrap(testString, 12)
    assert.deepStrictEqual(resultArr, ["should break", "wordsthatar-", "etoolonginto"])
  })
})
