# DeepMine Implementation Backlog

> Execution order for the Pomodoro-to-idle-clicker pivot
> Task status at creation: not started

## 1. Delivery strategy

Implementation proceeds through vertical slices. Each milestone must leave a runnable application rather than a collection of disconnected systems.

Order:

```text
Repository baseline
→ deterministic game core
→ first playable mine
→ automation and purchasing
→ persistence and offline progress
→ layers and active events
→ prestige
→ content, polish, and release validation
```

Do not begin broad content production before the first playable slice proves that tap, break, purchase, automation, save, and relaunch work together.

## 2. Global definition of done

A task is complete only when applicable items are satisfied:

- implementation is committed on a task branch;
- deterministic logic has unit tests;
- the application builds in GitHub Actions;
- user-visible changes are exercised in the Simulator;
- data format changes include migration handling;
- no unrelated project settings or identifiers are changed;
- Korean and English strings are provided for new primary UI;
- debug-only behavior is excluded from Release builds;
- documentation is updated when behavior differs from the product specification.

## 3. Milestone M0 — Repository and pivot baseline

**Goal:** place the current local app under version control, preserve a recoverable pre-pivot state, and establish build validation.

### M0-01 Import current source

- commit the current Xcode project/workspace;
- include source, assets, localization, tests, and package lock/resolution files;
- exclude DerivedData, user schemes, credentials, and signing artifacts;
- confirm the default branch contains a reproducible baseline.

**Done when:** a clean checkout opens without missing file references.

### M0-02 Record project facts

Add `docs/CURRENT_PROJECT_AUDIT.md` containing:

- project/workspace path;
- app target and shared scheme;
- bundle identifier;
- deployment target;
- Swift and UI frameworks in use;
- current persistence mechanism;
- current Pomodoro domain files;
- current tests and workflows;
- reusable visual/audio assets;
- migration implications for any released build.

**Done when:** every later task can name real files rather than inferred paths.

### M0-03 Preserve pre-pivot state

- create a tag or archival branch for the last working Pomodoro version;
- record the exact commit in the audit;
- do not keep duplicate legacy files inside the new app target.

**Done when:** the old product can be restored without contaminating new implementation.

### M0-04 Add iOS CI

- create a macOS GitHub Actions workflow;
- discover or validate the shared scheme;
- build unsigned for iOS Simulator;
- run existing tests;
- upload logs and `.xcresult`;
- cancel superseded branch runs;
- skip expensive jobs for documentation-only changes where safe.

**Done when:** the imported baseline has a completed successful run.

### M0-05 Remove product-language dependency

- inventory focus, Pomodoro, break, streak, session, and productivity strings;
- mark each source file as delete, rewrite, or infrastructure reuse;
- disable new development on the old focus loop.

**Done when:** removal scope is explicit and no new feature depends on timer state.

## 4. Milestone M1 — Deterministic game core

**Goal:** implement game-state and economy logic without relying on UI or SpriteKit.

### M1-01 Create large-number type

Implement:

- normalized mantissa/exponent storage;
- zero and sign validation;
- comparison;
- addition, subtraction, multiplication, division, and power;
- compact formatting;
- Codable support.

**Tests:** normalization boundaries, magnitude addition, geometric growth, invalid values, serialization.

### M1-02 Define state model

Implement:

- `GameState`;
- `RunState`;
- `PermanentState`;
- settings and lifetime statistics;
- stable IDs for equipment, layers, modifications, and research.

**Done when:** a fresh state can be created, copied, compared, encoded, and decoded.

### M1-03 Add content catalogs

Create initial definitions for:

- Sediment and Granite layers;
- starter drill, fracture hammer, conveyor, scanner, and generator;
- basic milestone tables;
- initial permanent research nodes;
- two run modifications.

**Done when:** economy code reads definitions from catalogs and views do not own balance constants.

### M1-04 Implement segment generation

- deterministic seed composition;
- segment health and reward calculation;
- weak-point graph generation;
- damage stage thresholds;
- next-segment generation.

**Tests:** same seed produces same segment; different depth changes expected values; weak points remain inside normalized bounds.

### M1-05 Implement damage resolution

- manual impact;
- stable automatic DPS;
- critical weak-point multiplier;
- bounded fracture chains;
- overkill handling;
- segment break reward and depth advance.

**Done when:** command sequences produce exact expected state transitions in tests.

### M1-06 Implement purchase calculations

