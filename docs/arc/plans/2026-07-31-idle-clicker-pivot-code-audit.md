# Idle Clicker Pivot — Code Audit and Migration Plan

Status: APPROVED — decisions resolved 2026-07-31 (D-033..D-036)
Priority: P0
Effort: XL
Created: 2026-07-31
Source: user request, `docs/SPEC_v0.2.md` (pre-pivot), PR #1 planning documents
Depends on: `agent/idle-clicker-pivot-plan` (`docs/PRODUCT_SPEC.md`,
`docs/TECHNICAL_PLAN.md`, `docs/IMPLEMENTATION_BACKLOG.md`)

## 0. What this document is

PR #1 already defines the target product, architecture and milestone backlog. It was
written when the repository held no source, and its own closing section asks for exactly
one thing before engineering can start:

> Import the current local DeepMine Xcode project. Record actual bundle ID, deployment
> target, scheme, persistence, and Pomodoro file inventory. Translate the milestone
> backlog into file-specific engineering issues after the audit.

The source now exists on `main` (`2ec8d3a`). **This document is that audit.** It does not
restate the product design; it maps the existing 13,600 lines onto the pivot and assigns
every file a disposition.

## 1. Recorded project facts

| Fact | Value |
|---|---|
| Project generation | XcodeGen, `project.yml` is the source of truth |
| App target | `DeepMineApp`, module name `DeepMineProbe` |
| Other targets | `DeepMineProbeWidget`, `DeepMineDeviceActivityMonitor`, tests, UI tests |
| App Group | `group.com.eiranotes.deepmine` |
| Persistence | SwiftData, explicit v1 schema, App Group container |
| Deployment | iOS 26+, Swift 6 |
| Core package | `DeepMineCore`, Foundation-only, 3,626 lines |
| App layer | 69 Swift files, 9,983 lines |
| Localization | `Localizable.xcstrings`, 363 keys, ko + en |
| Art | 79 imagesets, 237 PNGs, verified four-pigment |
| Verified gate | Core 101/101, simulator 182/182 at `11de437` |

**Correction to PR #1's assumption**: the branch's technical plan proposes creating a
module structure from scratch. A Foundation-only pure engine package with a deterministic
seeded RNG, idempotent command application and a balance-simulation CLI already exists.
The pivot should re-target that package, not replace it.

## 2. The load-bearing question

The pre-pivot product had one input: focused minutes. Every economic quantity derives from
it (`Balance.baseOrePerFocusCredit`, `minutesPerFocusCredit`, depth from
`lifetimeFocusCredits`). Removing Pomodoro removes the *only source of value* in the
economy.

So this is not a feature deletion. It is an **input replacement**: focused minutes →
damage dealt over real time. Everything downstream of that input must be re-derived, and
everything upstream (blocking, alarms, verification, streaks) is deleted.

This is why the audit below separates "delete" from "re-derive" — the second group is
where the real work is, and it is easy to mistake it for reuse.

## 3. Disposition by file

### 3.1 Delete outright — the focus contract

These exist only to make a focus session trustworthy. Nothing in an idle clicker needs
them.

| File | Lines | Reason |
|---|---:|---|
| `DeepMineCore/StreakEngine.swift` | 232 | Daily goal, rest weeks, streak decay |
| `DeepMineCore/StreakEngine+Calendar.swift` | 99 | Calendar arithmetic for the above |
| `DeepMineCore/SessionStateMachine.swift` | 114 | preparing→mining→completed lifecycle |
| `DeepMineCore/ClockIntegrityChecker.swift` | 96 | Anti-cheat for wall-clock focus time |
| `DeepMineCore/WeeklyLedger.swift` | 107 | Weekly focus retrospective |
| `DeepMineCore/OnboardingEngine.swift` | 132 | Practice dig, permission staging |
| `DeepMineApp/Session/SessionSystemCoordinator.swift` | ~300 | Shields, alarms, Live Activity |
| `DeepMineApp/Session/GameStore+Verification.swift` | 24 | Grade resolution |
| `DeepMineApp/Session/GameStore+Finalize.swift` | 213 | Session settlement |
| `DeepMineApp/Views/ActiveMineView.swift` | ~240 | The timer screen |
| `DeepMineApp/Views/SessionPreflightSheet.swift` | ~250 | Plan/duration promise |
| `DeepMineApp/Views/OnboardingFlowView*.swift` | ~320 | Two-page premise + practice |
| `DeepMineApp/Views/JournalView.swift` | 180 | Weekly session journal |
| `DeepMineProbe/App/ScreenTimeProbe.swift` | ~260 | FamilyControls/ManagedSettings |
| `DeepMineProbe/App/AlarmProbe.swift` | — | AlarmKit |
| `DeepMineProbe/Monitor/**` | — | DeviceActivityMonitor extension |

