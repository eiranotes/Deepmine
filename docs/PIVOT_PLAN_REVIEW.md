# Pivot Plan Review

> Reviews `PRODUCT_SPEC.md`, `TECHNICAL_PLAN.md`, and `IMPLEMENTATION_BACKLOG.md`
> against the stated project constraint: **reuse as much of the existing app as possible.**

## 1. What this review can and cannot say

This review was written **without access to the DeepMine source code**. The repository
contains documentation only, and the local Xcode project has never been pushed
(see `SOURCE_IMPORT.md`).

So this document deliberately does not attempt the file-by-file comparison the pivot needs.
It cannot: naming specific files, estimating removal effort, or declaring what is reusable
would all be invention. That comparison is `CURRENT_PROJECT_AUDIT.md`, and it stays blank
until the source lands.

What *can* be reviewed without the code is the plan's internal reasoning: which parts hold
regardless of what the audit finds, which parts assume facts nobody has checked, and which
parts conflict with the reuse-first constraint. That is the scope here.

## 2. What the existing plan gets right

These parts need no revision and should be treated as settled:

- **Simulation/rendering separation.** Economy on a fixed step (10 Hz), visuals on the
  display refresh rate. This is the single most valuable architectural decision in the plan.
  Idle games that skip it end up with progression that varies by device refresh rate, and
  retrofitting the separation later means rewriting the economy.
- **Deterministic segment generation from a seed.** Makes the economy testable and makes
  offline progress consistent with live progress. Correct.
- **Offline progress computed in aggregate, never by replaying ticks.** Correct, and the
  eight-hour cap / 35% efficiency starting values are reasonable.
- **Command-based mutation.** Enables replayable tests and a debug overlay cheaply.
- **Catalog-driven content** rather than balance constants scattered through views.
- **The "exactly once" concerns** — one offline transaction per foreground, one reward per
  segment break, one prestige commit. These are where idle games actually lose player
  progress, and the plan names them explicitly at M2-04, M4-04, and M7-02.
- **Product scope discipline.** The deferred list (§13 of the backlog) correctly keeps
  gacha, guilds, and live events off the critical path.

The product specification is in good shape overall. Most of the revision below is technical
and sequencing, not design.

## 3. The central tension: the plan is written as a rewrite

The project constraint is maximum reuse of existing work. The technical plan is not written
that way, and this shows up in three places:

**§3 proposes a complete greenfield module tree.** Nine top-level groups, roughly forty
named files, none of which reference anything that exists. A reuse-first plan starts from
the project's real layout and names what moves; this one starts from an ideal layout and
implies everything is new.

**§20 is titled "Removal plan for Pomodoro architecture"** and is a ten-step deletion
sequence. Reuse appears once, as step 8: "retain generic infrastructure only when it serves
game lifecycle, sound, haptics, persistence, or navigation." That clause is doing a large
amount of work for one line in a deletion checklist. Under a reuse-first constraint the
inverse framing is the useful one — inventory what carries over first, and let deletion be
whatever is left after.

**The backlog's M1 rebuilds foundations that may already exist.** M1-01 through M1-07
implement a number type, a state model, persistence-shaped types, and a simulation loop as
if from zero. Some of that genuinely is new — the economy did not exist in a Pomodoro app.
But persistence, settings, and lifecycle handling plausibly do exist in some form, and the
backlog does not pause to check before rebuilding.

**This is a framing problem, not a correctness problem.** The plan's target architecture is
sound. The issue is that it arrives at that architecture by construction rather than by
migration, so it gives no guidance on the actual question — how much of the existing app
survives. That guidance requires the audit.

## 4. Open decisions the plan states as settled

Each of these is presented as a conclusion in the current documents but is really a decision
awaiting the audit. Recording them here so they get made deliberately.

### 4.1 SpriteKit for the mine scene

`TECHNICAL_PLAN.md` §1 lists SpriteKit as a baseline assumption, and §9 specifies a full node
hierarchy and performance rules for it.

