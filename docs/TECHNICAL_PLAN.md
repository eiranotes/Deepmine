# DeepMine Technical Implementation Plan

> Scope: native iPhone implementation of the idle/clicker pivot
> Repository state at planning time: empty except for initialization and planning documents

## 1. Baseline assumptions

The recommended implementation is:

- Swift;
- SwiftUI for application shell, navigation, sheets, settings, and equipment panels;
- SpriteKit for the interactive mine scene, particles, machinery, fracture overlays, and collapse sequences;
- no server dependency for the first release;
- versioned local save files;
- deterministic economy and event generation where practical;
- iOS Simulator build and unit tests through GitHub Actions after the Xcode project is committed.

If the existing local DeepMine project uses a different rendering stack, the first implementation task is a source import and architecture audit. Product rules in `PRODUCT_SPEC.md` remain authoritative; renderer-specific details may change.

## 2. Repository bootstrap

Before game implementation begins, commit the actual local project to this repository.

Required baseline files:

```text
DeepMine.xcodeproj/ or DeepMine.xcworkspace/
DeepMine/
DeepMineTests/
DeepMineUITests/           optional at initial import
.github/workflows/ios.yml
.gitignore
README.md
docs/
```

Bootstrap checks:

- confirm the app target, bundle identifier, deployment target, and shared scheme;
- remove local signing identities, API keys, and machine-specific paths;
- verify all source and asset files are referenced by the project;
- record third-party package dependencies;
- confirm whether existing Pomodoro data must be migrated or can be discarded;
- build the imported baseline before removing old functionality;
- tag or branch the final pre-pivot version if historical recovery is required.

## 3. Proposed module structure

```text
DeepMine/
├── App/
│   ├── DeepMineApp.swift
│   ├── AppEnvironment.swift
│   └── RootView.swift
├── GameCore/
│   ├── Model/
│   │   ├── GameState.swift
│   │   ├── RunState.swift
│   │   ├── PermanentState.swift
│   │   ├── RockSegment.swift
│   │   ├── EquipmentState.swift
│   │   ├── ModificationState.swift
│   │   └── LayerDefinition.swift
│   ├── Economy/
│   │   ├── EconomyEngine.swift
│   │   ├── UpgradePricing.swift
│   │   ├── ProductionCalculator.swift
│   │   ├── PrestigeCalculator.swift
│   │   └── LargeNumber.swift
│   ├── Simulation/
│   │   ├── GameSimulation.swift
│   │   ├── FixedStepClock.swift
│   │   ├── DamageResolver.swift
│   │   ├── SegmentGenerator.swift
│   │   ├── EventEngine.swift
│   │   └── SeededRandom.swift
│   └── Content/
│       ├── EquipmentCatalog.swift
│       ├── LayerCatalog.swift
│       ├── ModificationCatalog.swift
│       └── ResearchCatalog.swift
├── Persistence/
│   ├── SaveEnvelope.swift
│   ├── SaveRepository.swift
│   ├── SaveMigration.swift
│   └── OfflineProgressCalculator.swift
├── Presentation/
│   ├── GameStore.swift
│   ├── Formatters/
│   └── ViewState/
├── MineScene/
│   ├── MineScene.swift
│   ├── MineSceneCoordinator.swift
│   ├── RockRenderer.swift
│   ├── MachineryRenderer.swift
│   ├── FractureRenderer.swift
│   ├── ParticlePool.swift
│   └── SceneEvents.swift
├── Features/
│   ├── Mine/
│   ├── Upgrades/
│   ├── Loadout/
│   ├── Prestige/
│   ├── OfflineSummary/
│   ├── Onboarding/
│   └── Settings/
├── Services/
│   ├── AudioService.swift
│   ├── HapticsService.swift
│   ├── AppLifecycleService.swift
│   └── AnalyticsService.swift
└── Resources/
    ├── Assets.xcassets
    ├── Audio/
    └── Localization/
```

The exact grouping may follow the imported project conventions. The separation between pure game logic, persistent state, presentation, and rendering should remain.

## 4. State ownership

### 4.1 `GameState`

Top-level persistent state:

```swift
struct GameState: Codable, Equatable {
    var schemaVersion: Int
    var run: RunState
    var permanent: PermanentState
    var settings: PlayerSettings
    var lifetime: LifetimeStatistics
    var lastSavedAt: Date
    var randomSeed: UInt64
}
```

### 4.2 `RunState`

Reset on prestige:

- ore;
- current depth and segment;
- equipment levels and enabled states;
- current power usage;
- heat;
- impact meter;
- run modifications;
- temporary event state;
- run statistics.

### 4.3 `PermanentState`

Persist across prestige:

- Core Shards;
- research levels;
- unlocked layers and variants;
- automation unlocks;
- tutorial flags;
- cosmetic selections.

### 4.4 `GameStore`

`GameStore` is the main-actor presentation owner.

Responsibilities:

- expose read-only view state to SwiftUI;
- translate UI intents into engine commands;
- publish coarse simulation changes;
- coordinate save, foreground, background, and scene events;
- never contain economy formulas.

Recommended shape:

```swift
@MainActor
@Observable
final class GameStore {
    private(set) var state: GameState
    private let simulation: GameSimulation
    private let saves: SaveRepository

    func tapRock(at normalizedPoint: CGPoint)
    func setDrillOverdrive(active: Bool)
    func purchase(_ equipment: EquipmentID, quantity: PurchaseQuantity)
    func selectModification(_ id: ModificationID)
    func performCollapse()
    func handleForeground(now: Date)
    func handleBackground(now: Date)
}
```

## 5. Simulation model

### 5.1 Separate simulation from rendering

The economy must not depend on SpriteKit frame rate.

Use two clocks:

- fixed-step simulation, recommended 10 updates per second;
- visual rendering at the system-provided frame rate.

The simulation emits aggregate events such as:

- `damageApplied`;
- `criticalHit`;
- `segmentDamaged(stage:)`;
- `segmentBroken`;
- `oreGranted`;
- `equipmentPurchased`;
- `resonanceStarted`;
- `layerChanged`;
- `collapseStarted`.

SpriteKit consumes these events to animate the result. It does not calculate rewards.

### 5.2 Fixed-step update

```text
accumulator += elapsedTime
while accumulator >= fixedStep:
    simulate(fixedStep)
    accumulator -= fixedStep
```

Constraints:

- clamp a single foreground frame delta to avoid a large update after interruption;
- background progress is handled separately, never by replaying thousands of live ticks;
- production can be aggregated mathematically when no event boundary occurs;
- scheduled attacks and heat thresholds use deterministic timers.

### 5.3 Command processing

All state mutations pass through explicit commands:

```swift
enum GameCommand {
    case manualHit(point: NormalizedPoint)
    case beginOverdrive
    case endOverdrive
    case purchaseEquipment(EquipmentID, PurchaseQuantity)
    case enableEquipment(EquipmentID, Bool)
    case chooseModification(ModificationID)
    case collectResonance(ResonanceNodeID)
    case collapseMine
}
```

Commands simplify replayable tests, debugging, and analytics.

## 6. Large-number representation

`Double` is sufficient for early prototypes but should not be exposed directly across all game code. Introduce a small value type from the start.

Recommended representation:

```swift
struct LargeNumber: Codable, Comparable, Hashable {
    var mantissa: Double       // normalized absolute value [1, 1000), or zero
    var exponent: Int          // base-1000 exponent
}
```

Required operations:

- addition and subtraction with magnitude cutoff;
- multiplication and division;
- integer and fractional powers used by balance formulas;
- comparisons;
- finite-value validation;
- compact formatting: `1.23K`, `4.56M`, `7.89B`, then scientific notation;
- Codable round-trip tests.

Rules:

- no NaN or infinity may enter persistent state;
- negative ore and cost are invalid;
- rounding is display-only;
- affordability uses exact internal comparison.

## 7. Economy engine

### 7.1 Pure calculations

`EconomyEngine` and related calculators should be stateless functions over immutable inputs.

Examples:

```swift
func segmentHealth(for context: SegmentContext) -> LargeNumber
func segmentReward(for context: SegmentContext) -> LargeNumber
func equipmentCost(id: EquipmentID, fromLevel: Int, quantity: Int) -> LargeNumber
func stableDPS(state: GameState) -> LargeNumber
func manualImpact(state: GameState) -> LargeNumber
func prestigeReward(state: GameState) -> Int
```