- x1, x10, and max purchase;
- geometric-series pricing;
- milestone application;
- power requirement validation;
- projected production output.

**Tests:** affordability boundaries, milestone crossing, power-disabled purchase, max quantity at large values.

### M1-07 Add fixed-step simulation

- fixed simulation cadence;
- command queue;
- scheduled automatic attacks;
- event output;
- foreground delta clamp;
- no renderer dependency.

**Done when:** the same commands and elapsed time produce identical results at different render frame rates.

## 5. Milestone M2 — First playable excavation slice

**Goal:** produce a runnable screen where the player can break rock and buy one visible automatic machine.

### M2-01 Replace root product flow

- remove timer-first navigation;
- launch directly into the mine;
- replace focus onboarding with embedded game onboarding;
- retain generic settings infrastructure where useful.

**Done when:** no focus session is required to reach gameplay.

### M2-02 Build MineScene shell

- integrate SpriteKit inside SwiftUI;
- create background, shaft, rock, machinery, effects, interaction, and debug layers;
- connect normalized touch coordinates to `GameStore`;
- render deterministic segment variants.

**Done when:** a fresh segment is visible and accepts input on supported phone layouts.

### M2-03 Implement rock hit feedback

- damage-stage texture or overlay transitions;
- localized hit flash;
- debris pool;
- compact damage numbers;
- impact sound pool;
- throttled light haptic.

**Done when:** rapid tapping does not create unbounded nodes or audio players.

### M2-04 Implement segment collapse

- stop accepting hits after lethal damage;
- play bounded collapse sequence;
- grant reward once;
- advance depth once;
- replace rock with next segment;
- update HUD and layer metadata.

**Tests:** repeated input during collapse cannot duplicate rewards.

### M2-05 Implement top HUD

Display:

- ore;
- ore per second;
- depth;
- layer;
- rock health state.

**Done when:** displayed values are driven by render snapshots rather than duplicated formulas.

### M2-06 Add starter purchase panel

- show starter drill level, cost, output gain, and milestone;
- support x1 and max purchase initially;
- install visible drill stages at defined levels;
- display insufficient-ore reason.

**Milestone acceptance test:** fresh install -> tap rock -> break segments -> buy drill -> observe automatic damage -> relaunch without a crash.

## 6. Milestone M3 — Automation, power, and active control

**Goal:** create the core interaction between idle production and short active interventions.

### M3-01 Add complete initial equipment set

Implement the first playable versions of:

- Rotary Drill;
- Fracture Hammer;
- Conveyor;
- Ore Scanner;
- Generator;
- Cooling Loop placeholder if heat is not yet active.

Every family requires a visible scene representation.

### M3-02 Implement power capacity

- calculate usage and capacity;
- block or disable equipment when necessary;
- allow player-controlled enable/disable;
- show compact power strip;
- explain disabled production in the equipment panel.

**Tests:** capacity boundaries, generator upgrade, disabled equipment output, state persistence.

### M3-03 Add Impact Meter

- rolling tap window;
- decay;
- full-meter fracture wave;
- event and visual feedback;
- research hooks.

**Done when:** active play raises output without requiring a fixed taps-per-second gate.

### M3-04 Add weak-point interaction

- scanner-adjusted appearance;
- normalized target hit testing;
- timed lifetime;
- critical and chain resolution;
- expiry without penalty.

**Tests:** correct point, incorrect point, expired point, chain bound, fixed-seed generation.

### M3-05 Add press-and-hold overdrive

- begin/end commands;
- output multiplier;
- heat accumulation placeholder or full heat model;
- release behavior;
- interruption handling when app backgrounds.

**Done when:** a touch cancellation cannot leave overdrive permanently active.

### M3-06 Complete purchase panel controls

- x1, x10, max;
- projected output;
- next milestone;
- disabled reasons;
- compact list hierarchy;
- no card grid for every statistic.

## 7. Milestone M4 — Persistence and offline progression

**Goal:** make progression reliable across backgrounding, termination, update, and relaunch.

### M4-01 Implement versioned save envelope

- file in Application Support;
- atomic replacement;
- previous backup;
- validation before acceptance;
- corruption recovery;
- debounced autosave.

### M4-02 Add schema migration framework

- explicit current format version;
- sequential migration functions;
- fixture-based tests;
- defaults for newly introduced fields.

### M4-03 Decide legacy Pomodoro migration

After source audit, implement one documented option:

- retain only generic settings;
- archive legacy data separately for one release;
- or explicit clean reset for unreleased/internal builds.

