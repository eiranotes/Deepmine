# DeepMine Product Specification

> Status: implementation baseline
> Pivot: Pomodoro/focus utility -> native idle clicker game
> Target platform: iPhone first

## 1. Product decision

DeepMine no longer treats focus time as the source of progression. The timer, focus session, break session, streak, productivity history, and notification-led return loop are removed from the product proposition.

The retained identity is:

- an underground mine that visibly expands downward;
- direct interaction with rock, fractures, ore, and machinery;
- idle production that continues while the app is closed;
- short active interventions that multiply automated production;
- repeated mine collapse and reconstruction through prestige.

The player-facing sentence is:

> Break rock, multiply machinery, and turn a narrow shaft into a self-running excavation system.

## 2. Design pillars

### 2.1 Visible accumulation

Every meaningful purchase must alter the mine scene, not only a number in the HUD.

Examples:

- a drill head appears and rotates;
- conveyors carry ore out of the shaft;
- support braces, cooling pipes, scanners, and power cables are added;
- deeper layers change rock silhouettes, particles, lighting, and impact behavior;
- prestige changes the starting rig and permanently modifies the shaft.

### 2.2 Active play amplifies idle play

Automation owns the baseline economy. Direct input creates temporary acceleration, targeting advantages, and chain reactions.

The player should never need continuous high-frequency tapping to maintain normal progress. Tapping remains useful because it exposes weak points, charges impact, and triggers events.

### 2.3 One-screen comprehension

The main loop must remain understandable from the primary excavation screen:

1. damage the current rock;
2. collect ore;
3. buy equipment;
4. descend;
5. reach the core;
6. collapse and rebuild stronger.

Systems that require separate management dashboards are excluded from the first release.

### 2.4 Progressive complexity

The first layer teaches damage and purchasing. New rules arrive one at a time through depth:

- fracture chains;
- critical weak points;
- heat and cooling;
- power capacity;
- timed pressure layers;
- prestige and permanent research.

## 3. Core loop

```text
Tap rock / trigger weak point
        ↓
Deal impact damage
        ↓
Break a rock segment
        ↓
Receive ore and depth progress
        ↓
Buy or upgrade machinery
        ↓
Increase automatic damage and event efficiency
        ↓
Enter a new geological layer
        ↓
Reach an unstable core
        ↓
Collapse the mine for Core Shards
        ↓
Unlock permanent research and restart faster
```

## 4. Session structure

### 4.1 Immediate loop: 1-10 seconds

- tap the central rock face;
- see a crack, hit flash, debris, damage number, and haptic response;
- collect a burst of ore when the segment breaks;
- react to a temporary weak point or resonance node.

### 4.2 Purchase loop: 10-90 seconds

- accumulate enough ore for the next visible machine or upgrade;
- compare the production gain before buying;
- install the purchase directly into the mine scene;
- see ore-per-second and break speed increase.

### 4.3 Layer loop: several purchases

- clear a fixed number of rock segments;
- cross a depth threshold;
- transition to a new layer with one new rule and one new equipment family;
- receive a concise layer introduction rather than a modal tutorial sequence.

### 4.4 Prestige loop

- reach an unstable core;
- choose to continue extracting or collapse immediately;
- convert run performance into Core Shards;
- reset temporary progression;
- purchase permanent research;
- start with a visibly improved rig.

First prestige balance target: reachable in the first substantial play session, approximately 45-90 minutes of mixed active and idle play. This is a tuning target, not a hard timer.

## 5. Player input

### 5.1 Standard tap

A tap applies `manualImpact` to the active rock segment.

Feedback order:

1. immediate deformation or crack change;
2. short impact sound;
3. localized debris;
4. compact damage number;
5. light haptic, with stronger haptic on break or critical hit.

### 5.2 Combo pressure

Consecutive taps inside a short rolling window fill an Impact Meter.

- meter decays instead of resetting instantly;
- full meter releases a radial fracture wave;
- fracture wave damages the current segment and reveals weak points;
- upgrades can change wave size, reward, and cooldown.

The meter prevents raw taps-per-second from being the only active-play skill.

### 5.3 Weak points

Weak points appear on rock geometry for a limited period.

- tapping the correct point applies critical damage;
- nearby fractures can chain into secondary breaks;
- scanners increase visibility time and appearance rate;
- weak points remain optional and never stop idle production.

### 5.4 Hold interaction

Press-and-hold temporarily overdrives the primary drill after it is unlocked.

- overdrive increases damage;
- heat rises during overdrive;
- release or cooling reduces heat;
- overheating creates a recovery period unless a related modification changes the behavior.

Tap and hold have distinct purposes: tap targets fractures; hold controls machine overdrive.

## 6. Resources

The first release uses two currencies and one capacity constraint.

### 6.1 Ore

Temporary run currency.

Used for:

- equipment levels;
- support systems;
- run-specific modifications;
- layer unlock requirements where needed.

Ore resets on collapse.

### 6.2 Core Shards

Permanent prestige currency.

Used for:

- permanent research;
- starting equipment;
- global multipliers;
- new layer variants;
- automation quality-of-life unlocks.