### 7.2 Catalog-driven content

Equipment, layers, research, and modifications should be data definitions, not scattered switch statements inside views.

```swift
struct EquipmentDefinition {
    let id: EquipmentID
    let baseCost: LargeNumber
    let costGrowth: Double
    let basePower: LargeNumber
    let powerConsumption: Int
    let milestones: [EquipmentMilestone]
    let sceneStageThresholds: [Int]
}
```

Catalogs may remain compiled Swift in the first release. External JSON is unnecessary unless live tuning is introduced.

### 7.3 Balance simulation

Add a developer-only command-line or unit-test harness that can simulate:

- passive-only progression;
- reasonable active weak-point collection;
- optimal purchase by lowest payback time;
- first prestige timing target;
- second-run acceleration;
- offline return scenarios;
- extreme upgrade levels.

Simulation output should include CSV or structured logs for:

- time to equipment milestones;
- time per segment and layer;
- ore income split by source;
- prestige reward by run length;
- stalled states caused by power or pricing.

## 8. Rock generation and fracture logic

### 8.1 Deterministic segment generation

A rock segment is generated from:

```text
runSeed + depthIndex + layerID + variantID
```

The generated model includes:

- health and reward modifiers;
- weak-point count and normalized positions;
- fracture graph seed;
- visual rock variant;
- optional resonance eligibility.

The renderer can vary cosmetic particles nondeterministically, but economic outcomes must derive from deterministic data.

### 8.2 Fracture graph

Represent targetable fracture points as a small graph rather than pixel-perfect physics.

```swift
struct FractureNode {
    let id: Int
    let position: NormalizedPoint
    let criticalMultiplier: Double
    let neighbors: [Int]
}
```

A critical hit can traverse a bounded number of neighbors according to upgrades. This provides chain-collapse behavior without runtime rigid-body fracture simulation.

### 8.3 Damage stages

Rock visuals use discrete stages, for example:

- pristine: 100-76%;
- cracked: 75-51%;
- fractured: 50-26%;
- unstable: 25-1%;
- collapse.

The simulation sends stage changes only when crossing a boundary. This avoids redrawing fracture textures on every hit.

## 9. SpriteKit scene architecture

### 9.1 Scene coordinator

`MineSceneCoordinator` bridges `GameStore` and `MineScene`.

- passes normalized input from scene to store;
- receives immutable render snapshots and scene events;
- does not expose mutable game state to SpriteKit nodes;
- queues important animation events in order;
- coalesces repeated minor damage events.

### 9.2 Node hierarchy

```text
MineScene
├── backgroundLayer
├── shaftLayer
│   ├── rearMachineryLayer
│   ├── rockLayer
│   ├── fractureLayer
│   ├── frontMachineryLayer
│   └── conveyorLayer
├── effectLayer
├── interactionLayer
└── debugLayer
```

### 9.3 Performance rules

- use texture atlases;
- reuse particles and floating-number nodes through pools;
- cap simultaneous debris;
- pause invisible or occluded machinery animation;
- avoid generating textures during rapid tapping;
- use normalized coordinate hit testing;
- keep physics bodies limited to effects that need them;
- test on the lowest supported device class.

## 10. SwiftUI feature structure

### 10.1 Root

`RootView` owns the mine screen and overlays:

- top HUD;
- impact, heat, and power strip;
- bottom navigation;
- upgrade/loadout/core sheets;
- offline summary;
- onboarding hints;
- settings.

### 10.2 Render snapshots

SwiftUI views should receive formatted or derived values through lightweight snapshots so they do not recompute the full economy on every scene tick.

```swift
struct HUDSnapshot: Equatable {
    let oreText: String
    let productionText: String
    let depthText: String
    let layerName: LocalizedStringKey
    let powerUsage: Int
    let powerCapacity: Int
    let heatFraction: Double
    let impactFraction: Double
}
```

Update HUD-level values at a lower cadence than visual effects where possible.

### 10.3 Purchase interactions

The purchase API must support:

- one level;
- ten levels;
- maximum affordable levels;
- projected result before purchase;
- disabled reason: insufficient ore, power, prerequisite, or layer lock.

