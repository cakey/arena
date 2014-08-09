expect = require "expect.js"

Point = require "../coffee/point"

# todo: it should name tests well

describe "points", ->
    p = new Point 0, 0
    it "should have x and y initialised corrected", ->
        expect(p.x).to.be 0
        expect(p.y).to.be 0

    it "should be able to add", ->
        otherP = new Point 4, 5
        newP = p.add otherP
        expect(newP.x).to.be 4
        expect(newP.y).to.be 5

    it "should be able to subtract", ->
        otherP = new Point 4, 5
        newP = p.subtract otherP
        expect(newP.x).to.be -4
        expect(newP.y).to.be -5

    it "should have equality operators", ->
        equalP = new Point 0, 0
        notEqualP = new Point 1, 1
        expect(p.equal equalP).to.be true
        expect(p.equal notEqualP).to.be false

    it "should have angle functions", ->
        p2 = new Point -1, 0
        angle = p.angle p2
        expect(angle).to.be Math.PI

        p2 = new Point 1, 1
        angle = p.angle p2
        expect(angle).to.be Math.PI / 4

        p2 = new Point 0, 1
        angle = p.angle p2
        expect(angle).to.be Math.PI / 2

    it "should have towards functions", ->
        p2 = new Point 3, 4
        newP = p.towards p2, 2.5
        expect(newP.x).to.be.within 1.49999, 1.50001
        expect(newP.y).to.be.within 1.99999, 2.00001

    it "should be able to go on a bearing", ->
        newP = p.bearing 0, 10
        expect(newP.x).to.be 10
        expect(newP.y).to.be 0

    it "should have proximity functions", ->
        withinP = new Point 1,1
        expect(p.within(withinP, 2)).to.be true
        expect(p.within(withinP, 1)).to.be false

    # TODO:
    # bound
    # map bound
    # angleBound
