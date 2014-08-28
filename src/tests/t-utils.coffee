expect = require "expect.js"

Utils = require "../lib/utils"

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
