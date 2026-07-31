# Pivot Revision — Idle Clicker with Focus as an Amplifier

Status: PROPOSED — revises D-033 and D-035
Priority: P0
Created: 2026-07-31
Supersedes the delete-heavy sequencing in
`docs/arc/plans/2026-07-31-idle-clicker-pivot-code-audit.md` §3.1 and §5
Keeps that document's file inventory and coupling measurements

## 0. Why the previous plan was wrong

The audit treated the pivot as binary: focus is the economy, so removing focus means
removing everything attached to it. That framing came from one sentence in the pre-pivot
spec, not from the code.

> Spec §1.2: 이건 **차단 기반 집중 도구**이고, 방치형 게임이 아니다.
> 오프라인 보상도, 수면 채굴도 없다. **집중만이 유일한 연료**다.

"집중만이 유일한 연료" is what forced the demolition. It is a *positioning claim*, and the
pivot is already discarding it. Once that sentence goes, focus does not have to be the only
input — it can be **one input among two**, and then almost nothing has to be deleted.

The four requirements the owner set (reuse, differentiation, retention, clicker
addictiveness) are all better served by demoting focus than by deleting it.

## 1. The proposal

**Idle production is the economy. Focus is an optional amplifier.**

```text
Baseline (always on, no permission needed)
  tap rock → damage → break segment → ore → buy machinery
  machinery deals automatic damage → ore accrues while closed

Amplifier (opt-in, needs FamilyControls)
  start 깊은 집중 → distracting apps blocked → production multiplied
  return → collect the boosted haul
```

A player who never grants Screen Time gets a complete idle clicker. A player who opts in
gets a materially better one, and the app can honestly claim something no competitor does.

### 1.1 What this buys against each requirement

| Requirement | How this serves it |
|---|---|
| 기존 자산 활용 | Deletion drops from ~2,000 lines to ~450. `SessionStateMachine`, `ClockIntegrityChecker`, `ScreenTimeProbe`, verification grades, alarm and Live Activity all keep a purpose |
| 차별성 보유 | No idle clicker on the App Store can block distracting apps. This is the differentiation, and it survives as a *feature* instead of dying as a *foundation* |
| 리텐션 | Achievements, vein codex, growth ledger, prestige, remembered-rebuy all survive untouched. Offline collection is added |
| 클리커 중독성 | Idle output becomes the baseline, so tap/impact meter/weak points/resonance can be built as pure additions rather than replacements |
| 이미지 차별화 | 237 existing PNGs reuse in place. The only real art gap is the rock face, and the four-pigment constraint is itself the visual differentiation |

### 1.2 The entitlement inverts from risk to upside

Previously the product could not ship without `com.apple.developer.family-controls`
(Spec §2.2, "크리티컬 패스"). Under this proposal the game is complete without it and the
amplifier lights up when approval lands. The dependency becomes **non-blocking** — strictly
better than both the pre-pivot design and the pure pivot.

## 2. Decisions this revises

Two approved decisions rest on premises this changes. They should be revisited explicitly
rather than quietly overridden.

### D-033 — accepted loss of the differentiator

Approved an hour ago on the understanding that differentiation was unavoidable collateral.
The owner has since asked for 차별성 보유. This proposal retains it, so the cost D-033
accepted no longer has to be paid.

### D-035 — home widget only

Decided because "an idle game has no session". Under this proposal optional focus sessions
exist again, and they are exactly what Live Activity, Dynamic Island and the alarm are for.

Recommendation: **keep Live Activity and the alarm for focus sessions only**; keep the home
widget for idle/offline state. Drop StandBy and the Control Widget, which served the
old always-on session framing.

D-034 (remove the fatigue soft cap) and D-036 (rename the module) stand unchanged.

## 3. Revised disposition

Changes from the audit's §3. Everything not listed keeps its previous disposition.

### 3.1 Delete — now a short list

