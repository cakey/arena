# Wanted: sprayArc effect - but it's random which is bad
# also hard to coordinate over network.

Point = require "../lib/point"


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
        description: "Standard range projectile, all rounder."
        cooldown: 0

    gun:
        cone: Math.PI / 10
        radius: 2
        castTime: 10
        speed: 1
        range: 800
        color: "#000000"
        channeled: false
        score: 1
        description: "High rate, low damage, long range machine gun."
        cooldown: 0

    bomb:
        cone: Math.PI / 1.5
        radius: 25
        castTime: 1000
        speed: 0.05
        range: 200
        color: "#00bbbb"
        channeled: false
        score: 500
        description: "Extremely high damage, close range, slow casting bomb."
        cooldown: 4000

        # TODO: smaller over time?

    flame:
        cone: Math.PI / 2
        radius: 12
        castTime: 5 #10
        speed: 0.3
        range: 75
        color: "#990099"
        channeled: true
        score: 3
        continue: true
        description: "Close range, low damage. Knocks back targets."
        cooldown: 0
        hitPlayer: (hitPlayer, projectile) ->
            # TODO
            # There are likely issues with network syncronisation
            #   (this needs to be calculated server side too...)
            # The arena should handle the knockback bounding

            # knockback
            angle = projectile.p.angle hitPlayer.p

            knockbackP = hitPlayer.p.bearing angle, 45

            radiusP = new Point hitPlayer.radius, hitPlayer.radius

            map = hitPlayer.gameState.map

            limitP = map.size.subtract radiusP

            boundedKnockbackP = knockbackP.bound radiusP, limitP

            hitPlayer.p = boundedKnockbackP
            # cancel cast
            hitPlayer.startCastTime = null

            hitPlayer.destP = hitPlayer.p



    interrupt:
        cone: Math.PI / 8
        radius: 4
        castTime: 1 #10
        speed: 3
        range: 1000
        color: "#aa0077"
        channeled: false
        score: 0
        description: "Instant projectile that interrupts targets. No damage."
        cooldown: 6000
        hitPlayer: (hitPlayer) ->
            hitPlayer.startCastTime = null

module.exports = skills
