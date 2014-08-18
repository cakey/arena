skills =
    orb:
        cone: Math.PI / 5
        radius: 7
        castTime: 400
        speed: 0.6
        range: 400
        color: "#aa0000"
        channeled: true
        score: 50

    gun:
        cone: Math.PI / 10
        radius: 2
        castTime: 10
        speed: 1
        range: 800
        color: "#000000"
        channeled: false
        score: 1

    bomb:
        cone: Math.PI / 1.5
        radius: 25
        castTime: 600
        speed: 0.05
        range: 800
        color: "#00bbbb"
        channeled: false
        score: 500

    flame:
        cone: Math.PI / 2
        radius: 12
        castTime: 5 #10
        speed: 0.3
        range: 55
        color: "#990099"
        channeled: true
        score: 3

module.exports = skills
