# Implementation Plans

| Plan | Title | Priority | Effort | Depends on | Status | Last touched | Notes |
|---|---|---:|---:|---|---|---|---|
| `2026-07-28-phase-0-probe-implementation.md` | Build the Phase 0 device probe | P1 | L | — | IN PROGRESS | 2026-07-28 | Device verification remains a hard gate before P1 |
| `2026-07-29-full-game-implementation.md` | Build the gameplay-complete DeepMine MVP | P1 | L | `2026-07-28-phase-0-probe-implementation.md` | DONE | 2026-07-30 | Core 73/73, Xcode 175/175, generic build and 19-screen read-back complete; physical device remains a release gate |
| `2026-07-31-complete-game-art-assets-implementation.md` | Generate and integrate the complete remaining game-art set | P1 | L | `2026-07-29-full-game-implementation.md` | DONE | 2026-07-31 | 40/40 PNG assets validated and integrated; build, focused tests, and 19-screen evidence passed; physical system surfaces remain a release gate |