The concern: if the existing app is pure SwiftUI — likely for a Pomodoro timer — then
SpriteKit is a **new** framework, new build surface, and new set of integration bugs
(`SpriteView` lifecycle, touch coordinate translation, scene teardown on backgrounding). That
is the opposite of reuse, adopted before anyone confirmed it was needed.

The alternative worth pricing: SwiftUI `Canvas` + `TimelineView` can render a rock face,
damage-stage overlays, floating damage numbers, and modest particle counts. It reuses the
existing view layer, and the fixed-step simulation the plan already mandates means the
renderer is swappable — the economy does not know or care what draws it.

Where SpriteKit genuinely wins is high particle counts, texture atlases, and node pooling
during rapid tapping. Those matter at M8 polish scale, not at M2 first-playable scale.

**Recommendation:** build the M2 slice on SwiftUI Canvas if the app is already SwiftUI.
Revisit at M5, when layer effects and particle load are real and measurable. The
simulation/rendering split the plan already requires is exactly what makes deferring this
decision cheap — which is an argument the plan could make for itself but does not.

### 4.2 `LargeNumber` as an M1-01 blocker

The plan makes a custom mantissa/exponent type the very first implementation task, ahead of
the state model and the playable slice.

`Double` holds values to ~1.8e308 with 15–17 significant digits. An idle game only needs
more than that when prestige multipliers compound past 1e308, which is deep late-game — many
releases never reach it, and DeepMine's first release certainly will not.

Building and testing a custom numeric type (normalization, arithmetic, powers, comparison,
formatting, Codable round-trips) before the game is playable inverts the priority order the
backlog itself argues for in §1: "Do not begin broad content production before the first
playable slice proves that tap, break, purchase, automation, save, and relaunch work
together." The same reasoning applies to infrastructure.

**Recommendation:** define the type name immediately, back it with `Double`, and confine the
implementation behind it.

```swift
struct GameNumber: Codable, Comparable, Hashable {
    private var value: Double
    // Arithmetic, comparison, and compact formatting go through here.
    // Callers never touch `value` directly.
}
```

Every call site is then already written against `GameNumber`, and swapping the backing
storage for mantissa/exponent later is an internal change with no diff outside this file.
The compact formatting (`1.23K`, `4.56M`) and the no-NaN/no-negative validation rules from
§6 of the technical plan should be implemented now — those are needed from day one and are
independent of the storage question.

### 4.3 Persistence mechanism

`TECHNICAL_PLAN.md` §11 specifies a `Codable` envelope written atomically to Application
Support. That is a good design for a game save.

But if the existing app uses SwiftData or Core Data, "reuse" and "this design" pull in
different directions, and the plan does not acknowledge the fork. Worth being explicit: a
game state that is one large mutable object graph saved atomically is a poor fit for an ORM,
and the file-based envelope is the right call **even at the cost of discarding the existing
persistence layer**. Object-graph persistence buys queryability that a single game save has
no use for, and costs migration complexity that the save format will feel on every schema
change.

**Recommendation:** adopt the envelope design as specified. Reuse the existing layer only
for settings, if the audit shows a clean separation. This is one case where the reuse-first
constraint should lose, and it should lose on record rather than by accident.

## 5. Reuse inventory to build during the audit

The audit's §2.3 REUSE table is where the reuse-first constraint is actually satisfied.
Categories worth looking for specifically — a Pomodoro app plausibly has several of these,
and each one found is work the pivot does not repeat:

| Category | Why it survives the pivot |
|---|---|
| App lifecycle / background handling | A timer app must already handle background/foreground precisely. This is directly the offline-progress trigger, and it is fiddly code worth keeping. |
| Persistence scaffolding | File paths, atomic writes, backup handling — reusable even if the schema is discarded. |
| Settings infrastructure | Storage, screen, and toggles are domain-neutral. |
| Design system / theme | Colors, spacing, typography, component styles. Direct reuse in HUD and panels. |
| Haptics service | Generator preparation and throttling is the same problem for taps as for timer events. |
| Audio service | Pooled playback, interruption and route-change handling. The plan's §13.1 warning against per-tap player allocation is likely already solved here. |
| Localization infrastructure | String catalogs and the Korean/English pipeline. Keys change; the plumbing does not. |
| Notification infrastructure | Retained only if the deferred return-notification feature (technical plan §14) is wanted. Otherwise removal. |
| Onboarding scaffolding | Page/step flow reusable with new content. |
| Number and duration formatting | Partial — locale handling reusable, units change. |
| CI workflow | If one exists, it is a starting point rather than new work. |

