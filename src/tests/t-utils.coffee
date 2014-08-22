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