Core Shards persist through collapse.

### 6.3 Power

Power is capacity, not a third spendable currency.

Each installed system consumes power. Generators increase capacity. This creates equipment choices without adding another inventory economy.

```text
Power: 18 / 20
Primary Drill       6
Fracture Hammer     4
Ore Scanner         3
Cooling Loop        5
```

A device can be disabled to free capacity. Later research may allow controlled overload.

## 7. Rock and depth model

### 7.1 Segment model

The shaft is divided into discrete rock segments. Each segment has:

- `depthIndex`;
- `layerID`;
- `maxHealth`;
- `currentHealth`;
- `oreReward`;
- weak-point seed;
- optional modifier;
- visual damage stage.

A segment break advances depth and generates the next deterministic segment.

### 7.2 Baseline scaling

Initial tuning formulas:

```text
segmentHealth(d) = layerHealthBase × 1.155^d × healthModifier
oreReward(d)     = layerOreBase    × 1.145^d × rewardModifier
```

`d` is the segment index within the current balancing band, not raw meters. Scaling is piecewise by layer so that designers can control difficulty spikes.

The health growth rate intentionally exceeds reward growth. Equipment milestones, critical play, and prestige research recover the gap.

### 7.3 Depth presentation

Depth is presented in meters for theme, while the economy uses segment indices internally.

One segment can represent a configurable meter interval. This avoids coupling display units to balance formulas.

## 8. Geological layers

| Layer | Approximate band | Primary rule | New visual language | Unlock |
|---|---:|---|---|---|
| Sediment | 0-100 m | basic break and purchase | loose soil, small stones | starter drill |
| Granite | 100-300 m | fracture chains | large angular slabs | fracture hammer |
| Crystal Vein | 300-600 m | target weak points | embedded crystals, refraction | ore scanner |
| Hydrothermal | 600-1,000 m | heat and cooling | steam, wet rock, orange seams | cooling loop |
| Compression Zone | 1,000-1,500 m | timed pressure windows | compressed bands, screen vibration | pressure stabilizer |
| Deep Anomaly | 1,500 m+ | rotating rule combinations | dark mineral, abnormal glow | anomaly research |

Each new layer introduces only one mandatory mechanic. Existing mechanics continue to interact with it.

## 9. Equipment families

### 9.1 Primary excavation

- Rotary Drill: stable automatic damage;
- Fracture Hammer: burst damage at intervals;
- Thermal Bore: high output with heat management;
- Plasma Cutter: late-run penetration multiplier;
- Autonomous Swarm: many small hits that interact with critical effects.

### 9.2 Support systems

- Ore Scanner: weak-point frequency and lifetime;
- Conveyor: reward transfer and break reward multiplier;
- Cooling Loop: heat reduction and overdrive duration;
- Power Generator: equipment capacity;
- Compression Brace: pressure-zone stability;
- Resonance Amplifier: event strength and chain count.

### 9.3 Equipment purchase rule

Every equipment family has:

- base cost;
- geometric cost growth;
- base production or utility value;
- level milestones;
- visible scene stages.

Suggested cost model:

```text
cost(level, count) = baseCost × growth^level
```

Initial growth bands:

- primary equipment: `1.14-1.17`;
- support equipment: `1.18-1.22`;
- generator capacity: hand-authored milestone costs.

### 9.4 Milestones

At levels 10, 25, 50, 100, and later bands, equipment receives a meaningful multiplier or behavior change.

A milestone should be visually announced and should materially shorten current segment clear time.

## 10. Modifications

Run-specific modifications change behavior rather than supplying only flat percentages.

Examples:

- every twentieth manual hit releases a fracture wave;
- critical hits propagate to adjacent fracture nodes;
- overheating causes an explosion before recovery;
- active production rises while offline efficiency falls;
- weak points last longer but appear less frequently;
- disabled support machines retain part of their passive bonus;
- power overload is allowed, adding periodic shutdown risk;
- conveyor capacity converts excess break damage into bonus ore.

Modification slots are limited. The player selects a build rather than collecting every effect in one run.

## 11. Resonance events

Resonance Nodes replace the role of a golden-cookie event.

A node appears inside the current rock for a short time. Tapping it selects one event from a weighted deterministic table.

Possible events:

- automatic damage multiplied for 30 seconds;
- manual hits become critical;
- current segment partially collapses;
- a rare ore seam appears;
- heat is cleared and overdrive becomes free temporarily;
- a chain of smaller nodes begins;
- conveyor output surges;
- all active equipment synchronizes for a combined strike.

Event goals:

- provide a reason to watch the mine without requiring constant attention;
- create visible production spikes;
- combine with modifications and equipment rather than existing as isolated rewards.

## 12. Prestige: controlled collapse

### 12.1 Trigger

At a core threshold, the shaft becomes unstable. The player may collapse immediately or continue for a higher risk/reward extraction band.

### 12.2 Reward formula

Initial prototype formula:

```text
Core Shards = floor(
    (lifetimeOreThisRun / 1,000,000)^0.35
    + maxDepthMeters / 500
    + coresExtracted × 2
)
```