The maximum-affordable calculation should use binary search or a closed geometric-series solution rather than repeated subtraction.

## 11. Persistence

### 11.1 Save format

Use an envelope around game state:

```swift
struct SaveEnvelope: Codable {
    let formatVersion: Int
    let createdAt: Date
    let savedAt: Date
    let payload: GameState
}
```

Storage:

- Application Support directory;
- atomic write to a temporary file, then replace;
- retain one previous backup;
- encode with stable date strategy;
- validate decoded values before accepting;
- recover from backup if the main file is corrupt.

### 11.2 Save triggers

- meaningful purchase;
- segment break, debounced;
- prestige;
- app background;
- periodic autosave while active;
- settings change.

Do not write on every simulation tick.

### 11.3 Schema migration

Every schema change increments `formatVersion`.

Migration chain:

```text
v1 -> v2 -> v3 -> current
```

Each migration is independently unit-tested using fixture files.

New Codable fields require defaults through migration or custom decoding. Do not rely on synthesized decoding when old saves lack required fields.

### 11.4 Pomodoro data boundary

Old focus data should not be silently interpreted as game currency.

Migration options, selected after inspecting the local project:

1. discard game-incompatible data and retain only settings;
2. archive old data in a separate legacy file for one release;
3. provide a one-time explicit reset notice if an installed build already exists publicly.

The implementation plan assumes no conversion of focus minutes or streaks into Ore or Core Shards.

## 12. Offline progression

`OfflineProgressCalculator` receives a saved state and elapsed duration. It returns a transaction summary and resulting state.

```swift
struct OfflineProgressResult {
    let effectiveDuration: TimeInterval
    let oreEarned: LargeNumber
    let segmentsCleared: Int
    let resultingDepth: Int
    let state: GameState
}
```

Rules:

- clamp duration to the current cap;
- apply stable automatic output only;
- do not roll live resonance events repeatedly;
- advance deterministic scheduled machinery where economically relevant;
- process segment boundaries in batches;
- cap loops and use aggregate formulas for very high production;
- save the result before presenting the summary.

Tests must cover app termination, device time moving backward, maximum cap, zero production, crossing layers, and reaching a prestige threshold while offline.

## 13. Audio and haptics

### 13.1 Audio

`AudioService` manages:

- pooled impact sounds;
- machinery loops by family;
- layer ambience;
- one-shot critical, break, resonance, and collapse cues;
- volume groups;
- interruption and route changes.

Avoid starting a new audio player per tap.

### 13.2 Haptics

Prepare generators in advance and throttle repeated light impacts.

Required patterns:

- light manual hit;
- medium critical hit;
- heavy segment break;
- structured resonance success;
- collapse sequence.

Respect the in-app haptic toggle and system accessibility behavior.

## 14. Lifecycle and notifications

The game does not require Pomodoro alerts.

Optional return notification support, deferred until the core game is stable:

- notify when offline cap is reached;
- notify when a selected long machine cycle completes;
- never schedule notifications as a prerequisite for earning progress.

Lifecycle handling:

- record monotonic active deltas for live simulation;
- record wall-clock save timestamp for offline calculation;
- flush save on background;
- stop unnecessary rendering and audio in background;
- calculate offline result once on foreground.

## 15. Accessibility and localization

Minimum requirements:

- Dynamic Type for SwiftUI panels;
- VoiceOver labels for ore, production, depth, purchase cost, and disabled reasons;
- non-color indicators for heat and power states;
- Reduce Motion mode that replaces large camera shake and rapid flashes;
- haptic and audio toggles;
- Korean and English localization keys from the first implementation;
- number formatting independent of hard-coded language strings.

SpriteKit interaction should expose an accessible fallback action for manual impact and current weak point when VoiceOver is active.

## 16. Analytics and debug instrumentation

Analytics is optional in production but event hooks should exist behind a protocol.

Useful events:

- onboarding step completion;
- equipment purchase and level milestone;
- layer entry;
- resonance collection and expiry;
- session active/idle split;
- offline reward duration;
- prestige depth, run duration, and reward;
- point at which a player exits a run.

Never make simulation behavior depend on analytics availability.

