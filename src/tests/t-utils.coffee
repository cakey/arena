expect = require "expect.js"

Utils = require "../lib/utils"

describe "randInt", ->
    it "should have not return a number out of bounds", ->
        expect(Utils.randInt 4, 5).to.be.within 4, 5

describe "some", ->
    it "should return false when all false", ->
        expect(Utils.some([false, false, false], (a) -> a)).to.be false

    it "should return true when one true", ->
        expect(Utils.some([false, false, true], (a) -> a)).to.be true

describe "every", ->
    it "should return false when one false", ->
        expect(Utils.every([true, false, true], (a) -> a)).to.be false

    it "should return true when all true", ->
        expect(Utils.every([true, true, true], (a) -> a)).to.be true

describe  "wordWrap", ->
    it "should wrap on a word with max characters per line", ->
        testString = "should wrap on a word with max characters per line"
        resultArr = Utils.string.wordWrap testString, 12
        expect(resultArr).to.eql [
            "should wrap",
            "on a word",
            "with max",
            "characters",
            "per line"
        ]

    it "should break wordsthataretoolonginto separatelinestoavoid overflow", ->
        testString = "should break wordsthataretoolonginto separatelinestoavoid overflow"
        resultArr = Utils.string.wordWrap testString, 12
        expect(resultArr).to.eql [
            "should break",
            "wordsthatar-",
            "etoolonginto",
            "separatelin-",
            "estoavoid",
            "overflow",
        ]

    it "not have a trailing empty string if last overflowed word is flush to a line", ->
        testString = "should break wordsthataretoolonginto"
        resultArr = Utils.string.wordWrap testString, 12
        expect(resultArr).to.eql [
            "should break",
            "wordsthatar-",
            "etoolonginto",
        ]