Also delete from `project.yml`: the `DeepMineDeviceActivityMonitor` target, the
`com.apple.developer.family-controls` entitlement, `NSAlarmKitUsageDescription`.

**Removing the FamilyControls entitlement is the single largest de-risking in this
pivot.** It was the critical-path approval item in Spec §2.2. The pivot eliminates it.

### 3.2 Re-derive — same shape, different input

These survive structurally but every number inside them changes meaning. Budget them as
rewrites with a reference implementation, not as edits.

| File | Keeps | Must change |
|---|---|---|
| `Balance.swift` | Constant-registry pattern, `compounded` helpers | All focus-derived constants. `baseOrePerFocusCredit`, `minutesPerFocusCredit`, session length/plan/verification/fatigue/streak multipliers all die. New: damage, segment HP, ore-per-break, offline rate |
| `RewardCalculator.swift` | Overflow-safe product, breakdown reporting | Input becomes damage events, not `SessionOutcome`. `FatigueCalculator` (daily soft cap) is a focus-era anti-overuse device and should be deleted, not ported |
| `ProgressionEngine.swift` | Idempotent application by ID, saturating arithmetic | `depth` becomes a function of segments broken, not credits |
| `EquipmentEngine.swift` + `UpgradeAdvisor.swift` | Compounding curve, remembered-rebuy discount, depth-gated ceiling, advisor efficiency ranking | Effects retarget from "per session" to "per second / per hit". Cart (long-session bonus) has no analogue and is replaced by an automation family |
| `VeinEngine.swift` | Seeded RNG, dry-spell protection, guaranteed-after-N | Roll trigger becomes segment break, not session completion |
| `Achievements.swift` + catalog | Whole engine, reward policy (D-028/D-029), idempotency | 6 of 13 metrics die (`lifetimeFocusMinutes`, `streakDays`, `goalDaysEarned`, `sealedCompletions`, `deepCompletions`, `surveyCompletions`). Replace with segments broken, max depth, offline ore, crit count, overdrive time |
| `GameState.swift` | Explicit `Codable`, forward-compatible `decodeIfPresent` | Split into `RunState` / `PermanentState` per PR #1 §4 |

### 3.3 Reuse nearly as-is

| File | Note |
|---|---|
| `WorldProgression.swift` | Region gates, theme/decoration unlocks, vein effects. Depth thresholds retune; structure holds |
| `PrestigeEngine.swift` | Loss-first preview, shard grant, remembered-rebuy, compounding permanent upgrades. Already the exact shape PR #1 §4.4 asks for |
| `VeinCodex.swift`, `GrowthLedger.swift`, `MineCrew.swift` | No focus coupling. Growth ledger's per-session axis becomes per-layer |
| `GameCommand.swift` + `GameCommandQueue` | Idempotent receipts, App Group queue, quarantine. Directly reusable for the fixed-step command model in PR #1 §5.3 |
| `SeededGenerator` | Deterministic RNG for segment generation |
| `DeepMineBalanceCLI` | Persona simulation harness. Retarget personas from schedules to play patterns |

### 3.4 Reuse entirely — no changes

- **79 imagesets / 237 PNGs.** Verified four-pigment. Equipment tiers, veins, theme
  scenes, decorations, resources, permanent upgrades, DI banners, StandBy backgrounds and
  35 achievement badges all describe a mine, not a timer.
- **Design system**: `DeepMineDesignTokens`, `DeepMineComponents`, riveted panels, metal
  button styles, progress rail, counting number, `DeepMinePalette`.
- **Feedback layer**: `GameFeedbackEvent`, `GameHapticEngine`. Event names retarget
  (`sessionSealed` → `segmentBroken`) but the CoreHaptics pattern vocabulary is exactly
  what a clicker needs.
- **Persistence infrastructure**: corruption isolation, atomic commit, App Group store.
- `DESIGN.md`, `docs/PIXEL_ART_PROMPTS.md`, `docs/ACHIEVEMENT_ART_PROMPTS.md`.

### 3.5 Reconsider — surfaces without a session

Live Activity, Dynamic Island, StandBy and the Control Widget exist to show a running
session. An idle game has no session, but it does have offline production.

Two options, decide before M4:

- **(a) Repurpose**: Live Activity shows offline accumulation and a "collect" action. Real
  utility, but ActivityKit needs a start trigger and 8/12-hour limits do not match
  multi-day idling.
- **(b) Reduce to widget only**: home widget shows ore/sec and pending offline ore. Cheap
  and honest.

Recommendation: **(b) for the first release**, keep the widget snapshot writer, delete the
Live Activity lifecycle. Revisit (a) only if offline collection proves to be the retention
hook.

## 4. What the pivot costs that PR #1 does not mention

