skills =
    orb:
        cone: Math.PI / 5
        radius: 7
        castTime: 750
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
        castTime: 1000
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
        range: 75
        color: "#990099"
        channeled: true
        score: 3
        hitPlayer: (hitPlayer, projectile) ->
            # TODO
            # There are likely issues with network syncronisation
            #   (this needs to be calculated server side too...)
            # Also, probably bug with knockback out of arena...

            # knockback
            angle = projectile.p.angle hitPlayer.p
            hitPlayer.p = hitPlayer.p.bearing angle, 45
            # cancel cast
            hitPlayer.startCastTime = null


    interrupt:
        cone: Math.PI / 8
        radius: 4
        castTime: 1 #10
        speed: 3
        range: 1000
        color: "#aa0077"
        channeled: false
        score: 0
        hitPlayer: (hitPlayer) ->
            hitPlayer.startCastTime = null

module.exports = skills