| File | Reason |
|---|---|
| `StreakEngine.swift` + `+Calendar.swift` | Daily-goal streak assumes a minutes target. Replaced by a much smaller consecutive-day-of-mining counter |
| `WeeklyLedger.swift` | Weekly focus retrospective. `GrowthLedger` already covers progression |
| `FatigueCalculator` (inside `RewardCalculator`) | D-034 |
| `DeepMineApp/Views/JournalView.swift` | Weekly session journal |
| `ProbeLockScreenContent`, `DeepMineControlWidget`, StandBy fixtures | D-035 as revised |
| Guardrail claims in `GAME_DESIGN_REVIEW.md`, `PRODUCT.md` | D-034 obligation |

Roughly 450 lines, versus ~2,000 in the previous plan.

### 3.2 Retain and retarget — previously marked for deletion

| File | New role |
|---|---|
| `SessionStateMachine.swift` | Lifecycle of an optional focus session. Unchanged logic |
| `ClockIntegrityChecker.swift` | Validates a *boosted* session's elapsed time. Cheating the amplifier must not pay |
| `ScreenTimeProbe.swift`, shield journal, monitor extension | The amplifier's mechanism |
| `AlarmProbe` | Focus session end alarm |
| `LiveActivityLifecycle`, activity content | Focus session display |
| `VerificationGrade` | Amplifier multiplier tier: sealed ×full, open ×reduced, collapsed ×none. Same three cases, same resolution logic |
| `SessionPreflightSheet`, `ActiveMineView` | Reachable from a "깊은 집중" entry point instead of being the only way to play |
| `OnboardingEngine` + flow | Teaches tap→break→buy first. Permissions move to the amplifier's first use, not onboarding |

`MinePlan` (26 files) and `SessionLength` (23 files) survive as focus-session parameters,
which removes the single largest refactor in the previous plan.

### 3.3 Build new — the clicker core

This is where the effort actually goes, and it is additive.

| Item | Note |
|---|---|
| `BigNumber` | PR #1 §6. Ore reaches magnitudes `Double` formats poorly |
| `RockSegment` generation + damage | Deterministic from `SeededGenerator`, which exists |
| `TapEngine` | Manual impact, crit, impact meter, weak points |
| `AutomationEngine` | Ore per second from equipment; the new baseline economy |
| `OfflineCalculator` | PR #1 §13. Cap and efficiency as tunables |
| Fixed-step simulation | PR #1 §5. Commands already have an idempotent queue |
| `Balance` retarget | Focus-derived constants replaced by damage/HP/rate constants; the registry pattern stays |

## 4. Art plan — the real gap

237 PNGs reuse unchanged. The gap is precise and small: **there is no rock.**

A clicker's central object is the thing you hit, and no asset in the catalog depicts it.

| Family | Count | Purpose |
|---|---:|---|
| `RockFace_{entry,crystal,ruins,abyss}_stage{1..4}` | 16 | The tap target per layer, four damage stages each |
| `Fracture_{light,medium,heavy}` | 3 | Crack overlays composited on the face |
| `WeakPoint_{idle,hit}` | 2 | Critical target marker |
| `Debris_{small,large}` | 2 | Break particles |
| `ResonanceNode` | 1 | The golden-cookie analogue |

24 new images, generated the same way as the badges: prompt document → ImageGen → hex
quantization → nearest-neighbour resize → mechanical palette verification. The pipeline and
scripts already exist (`scripts/process_game_assets.py`).

**Prompts and placeholders shipped in P1-3** (`docs/ROCK_ART_PROMPTS.md`,
`GameArtCatalog`). Every slot renders a procedural stand-in in the same four pigments until
an imageset with the matching name is installed, at which point the real art takes over
with no code change. The art gap therefore no longer blocks building the clicker loop —
P2-1 can be played and screenshotted before a single image exists.