Three things the planning documents do not price. They should be decided explicitly rather
than discovered during M2.

### 4.1 The differentiator disappears

Spec §1.2 said the product "is a focus tool, not an idle game", and §13 rejected ad-based
and pay-for-power monetization precisely because focus was the honest product. After the
pivot DeepMine competes directly with a saturated idle-clicker market on presentation and
balance alone.

The retained edges are the four-pigment art system, the honest-economy stance, and no ads.
None of them are hard to copy. This is a real strategic cost and worth naming before
committing engineering months.

### 4.2 The soft cap has no successor

`FatigueCalculator` reduced rewards past 240 daily minutes — an anti-overuse device that
only makes sense when the input is human attention. Idle games normally *want* long
engagement. Deleting it is correct, but it means the product loses its stated ethical
guardrail (§19.2, the retention guardrails in `GAME_DESIGN_REVIEW.md`).

If those guardrails still matter, a replacement has to be designed. If they do not, say so
and remove the claims from the documents rather than leaving them contradicted.

### 4.3 Verified work being discarded

Roughly 2,000 lines of Core and app code, currently at Core 101/101 and simulator 182/182,
are deleted. The economy fixes from `455b1e5` (compounding equipment, lifetime depth,
prestige rebuy discount) survive as *design lessons* but their implementations are tied to
focus credits.

Preserve `main` at `2ec8d3a` as a tag before the pivot branch merges.

## 5. Proposed sequence

This refines PR #1's M0 with the audit now available. M1 onward is unchanged from the
backlog.

| Step | Work | Gate |
|---|---|---|
| P0-1 | Tag `pre-pivot-v1` at `2ec8d3a`. Merge PR #1 planning docs | Tag exists |
| P0-2 | Decide §4.1–4.3 and §3.5 explicitly, record as decisions | DECISIONS entries |
| P0-3 | Add simulator CI on `main`, establish green baseline | CI green at 182/182 |
| P0-4 | Delete §3.1 in one commit. Remove the monitor target and FamilyControls entitlement | Build green, suite green minus deleted tests |
| P0-5 | Reduce `Localizable.xcstrings` to surviving keys | Parity contract test passes |
| P1 | PR #1 M1 (deterministic core) against the retained `DeepMineCore` | Core tests green |
| P2+ | PR #1 M2–M6 unchanged | Per backlog |

P0-4 is deliberately a single large deletion commit. Removing the focus contract piecemeal
leaves the build broken between commits, because `SessionLength` and `MinePlan` are
referenced in 23 and 26 files respectively.

## 6. Coupling measurements

Evidence for the sequencing above.

| Symbol | Files referencing |
|---|---:|
| `MinePlan` | 26 |
| `SessionLength` | 23 |
| `VerificationGrade` | 18 |
| `dailyGoal` | 16 |
| `AlarmKit` | 8 |
| `focusCredit` | 8 |
| `FamilyControls` | 6 |
| `ActivityKit` | 4 |

Only six Core files are free of focus coupling: `VeinCodex`, `GrowthLedger`,
`WorldProgression`, `MineCrew`, `ClockIntegrityChecker`, `SessionStateMachine` — and the
last two are deleted anyway.

## 7. Resolved decisions

Answered by the owner on 2026-07-31 and recorded as D-033 through D-036.

| Question | Decision |
|---|---|
| §4.1 Losing the focus differentiator | **Accepted.** Competing on presentation and balance is understood |
| §4.2 Ethical engagement guardrail | **Removed, no successor.** The fatigue soft cap and the guardrail claims in the documents both go. A claim without a mechanism is worse than neither |
| §3.5 System surfaces | **Home widget only.** Live Activity, Dynamic Island, StandBy and Control Widget are deleted. The snapshot writer and command queue survive |
| Pre-pivot build | **Maintained branch**, not just a tag. `pomodoro-v1-focus-blocking` plus `pre-pivot-v1` |
| Module name | **Renamed to `DeepMine`.** `Probe` came from the deleted Phase 0 harness |

## 8. Consequences of the resolutions

- §3.1's delete list grows: `LiveActivityLifecycle`, `DeepMineLiveActivityWidget`,
  `DeepMineControlWidget`, `GameActivitySurfaceContent`, `ProbeLockScreenContent` and the
  activity fixture views join it.
- `FatigueCalculator` and `Balance`'s fatigue constants are deleted rather than retuned,
  and the guardrail sections of `GAME_DESIGN_REVIEW.md` and `PRODUCT.md` are removed in
  the same commit so the documents do not keep asserting a policy the code dropped.
- `project.yml` loses the monitor target, the FamilyControls entitlement,
  `NSAlarmKitUsageDescription`, and renames the module.
- The widget target keeps `DeepMineHomeWidget` and its snapshot provider only.