Do not convert focus time or streaks into game currency.

### M4-04 Implement offline calculator

- elapsed-time clamp;
- eight-hour initial cap;
- 35% initial efficiency;
- stable automatic production only;
- batched segment crossing;
- layer crossing;
- exactly-once application.

### M4-05 Add offline summary

- duration;
- ore earned;
- segments cleared;
- resulting depth;
- one-tap dismissal;
- save result before presentation.

### M4-06 Lifecycle integration

- save on background;
- stop rendering/audio;
- clear unsafe held-input state;
- apply offline transaction once on foreground;
- resume fixed-step simulation.

**Milestone acceptance test:** progress -> terminate app -> alter no debug state -> relaunch -> receive correct capped reward -> dismiss summary -> continue from resulting segment.

## 8. Milestone M5 — Geological progression and resonance

**Goal:** turn the first slice into a multi-layer game with escalating mechanics.

### M5-01 Granite layer

- fracture-chain rule;
- new rock silhouettes and debris;
- fracture hammer unlock;
- layer transition sequence.

### M5-02 Crystal Vein layer

- scanner-focused weak points;
- crystal visual accents;
- rare seam reward variant;
- scanner scene stages.

### M5-03 Hydrothermal layer

- full heat model;
- cooling loop;
- steam and thermal visuals;
- overheat recovery;
- heat-related modification hooks.

### M5-04 Compression Zone

- pressure windows;
- stability state;
- pressure brace;
- timed but non-blocking layer rule;
- Reduce Motion alternative to heavy shaking.

### M5-05 Deep Anomaly baseline

- deterministic combination of prior rules;
- anomaly visual set;
- bounded modifier combinations;
- no combination may halt idle production indefinitely.

### M5-06 Resonance Nodes

- spawn schedule and weighted table;
- collection and expiry;
- initial event set;
- event banner and scene pulse;
- analytics hooks;
- fixed-seed tests.

Initial event set:

- automatic damage surge;
- manual critical window;
- partial collapse;
- rare ore seam;
- free overdrive/cooling;
- chained nodes.

### M5-07 Layer content validation

For each layer verify:

- rule is introduced once;
- equipment unlock is affordable in intended progression;
- visual transition is distinct;
- offline calculation handles the layer;
- no text clips in Korean or English.

## 9. Milestone M6 — Modifications and build choice

**Goal:** add run-level decisions that change behavior without expanding into a refinery or worker-management game.

### M6-01 Modification model

- stable IDs;
- rarity or tier only if necessary;
- eligibility rules;
- limited slots;
- mutually exclusive definitions;
- save and reset boundary.

### M6-02 Choice presentation

- present a small choice set at defined depth milestones;
- show effect in plain numerical terms;
- allow confirmation;
- avoid blocking the mine during ordinary production.

### M6-03 Initial behavior-changing set

Implement and test at least:

- periodic fracture wave;
- chain-critical propagation;
- overheat explosion;
- active/offline tradeoff;
- long-lived weak points;
- power overload;
- excess-damage ore conversion.

### M6-04 Loadout screen

- active slots;
- effect summary;
- source/depth acquired;
- conflict explanation;
- no drag-and-drop requirement for first release.

## 10. Milestone M7 — Prestige and second-run acceleration

**Goal:** complete the idle-clicker meta loop.

### M7-01 Core-ready state

- detect core threshold;
- show instability without blocking continued extraction;
- calculate live projected Core Shards;
- prevent collapse command during invalid animation state.

### M7-02 Collapse sequence

- confirmation with reset summary;
- mine-wide animation;
- commit reward exactly once;
- reset `RunState`;
- preserve `PermanentState`;
- save immediately after transaction.

### M7-03 Permanent research

Initial branches:

- Excavation;
- Discovery;
- Infrastructure.

Each node requires:

- cost;
- prerequisite;
- level cap;
- exact effect;
- resulting value preview;
- tests for application and persistence.

### M7-04 Starting rig changes

Permanent upgrades must be visible through:

- starting equipment level;
- generator or shaft structure;
- initial break speed;
- unlocked elevator/skip state.

### M7-05 Balance simulation

Run automated scenarios for:

- passive first run;
- mixed active first run;
- immediate collapse at threshold;
- delayed collapse;
- second and third runs;
- offline-heavy play;
- aggressive active build;
- power-limited build.

Tune until:

- first prestige grants a meaningful purchase;
- second run is visibly faster;
- repeated shallow resets do not dominate;
- no layer produces an unexplained progression wall.

**Milestone acceptance test:** installation -> first prestige -> research purchase -> second run reaches an early milestone faster, with correct save/relaunch behavior.

## 11. Milestone M8 — Content, polish, and release gate

**Goal:** convert the complete loop into a stable release candidate.

### M8-01 Finalize visual asset pipeline

- texture atlases;
- layer palettes;
- rock damage stages;
- machinery scene stages;
- pooled particles;
- icon and launch assets;
- no temporary debug art in release target.

### M8-02 Finalize audio and haptics

- impact variation;
- machinery loops;
- layer ambience;
- critical, break, resonance, and collapse cues;
- interruption handling;
- independent toggles.

### M8-03 Accessibility pass

- Dynamic Type panels;
- VoiceOver values and actions;
- non-color state indicators;
- Reduce Motion behavior;
- reduced flash option where needed;
- accessible manual-impact fallback.

### M8-04 Localization pass

- Korean and English coverage;
- compact number grammar;
- long-string testing;
- remove all obsolete productivity copy;
- verify notification and settings text.

### M8-05 Extended stability tests

- repeated rapid tapping;
- long unattended foreground session;
- repeated background/foreground cycles;
- app termination during segment collapse;
- app termination during prestige transaction;
- corrupt save recovery;
- high-number formatting;
- equipment max-purchase at late levels;
- node and particle count monitoring.

### M8-06 Store and product cleanup

- rewrite app description, screenshots, keywords, and onboarding around the game;
- remove focus/Pomodoro privacy declarations and capabilities that are no longer used;
- retain only required background modes and notification usage;
- validate bundle settings and entitlements;
- decide monetization separately from the core economy.

### M8-07 Release candidate validation

Required evidence:

- clean checkout build;
- successful CI build and tests;
- Simulator screenshots for fresh, midgame, offline summary, and prestige-ready states;
- visual review of screenshots;
- real-device input, audio, haptic, thermal, and lifecycle check;
- documented known limitations;
- no open data-loss or duplicate-reward defects.

## 12. Cross-cutting work queue

### BAL — Balance

- BAL-01 create progression simulation output;
- BAL-02 establish first-purchase target;
- BAL-03 establish layer transition bands;
- BAL-04 tune active/passive production ratio;
- BAL-05 tune offline efficiency;
- BAL-06 tune first prestige;
- BAL-07 tune second-run acceleration;
- BAL-08 test extreme-number stability.

### ART — Art

- ART-01 visual scale and pixel grid specification;
- ART-02 Sediment rock set;
- ART-03 Granite rock set;
- ART-04 Crystal rock set;
- ART-05 Hydrothermal rock set;
- ART-06 Compression and anomaly sets;
- ART-07 machinery stage sprites;
- ART-08 fracture overlays and weak points;
- ART-09 collapse and resonance effects;
- ART-10 UI icons and store assets.

### AUD — Audio

- AUD-01 impact family;
- AUD-02 break family;
- AUD-03 machinery loops;
- AUD-04 layer ambience;
- AUD-05 resonance cues;
- AUD-06 prestige sequence;
- AUD-07 mix and interruption validation.

### QA — Quality

- QA-01 deterministic economy suite;
- QA-02 persistence fixtures;
- QA-03 offline matrix;
- QA-04 lifecycle stress test;
- QA-05 accessibility matrix;
- QA-06 localization screenshots;
- QA-07 lowest-device performance pass;
- QA-08 release regression checklist.

## 13. Explicitly deferred backlog

These tasks must not enter the critical path before M8:

- CloudKit sync;
- Game Center leaderboards;
- social or guild features;
- multiple mines;
- character collection;
- crafting and refinery chains;
- live events;
- ad-reward economy;
- subscriptions;
- server-authoritative saves;
- procedural narrative;
- Android or desktop ports.

## 14. First engineering issue set

After the current source is imported, create the first executable issue batch in this order:

1. audit actual project structure and reusable code;
2. restore green baseline CI;
3. define state and `LargeNumber`;
4. implement segment/damage/economy unit tests;
5. replace root timer flow with MineScene shell;
6. deliver tap -> break -> reward;
7. deliver purchase -> visible automatic drill;
8. add versioned save and relaunch;
9. add offline reward;
10. add first layer transition.

Do not split these into dozens of UI-only tickets before the vertical slice is running.
