# Implementation Plans

| Plan | Title | Priority | Effort | Depends on | Status | Last touched | Notes |
|---|---|---:|---:|---|---|---|---|
| `2026-07-28-phase-0-probe-implementation.md` | Build the Phase 0 device probe | P1 | L | — | IN PROGRESS | 2026-08-02 | Simulator-first implementation is authorized; physical device verification remains a release gate, not a P1 implementation blocker |
| `2026-07-29-full-game-implementation.md` | Build the gameplay-complete DeepMine MVP | P1 | L | `2026-07-28-phase-0-probe-implementation.md` | DONE | 2026-07-30 | Core 73/73, Xcode 175/175, generic build and 19-screen read-back complete; physical device remains a release gate |
| `2026-07-31-complete-game-art-assets-implementation.md` | Generate and integrate the complete remaining game-art set | P1 | L | `2026-07-29-full-game-implementation.md` | DONE | 2026-07-31 | 40/40 PNG assets validated and integrated; build, focused tests, and 19-screen evidence passed; physical system surfaces remain a release gate |
| `2026-08-02-unbounded-growth.md` | Remove the fixed product ceiling and add a second multiplicative axis | P1 | L | `2026-07-31-long-run-progression.md` | IMPLEMENTED, CLOSEOUT OPEN | 2026-08-02 | Lv.200 product cap removal, a Lv.100,000 arithmetic safety ceiling, ore-funded refinement, BigNumber wallet, purchase UI and 5/20/100km visual geology are implemented. True-uncapped arithmetic, actual-UI long simulation and refinement reinstall remain open |
