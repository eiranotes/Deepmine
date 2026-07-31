# Long-Run Progression — Exponential Depth and Playtime

Status: PROPOSED
Priority: P1
Created: 2026-07-31
Depends on: D-037 (focus as amplifier), PR #1 `docs/PRODUCT_SPEC.md`

## 1. The problem

The economy was tuned for a product where the input was human attention, which is scarce
and self-limiting. An idle clicker's input is elapsed time, which is not. Three ceilings
that were correct before are now the thing preventing long play.

### 1.1 The growth cap is a focus-fairness artifact

```swift
growthRate = 1.04
maximumGrowthFocusCredits = 20.0   // → ×2.19, permanently
```

D-019 introduced this cap because unbounded `1.04^lifetimeCredits` made a heavy focus user
261,767× richer than a light one, and that gap felt unfair when the input was *how much of
your life you gave the app*. When the input is elapsed time, a large gap between someone
playing a month and someone playing a day is not unfairness — it is the genre.

The cap now does nothing except flatten the curve at ×2.19 forever.

### 1.2 Equipment terminates

60 levels with `1.12^(lv-1)` reaches ×804 and stops. In the 180-day simulation the heavy
persona was already at drill 38. A dedicated player hits the end of the ladder, and after
that only prestige count changes.

### 1.3 Permanent upgrades terminate

`maximumPermanentUpgradeLevel = 10` across three lines, and `excavationMemory` at
`1.08^10 = ×2.16`. Total permanent ceiling is roughly ×2.16 × ×1.5 (compressed time) ×
+10%p vein chance. After perhaps ten prestiges there is nothing left to buy, which is
exactly when a clicker should be opening up.

## 2. Principle

Long playtime in this genre does not come from bigger numbers. It comes from **a new
multiplier layer arriving just as the previous one saturates**. Each layer is individually
bounded and legible; the stack is what runs long.

```text
layer 1  equipment levels        saturates in weeks
layer 2  prestige research       saturates in months
layer 3  deep core mastery       saturates in ~a year
layer 4  layer specialisation    open-ended, small per-step
```

At any moment exactly one layer should be the interesting one.

## 3. Proposed changes

### 3.1 Remove the growth cap, keep growth slow

| Constant | Now | Proposed |
|---|---|---|
| `growthRate` | 1.04 | 1.02 |
| `maximumGrowthFocusCredits` | 20 (×2.19 ceiling) | removed |

Halving the rate and removing the ceiling makes the early curve gentler than today and the
long curve unbounded. At 200 accumulated units the multiplier is ×52; at 500, ×19,000. It
never flattens, and the first hour is *slower* than the current tuning, not faster.

The variable stops being "focus credits" and becomes total segments broken.

### 3.2 Equipment ceiling rises with depth, without a hard stop

Keep `1.12^(lv-1)` and the depth gate. Raise `maximumEquipmentLevel` 60 → 200 and let the
depth gate be the real limit, as it already is. Level 200 is not a target; it is headroom
so the gate is always the binding constraint and the ladder never visibly ends.

`Balance.compounded` already saturates at `greatestFiniteMagnitude`, so the arithmetic is
safe. `BigNumber` (PR #1 §6) is required before this ships.

### 3.3 Permanent research becomes the second layer

| Constant | Now | Proposed |
|---|---|---|
| `maximumPermanentUpgradeLevel` | 10 | 40 |
| Shard cost of level n | n | `ceil(n^1.35)` |
| `excavationMemoryGrowthRate` | 1.08 | 1.06 |

Level 40 memory is `1.06^40 = ×10.3`, reached over many prestiges rather than ten. The
superlinear cost keeps each level a real decision instead of an automatic purchase.

### 3.4 Third layer: core mastery

New permanent currency earned only by prestiging *past* the previous best depth, so it
rewards pushing rather than looping. Spend on:

- offline cap and efficiency (the pacing lever for long play);
- layer-entry head starts;
- an ore multiplier that compounds with, not replaces, research.

This is the layer that carries months 3–12. It should not exist at launch, but the state
field should be reserved now so no migration is needed later.

### 3.5 Offline progression is the playtime mechanism

PR #1 §13 sets an 8-hour cap at 35% efficiency. For long-run retention this is the single
most important number: it decides whether a player returns twice a day or twice a week.

Proposal: 8h/35% at start, both raised by research to 24h/75%. Long-run players should
find checking in twice a day worthwhile without feeling punished for sleeping.

## 4. What this does to the guardrails

D-026 set the heavy/light ore gap ceiling at 80× over 30 days. Removing the growth cap
breaks that number by design — an unbounded curve means the gap grows with play time.

Replacement guardrails:

- **Delete the ore-gap regression.** It measured focus fairness, which D-034 and D-037
  removed. Keeping it would block every change in §3.
- **Add a saturation regression instead**: at 30, 180 and 365 simulated days, no
  progression layer may be simultaneously maxed. That is the property we actually want —
  something is always left to buy.
- **Add a first-hour regression**: time to first upgrade and to the third layer must stay
  inside the current window, so making the long game longer must not make the first hour
  slower.

## 5. Sequencing

These are balance changes and cannot be validated until the clicker core exists — there is
no damage input to simulate yet.

| Step | When |
|---|---|
| Reserve `coreMastery` state fields | With the next persistence change, before launch |
| Remove growth cap, retune to 1.02 | P1-2, with the `Balance` retarget |
| Raise equipment ceiling to 200 | After `BigNumber` |
| Permanent research to 40 levels | P3, with the achievement retarget |
| Core mastery layer | Post-launch |
| Replace ore-gap regression with saturation + first-hour | P1-2, same commit as the cap removal |

## 6. Risk

The honest one: an unbounded curve plus four stacked layers is how idle games become
number-soup where nothing means anything. The defence is §2 — exactly one layer
interesting at a time — and it is a tuning discipline, not something the type system can
enforce. The saturation regression in §4 is the closest mechanical check available.
