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

## Current repository state

At the time of this pivot plan, the GitHub repository did not contain the existing local Xcode project. The first engineering milestone is therefore to import and audit the current source before mapping removal and reuse work to exact file paths.

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