The final formula must be balance-tested with generated simulations. It must satisfy:

- first collapse grants at least one meaningful purchase;
- delaying collapse has a visible but diminishing benefit;
- no single variable dominates every run;
- repeated early resets do not outperform reaching intended depth milestones.

### 12.3 Reset boundary

Reset:

- ore;
- temporary equipment levels;
- current depth and layer;
- run modifications;
- temporary events and heat.

Persist:

- Core Shards;
- permanent research;
- lifetime statistics;
- settings and accessibility;
- unlocked cosmetic scene variants;
- tutorial completion flags.

### 12.4 Permanent research branches

**Excavation**

- starting manual impact;
- automatic damage multiplier;
- equipment milestone strength;
- starting drill level.

**Discovery**

- weak-point frequency;
- resonance event duration;
- rare layer variants;
- better modification choices.

**Infrastructure**

- starting power capacity;
- offline efficiency;
- automatic purchase unlock;
- elevator skip to previously mastered bands.

The initial tree should remain small enough that every purchase has an observable effect.

## 13. Offline progression

### 13.1 Rules

- default offline cap: 8 hours;
- initial efficiency: 35% of current stable automatic production;
- manual, resonance, temporary overdrive, and probabilistic chain effects are excluded;
- permanent research can raise efficiency and cap;
- negative elapsed time yields zero progress;
- elapsed time beyond the cap is ignored.

### 13.2 Return presentation

On foregrounding, display a compact bottom sheet:

```text
While away: 3 h 24 m
Ore mined: 184.2K
Segments cleared: 12
Current depth: 438 m
```

The sheet must not block immediate play for more than one tap and must be dismissible by tapping the mine.

## 14. Main screen specification

### 14.1 Layout

```text
┌──────────────────────────────┐
│ Depth 327 m     Ore 18.4K    │
│ Layer: Crystal  +432 / sec   │
├──────────────────────────────┤
│                              │
│       ACTIVE ROCK FACE       │
│ weak points / cracks / drill │
│                              │
│ machinery and conveyor path  │
├──────────────────────────────┤
│ Impact meter   Heat   Power  │
├──────────────────────────────┤
│ Upgrade      Loadout     Core│
└──────────────────────────────┘
```

### 14.2 Information priority

Always visible:

- current ore;
- stable ore per second;
- depth and layer;
- rock health state;
- active input feedback;
- enough power/heat information to explain blocked actions.

Secondary panels:

- equipment purchase list;
- modification loadout;
- prestige research;
- statistics and settings.

### 14.3 Upgrade panel

Each row shows:

- equipment name and current level;
- next visible effect;
- cost;
- projected production change;
- buy x1, x10, and max controls;
- next milestone level.

Avoid placing every statistic into independent cards. Use a compact equipment list with strong hierarchy.

## 15. Visual direction

### 15.1 Style

- pixel-based or low-resolution raster treatment;
- industrial mine rather than futuristic spaceship;
- restrained color palette with layer-specific accents;
- machinery silhouettes that remain legible at phone scale;
- limited bloom and neon;
- dark rock masses contrasted by ore, dust, lamps, and heat.

### 15.2 Motion

Continuous motion:

- drill rotation;
- conveyor travel;
- small dust drift;
- cooling and steam cycles.

Event motion:

- crack propagation;
- segment collapse;
- resonance pulse;
- layer transition;
- prestige collapse.

Routine UI transitions should remain short. Large collapse sequences may be longer but skippable after the first view.

### 15.3 Audio and haptics

- impacts use a small randomized family, not one repeated sample;
- machine layers fade in as equipment becomes visible;
- ore break has a clear completion sound;
- resonance events use a distinct frequency cue;
- haptics scale from tap to critical to segment collapse;
- independent music, SFX, and haptic toggles.

## 16. Onboarding

The tutorial is embedded in the first depth band.

1. pulse the rock face until the first tap;
2. break the first segment;
3. highlight the affordable starter drill;
4. show automatic damage;
5. introduce one weak point;
6. end guided interaction.

Power, heat, modifications, and prestige are explained only when first encountered.

No productivity or focus-app language remains in onboarding, App Store copy, notifications, achievements, or settings.

## 17. Scope boundaries

Not included in the first complete playable release:

- worker or character collection;
- multiple simultaneous mines;
- crafting recipes and refinery chains;
- social guild systems;
- competitive leaderboards;
- live-service events;
- narrative quest chains;
- equipment gacha;
- mandatory advertising loops;
- cloud synchronization unless local stability is complete.

These systems can be reconsidered only after the excavation loop, first prestige, and return loop are demonstrably engaging.

## 18. Product acceptance criteria

The pivot is product-complete when:

- a new player understands the main loop without reading a manual;
- the first machine is purchased shortly after the initial taps;
- every equipment family has a visible scene representation;
- idle progress works after background termination and relaunch;
- active weak-point and resonance play materially outperforms passive watching without being mandatory;
- at least five geological rules are playable;
- prestige resets the correct state and produces a faster second run;
- no Pomodoro, focus-session, break-session, streak, or productivity-history dependency remains;
- the game can be played from installation through first prestige without debug intervention.
