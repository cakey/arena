# Wanted: sprayArc effect - but it's random which is bad
# also hard to coordinate over network.

Point = require "./point"
Config = require "./config"
Barriers = require "./mechanics/barriers"

skills =
    orb:
        cone: Math.PI / 5
        radius: 7
        castTime: 750
        speed: 0.6
        range: 400
        color: "#aa0000"
        channeled: true
        score: 0 #50
        description: "Standard range projectile, all rounder."
        cooldown: 0
        enemies: true
        type: "projectile"

    gun:
        cone: Math.PI / 10
        radius: 2
        castTime: 10
        speed: 1
        range: 800
        color: "#000000"
        channeled: false
        score: 0 #1
        description: "High rate, low damage, long range machine gun."
        cooldown: 0
        enemies: true
        hitPlayer: (hitPlayer, projectile, gameState) ->
            gameState.killPlayer hitPlayer.id
        type: "projectile"


    bomb:
        cone: Math.PI / 1.5
        radius: 12
        castTime: 600
        speed: 0.15
        range: 300
        color: "#00bbbb"
        channeled: false
        score: 0 #500
        description: "One hit kill."
        cooldown: 3000
        enemies: true
        type: "projectile"
        hitPlayer: (hitPlayer, projectile, gameState) ->
            gameState.killPlayer hitPlayer.id


    flame:
        cone: Math.PI / 2
        radius: 6
        castTime: 150 #10
        speed: 0.4
        range: 250
        color: "#990099"
        channeled: false
        score: 0 #3
        description: "Close range, low damage. Knocks back targets."
        cooldown: 2000
        enemies: true
        type: "projectile"

        hitPlayer: (hitPlayer, projectile, gameState) ->
            # TODO
            # There are likely issues with network syncronisation
            #   (this needs to be calculated server side too...)
            # The arena should handle the knockback bounding

            if not hitPlayer.states["invulnerable"]?
                # knockback
                angle = projectile.p.angle hitPlayer.p

                knockbackP = hitPlayer.p.bearing angle, 100

                radiusP = new Point hitPlayer.radius, hitPlayer.radius

                limitP = gameState.map.size.subtract radiusP

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
        score: 0 #0
        description: "Instant projectile that interrupts targets. No damage."
        cooldown: 6000
        type: "projectile"
        enemies: true

        hitPlayer: (hitPlayer) ->
            hitPlayer.startCastTime = null

    invulnerable:
        castTime: 50
        radius: 5
        cone: Math.PI * 2
        color: Config.colors.invulnerable
        range: 1000
        channeled: false
        score: 0
        description: "Makes targeted ally invulnerable."
        cooldown: 8000
        type: "targeted"
        accuracyRadius: 40
        allies: true
        enemies: false

        hitPlayer: (hitPlayer) ->
            hitPlayer.applyState "invulnerable", 2000

    barrier:
        castTime: 150
        type: "ground_targeted"
        radius: 4
        color: Config.colors.barrierBrown
        range: 1000
        channeled: false
        score: 0
        description: "Create a ground barrier"
        cooldown: 8000
        cone: Math.PI

        onLand: (gameState, castP, originP) ->

            # make barrier perpendicular to cast/player line
            barrierAngle = castP.angle(originP) + Math.PI/2
            for i in [-6..6]
                loc = castP.bearing barrierAngle, 12*i

                tl = loc.subtract new Point 4, 4
                br = loc.add new Point 4, 4
                barrier = new Barriers.Rect tl, br

                gameState.createBarrier barrier, 3250 - (Math.abs(i) * 80)


module.exports = skills
