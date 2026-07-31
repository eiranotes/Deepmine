# DeepMine

DeepMine is being redesigned from a Pomodoro/focus utility into a native idle clicker game about direct excavation, visible machinery growth, geological layers, offline progression, and repeated mine collapse.

## Product direction

```text
Tap and fracture rock
→ collect Ore
→ install automated machinery
→ descend through geological layers
→ trigger short active production surges
→ reach an unstable core
→ collapse the mine for permanent Core Shards
→ rebuild faster
```

The timer, focus session, break session, productivity history, and focus-streak loop are outside the new product scope.

## Planning documents

- [Product specification](docs/PRODUCT_SPEC.md) — core loop, resources, equipment, geological layers, active events, prestige, offline progression, UI, and visual direction.
- [Technical implementation plan](docs/TECHNICAL_PLAN.md) — proposed SwiftUI/SpriteKit architecture, deterministic simulation, persistence, migration, testing, CI, and performance rules.
- [Implementation backlog](docs/IMPLEMENTATION_BACKLOG.md) — ordered milestones from repository import through release-candidate validation, including definitions of done.
- [Pivot plan review](docs/PIVOT_PLAN_REVIEW.md) — the three documents above reviewed against the reuse-first constraint: what is settled, what is an unverified assumption, and the revised milestone ordering.
- [Source import guide](docs/SOURCE_IMPORT.md) — how to push the local Xcode project into this repository. **Currently the blocking prerequisite for all engineering work.**
- [Current project audit](docs/CURRENT_PROJECT_AUDIT.md) — template, to be filled from the real source once imported.

## Current repository state

**This repository contains documentation only.** There is no `.xcodeproj`, no Swift source, and no assets — the existing local DeepMine project has never been pushed.

This matters more than it may appear. The planning documents were written against an empty repository, so they describe the target game but could not describe the code being pivoted. Every reuse decision — which persistence layer survives, whether the mine scene is SpriteKit or SwiftUI, which services carry over — depends on facts that only the real source can supply.

The first engineering milestone is therefore to import and audit the current source, following [the import guide](docs/SOURCE_IMPORT.md), before mapping removal and reuse work to exact file paths.

Recommended baseline stack after audit:

- Swift and SwiftUI application shell;
- SpriteKit interactive mine scene;
- fixed-step deterministic game simulation independent of frame rate;
- versioned local save with backup and migration;
- offline progression calculated in aggregate;
- iOS Simulator build and tests in GitHub Actions.

## First executable slice

The first playable milestone is intentionally narrow:

1. launch directly into the mine;
2. tap a rock and see damage feedback;
3. break the segment and receive Ore;
4. buy a visible starter drill;
5. observe automatic damage;
6. save, terminate, and relaunch without losing progression.

Content expansion, additional layers, modifications, and prestige follow only after this slice works end to end.
