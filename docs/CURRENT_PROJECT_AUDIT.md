# Current Project Audit

> Status: **TEMPLATE — not yet filled in.**
> Blocked on: `docs/SOURCE_IMPORT.md` (the source has not been pushed).
> Backlog task: M0-02.

Every field below is a question that only the real source can answer. Fill each one with a
concrete file path, value, or explicit `none`. Do not leave inferred or placeholder values —
the point of this document is that later tasks can name real files instead of guessing, and a
plausible-looking guess is worse than a blank.

---

## 1. Project facts

| Field | Value |
|---|---|
| Project or workspace path | |
| App target name | |
| Shared scheme name | |
| Bundle identifier | |
| Deployment target (iOS version) | |
| Swift version / toolchain | |
| Xcode version used locally | |
| Supported device families | |
| Orientation support | |
| Uses SwiftUI / UIKit / mixed | |
| Existing rendering stack (if any) | |
| Third-party dependencies (SPM/Pods/Carthage) | |
| Existing test targets | |
| Existing CI workflows | |
| Currently released on the App Store? | |
| If released: current public version | |

## 2. Source inventory

List every source file, grouped by pivot disposition. This is the table that converts the
abstract "remove Pomodoro" instruction into a concrete work list.

### 2.1 DELETE — Pomodoro domain, no game equivalent

| File | What it does | Notes |
|---|---|---|
| | | |

### 2.2 REWRITE — the concept survives, the implementation does not

For example: a timer view model becomes a simulation tick driver; a session-complete
celebration becomes a segment-break celebration.

| File | Current role | Target role |
|---|---|---|
| | | |

### 2.3 REUSE — infrastructure that is not Pomodoro-specific

This is the highest-value section of the audit. See `PIVOT_PLAN_REVIEW.md` §3 for the
categories worth looking for.

| File | What it provides | Changes needed |
|---|---|---|
| | | |

### 2.4 UNCLEAR — needs a decision

| File | Question | Who decides |
|---|---|---|
| | | |

## 3. Persistence

| Field | Value |
|---|---|
| Mechanism (UserDefaults / SwiftData / Core Data / files / Keychain) | |
| Where the store lives on disk | |
| Is there a schema version field today? | |
| What Pomodoro data exists (sessions, streaks, history, settings) | |
| Approximate size of a real user's store | |
| Is any of it worth migrating? | |
| Is iCloud / CloudKit sync enabled? | |

**Migration decision** (backlog M4-03 — pick one and record the reasoning):

- [ ] Retain generic settings only; discard Pomodoro data
- [ ] Archive legacy data to a separate file for one release
- [ ] Clean reset (only valid if the app was never publicly released)

Constraint from `PRODUCT_SPEC.md`: focus minutes and streaks are **not** converted into Ore
or Core Shards under any option.

## 4. Reusable assets

| Category | What exists | Reusable for the mine? |
|---|---|---|
| Colors / theme / design tokens | | |
| Fonts | | |
| Icons | | |
| Illustrations / art | | |
| Sound effects | | |
| Music / ambience | | |
| Haptic patterns | | |
| Animations | | |
| App icon / launch screen | | |
| Localization strings | | |

## 5. Capabilities and entitlements

| Capability | Currently enabled | Still needed after pivot |
|---|---|---|
| Push / local notifications | | |
| Background modes | | |
| Live Activities / ActivityKit | | |
| WidgetKit extension | | |
| App Intents / Shortcuts | | |
| HealthKit / Screen Time / other | | |
| App Groups | | |
| iCloud | | |

Anything answering "no" to the right-hand column is removal work — including the matching
privacy declarations and App Store metadata (backlog M8-06).

## 6. Pomodoro terminology sweep

Run against the imported source and record raw counts, so the removal work has a measurable
finish line:

```sh
for term in pomodoro focus break session streak productivity \
            timerDuration focusDuration breakDuration; do
  printf '%-18s %s\n' "$term" "$(git grep -ci "$term" -- '*.swift' | wc -l)"
done
```

| Term | Files | Reviewed | Notes |
|---|---:|---|---|
| pomodoro | | | |
| focus | | | |
| break | | | |
| session | | | |
| streak | | | |
| productivity | | | |
| timerDuration | | | |
| focusDuration | | | |
| breakDuration | | | |

`break` and `session` will produce false positives — Swift's `break` keyword, URLSession,
audio sessions. Review each hit rather than mass-deleting; the counts are a work estimate,
not a delete list.

## 7. Build verification

Confirm the imported baseline builds **before** any pivot work begins. A pivot that starts
from an unverified baseline cannot tell its own breakage from pre-existing breakage.

| Check | Result |
|---|---|
| Clean checkout opens without missing file references | |
| Builds for Simulator | |
| Existing tests pass | |
| Runs in Simulator | |
| Warnings worth noting | |

## 8. Audit conclusions

To be written once the tables above are filled:

- Reusable proportion of the existing codebase:
- Recommended rendering stack (see `PIVOT_PLAN_REVIEW.md` §4.1):
- Recommended persistence approach (see §4.2):
- Estimated removal effort:
- Anything in the pivot plan that the real code contradicts:
