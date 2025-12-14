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

## Avoiding Over-Engineering

Before proposing an abstraction or refactor, ask:

1. **Is the "duplication" actually identical?** Similar-looking code that differs in small ways often *should* stay separate. Forcing it into an abstraction creates awkward parameters or conditions.

2. **How many times is it used?** Don't abstract something used in 2-3 places. Wait until there's a clear pattern across 5+ usages.

3. **Does the abstraction make the code easier to read at the call site?** If you need type guards, special methods, or mental overhead to use it, the original was probably clearer.

4. **What's the actual bug/maintenance risk?** "Could have a typo" in 2 places isn't worth a new type system. "Will definitely break in 10 places" might be.

5. **Write out the actual code change first.** Often the "cleaner" version is more lines and harder to follow. If the refactored code isn't obviously better when you see it, don't do it.