Developer overlay:

- current simulation tick rate;
- stable DPS and manual impact;
- segment seed and health;
- active multipliers;
- power and heat calculations;
- force resonance;
- jump to layer;
- grant ore;
- preview prestige;
- export current save.

Debug controls must be excluded from release UI.

## 17. Tests

### 17.1 Unit tests

Required deterministic coverage:

- `LargeNumber` normalization, arithmetic, formatting, and Codable;
- geometric equipment cost and max-affordable quantity;
- production calculation by equipment and milestone;
- damage stage transitions;
- weak-point critical and bounded chain traversal;
- power enable/disable constraints;
- heat and overdrive transitions;
- segment generation repeatability;
- resonance weighted selection under fixed seed;
- layer transitions;
- prestige reward and reset boundary;
- save round trip and migration;
- offline cap, aggregation, and layer crossing.

### 17.2 Integration tests

- fresh install through first equipment purchase;
- segment break advances depth and grants the expected reward;
- purchase updates simulation and visible scene stage;
- background-save-relaunch applies exactly one offline transaction;
- prestige clears run state and preserves permanent state;
- corrupt primary save recovers from backup.

### 17.3 UI tests

Once stable deterministic launch arguments exist:

```text
--ui-fresh-install
--ui-midgame-crystal-layer
--ui-offline-summary
--ui-prestige-ready
--ui-reduce-motion
```

Use seeded fixtures rather than real elapsed waiting.

UI assertions:

- key HUD labels are visible;
- purchase panel exposes price and disabled reason;
- offline summary can be dismissed;
- first prestige can be completed;
- Korean strings do not clip on supported phone sizes.

## 18. Continuous integration

CI cannot be implemented until the Xcode project, scheme, and bundle identifier exist in the repository.

After source import, add `.github/workflows/ios.yml` with:

- macOS GitHub-hosted runner;
- printed Xcode and SDK versions;
- package resolution where needed;
- unsigned simulator build using `CODE_SIGNING_ALLOWED=NO`;
- dynamically resolved available iPhone simulator;
- unit tests with `.xcresult`;
- uploaded build/test logs with `if: always()`;
- concurrency cancellation;
- least-privilege permissions;
- path filtering so documentation-only changes do not consume simulator minutes unnecessarily.

A green workflow is required before declaring a code milestone complete.

## 19. Performance budget

Initial technical targets:

- stable interaction on the lowest supported device;
- no simulation result variance by display refresh rate;
- no unbounded SpriteKit node accumulation;
- bounded particles and floating labels;
- no synchronous disk writes during rapid input;
- scene assets loaded before gameplay or asynchronously outside the input path;
- save file small enough for immediate decode;
- offline calculation completes without replaying each missed frame or attack.

Instrument node count, update duration, allocation spikes, and save duration in debug builds.

## 20. Removal plan for Pomodoro architecture

After the imported baseline builds and is tagged:

1. identify timer/session domain models;
2. remove focus and break scheduling from the root state;
3. remove productivity history and streak calculations;
4. remove focus notification categories and pending requests;
5. remove timer-specific Live Activity, widgets, or intents unless reused for a future game feature;
6. remove onboarding and settings tied to focus duration;
7. remove App Store/localization strings describing productivity;
8. retain generic infrastructure only when it serves game lifecycle, sound, haptics, persistence, or navigation;
9. add a compile-time search gate for old terminology;
10. verify no focus-state dependency remains in save startup.

Suggested search terms:

```text
pomodoro
focus
break
session
streak
productivity
timerDuration
focusDuration
breakDuration
```

Terms may have legitimate generic uses; each result must be reviewed rather than mass-deleted.

## 21. Technical completion gates

A code release candidate is ready when:

- the repository builds from a clean checkout;
- deterministic game-core tests pass;
- source contains no mandatory Pomodoro progression path;
- live and offline simulation produce consistent economy results;
- save migration and backup recovery are tested;
- active input, equipment purchase, layer transitions, and prestige work end to end;
- SpriteKit node count remains bounded during extended play;
- Korean and English primary screens pass layout review;
- CI artifacts contain build logs, test logs, and `.xcresult`;
- remaining real-device checks are documented separately from simulator validation.
