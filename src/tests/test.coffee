expect = require "expect.js"

describe "the world", ->
    it "should say hello", ->
        expect("hello world").to.be.a('string')
