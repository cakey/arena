# Arena

Multiplayer browser PvP arena game.

## Run

```
npm start          # dev server with live reload (port 8765)
npm run server     # game server (port 8001)
```

Open `http://localhost:8765` to play, or `http://localhost:8765?spectate` to watch AIs only.

## Test

```
npm test
```

Tests should be minimal - only add when fixing a bug that:
1. Is generic enough we might reintroduce it
2. Is simple enough to test without being tied to implementation details

Don't add tests for every change.

## Principles

- Fewer lines of code is always better
- Keep things minimal

## Commit Style

When committing multiple types of changes, use clear sections in the commit message:

```
Brief summary

Balance:
- Change 1
- Change 2

Visual:
- Change 1

AI:
- Change 1
```

Categories: Balance, Visual, AI, Bugfix, Other

Remind user to commit after large changes (5+ files modified).

## Pathfinding & Collision Considerations

**Two separate collision methods:**
- `circleIntersect` - for player movement, shrunk bounds to match rounded visual corners
- `circleIntersectForPathfinding` - for AI pathfinding, uses full rectangle bounds (more conservative)

This separation ensures:
- Players can get close to visually rounded corners
- AI paths stay well clear of barriers

**Visual vs Collision mismatch:**
- Barriers render with rounded corners (30% of smaller dimension)
- `getCollisionBounds()` shrinks by 70% of corner radius for movement collision
- Debug with `Config.UI.debugCollision = true` to see actual collision bounds

**Grid alignment issues:**
- Pathfinding uses a discrete grid (CELL_SIZE pixels), but barriers aren't grid-aligned
- A cell center might be "safe" but the cell edges could overlap barriers
- isCellBlocked uses `PLAYER_RADIUS + PATH_BUFFER` to mark cells near barriers as blocked

**Key constants in pathfinding.ts:**
- `CELL_SIZE` - smaller = more precise but slower (currently 15)
- `PLAYER_RADIUS` - must match actual player radius (20)
- `PATH_BUFFER` - extra margin to keep AIs away from walls (5)
- Grid blocking uses `PLAYER_RADIUS + PATH_BUFFER` (25px) - don't add more or players will be in "blocked" cells

**When modifying barriers or collision:**
1. Test with debugCollision enabled
2. Check that red debug boxes align reasonably with visuals
3. If AIs get stuck, increase PATH_BUFFER or decrease CELL_SIZE
4. Remember: pathfinding grid is generated once at startup from static barriers
5. Both circleIntersect methods must be updated if collision logic changes

## Avoiding Over-Engineering

Before proposing an abstraction or refactor, ask:

1. **Is the "duplication" actually identical?** Similar-looking code that differs in small ways often *should* stay separate. Forcing it into an abstraction creates awkward parameters or conditions.

2. **How many times is it used?** Don't abstract something used in 2-3 places. Wait until there's a clear pattern across 5+ usages.

3. **Does the abstraction make the code easier to read at the call site?** If you need type guards, special methods, or mental overhead to use it, the original was probably clearer.

4. **What's the actual bug/maintenance risk?** "Could have a typo" in 2 places isn't worth a new type system. "Will definitely break in 10 places" might be.

5. **Write out the actual code change first.** Often the "cleaner" version is more lines and harder to follow. If the refactored code isn't obviously better when you see it, don't do it.