A Pomodoro app is unlikely to contribute anything to the economy, the mine scene, or the
progression systems. Those are genuinely new. The reuse case is concentrated in the
infrastructure layer, which is also where the tedious, easy-to-underestimate work lives — so
a good result here is worth real audit time.

## 6. Revised sequencing

The backlog's milestone content is sound. The change proposed is to the order of M0 and M1,
so that the audit informs the build rather than running alongside it.

```text
M0  Import + audit + green CI on the UNCHANGED baseline
      ├─ push local source                        (SOURCE_IMPORT.md)
      ├─ tag v0-pomodoro-baseline
      ├─ fill CURRENT_PROJECT_AUDIT.md
      ├─ CI green on untouched code
      └─ resolve decisions in §4 above
              ↓
M0.5 Revise the plan against reality              ← NEW
      ├─ rewrite TECHNICAL_PLAN.md §3 to the real module layout
      ├─ rewrite §20 as reuse inventory first, deletion second
      └─ re-scope M1 to exclude what already exists
              ↓
M1  Game core — only the parts the audit confirms are missing
              ↓
M2  First playable slice   ← the real proof point
      tap → break → reward → buy drill → automatic damage → relaunch
              ↓
M3+ unchanged from IMPLEMENTATION_BACKLOG.md
```

Two notes on this ordering:

**CI belongs on the unchanged baseline.** The backlog places M0-04 correctly, but the reason
is worth stating: CI introduced after the pivot starts cannot distinguish "the pivot broke
this" from "this was already broken." That distinction is most of CI's value during a
migration.

**M0.5 is the step the current plan is missing.** The plan was written before the code was
visible, so it has no mechanism for correcting itself once the code appears. Without an
explicit revision step, the greenfield module tree in §3 will be followed as though it were
verified — and it is not, because nothing has been.

## 7. Smaller notes

- **Prestige formula** (`PRODUCT_SPEC.md` §12.2) reads reasonably as a starting point. The
  `^0.35` exponent on lifetime ore gives the intended diminishing return. It will need the
  simulation harness from technical plan §7.3 to tune, and that harness should be built
  before the formula is treated as anything but provisional.
- **Health growth (1.155) exceeding reward growth (1.145)** is deliberate and correct — it
  creates the pressure that makes upgrades and prestige feel necessary. The gap is narrow
  enough to be tunable rather than punishing. Worth preserving through balance passes.
- **Power as capacity rather than currency** (§6.3) is a good economy decision. It creates
  build choices without a third resource to manage.
- **Two currencies for the first release** is right. Idle games that ship with four or five
  are hard to teach.
- **Accessibility from the start** (technical plan §15) rather than as an M8 retrofit is the
  correct call, particularly the VoiceOver fallback for manual impact — a tap-driven game is
  otherwise unplayable with VoiceOver active.
- **`docs/CURRENT_PROJECT_AUDIT.md` is referenced by backlog M0-02 but was never created.**
  Added in this change as a blank template.

## 8. Summary

| Area | Assessment |
|---|---|
| Product specification | Sound. Ship as-is. |
| Simulation architecture | Sound. The fixed-step/render split is the plan's best decision. |
| Persistence design | Sound, but adopt it knowingly at the cost of existing persistence. |
| Module structure (§3) | Unverified. Rewrite after the audit. |
| Removal plan (§20) | Reframe: inventory reuse first, deletion second. |
| SpriteKit assumption | Unverified. Defer; the render split makes deferring cheap. |
| `LargeNumber` priority | Inverted. Wrap `Double` now, revisit late. |
| Milestone ordering | Sound, plus an explicit plan-revision step after the audit. |
| **Overall blocker** | **The source has never been pushed. Everything above waits on it.** |