**The four pigments are the differentiation.** Idle clickers converge on glossy gradients,
neon numbers and cartoon gloss. A coal-and-brass mine rendered in four flat colours does
not look like any of them, and the constraint is already enforced mechanically — 237 PNGs
verified, zero violations.

## 5. Retention and addictiveness, concretely

Existing systems that need no work: achievements 35, vein codex, growth ledger, prestige
with remembered-rebuy, depth-gated equipment ceiling, compounding upgrade curve.

Additions, in dependency order:

1. **Number growth made visible** — count-up already exists; apply it to ore/sec.
2. **Offline collection sheet** — the strongest idle retention hook. Reuses the return
   report's three-beat structure.
3. **Impact meter and weak points** — active play that amplifies rather than replaces idle.
4. **Resonance nodes** — timed events, deterministic table.
5. **Layer transitions** — one new rule per layer, reusing the four theme scenes.
6. **Achievement metrics retarget** — 6 focus metrics swap for segments broken, max depth,
   offline collected, crits, overdrive seconds. Engine and reward policy untouched.

## 6. Revised sequence

| Step | Work | Gate |
|---|---|---|
| P0-1 | ✅ Preserve `pomodoro-v1-focus-blocking` + `pre-pivot-v1` | Done |
| P0-2 | ✅ Confirm the D-033/D-035 revisions in §2 | D-037, D-038 |
| P0-3 | ✅ Rewrite Spec §1.2 identity: two inputs, focus optional | Spec coherent |
| P0-4 | ✅ Small deletion (§3.1) + module rename, in four commits | Build and suite green |
| P1-1 | ✅ `BigNumber` + `RockSegment` + damage, Core only | Core 130/130 |
| P1-2 | ✅ `StrikeEngine`: tap, impact meter, automation (D-039) | Core 153/153 |
| P1-3 | ✅ Swappable art layer + 24 placeholders + prompt document | Suite green |
| P1-4 | Rock art 24 images through the existing pipeline | Palette verified |
| P2-1 | Tap → break → ore → buy vertical slice on a new root screen | Playable |
| P2-2 | Offline calculator + collection sheet | Relaunch verified |
| P2-3 | Focus amplifier re-entry: reuse preflight/active/LA behind an entry point | Optional path works |
| P3+ | Impact meter, weak points, resonance, layers, achievement retarget | Per PR #1 M3–M6 |

P0-4 is now small enough to be reviewable, which the previous single 2,000-line deletion
commit was not.

## 7. What this proposal does not fix

- The tap loop, automation and offline progression are still genuinely new work. Reuse
  lowers the cost of the pivot; it does not make it cheap.
- Two inputs means two balance surfaces. The balance CLI must simulate idle-only players
  and amplifier users separately, or the amplifier will be either mandatory or pointless.
- Keeping the amplifier keeps `FamilyControls` review scrutiny at submission, even though
  it no longer blocks shipping.

## 8. P0 completion note (2026-07-31)

P0 is done in four reviewable commits rather than the single 2,000-line deletion the
earlier plan required.

| Commit | Content | Gate |
|---|---|---|
| `67d8bda` | Audit and decisions D-033..D-036 | — |
| `42390a1` | Direction revision, spec §1.2, fatigue soft cap removed | Core 91/91 |
| `f95451d` | Streak reduced, ledger rescoped to lifetime | Suite 186/186 |
| `ffb5018` | StandBy and Control Center widget removed | Suite 182/182 |
| (pending) | Module rename to `DeepMine` | — |

Deferred deliberately: the `DeepMineProbe/` directory keeps its name. The `Probe*` types
inside it are the Phase 0 diagnostics harness, which still exists behind the hidden
settings path and is honestly named. Renaming 40+ paths in `project.yml` would be churn
with no functional gain.

Next is P1, which is where the clicker is actually built: `BigNumber`, `RockSegment`,
`TapEngine`, `AutomationEngine`. Everything so far was clearing the way.
