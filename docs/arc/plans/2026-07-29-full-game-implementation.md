# DeepMine Gameplay-Complete MVP Implementation Plan

> **For Arc:** Use /arc:implement. Build agents report DONE, DONE_WITH_CONCERNS,
> NEEDS_CONTEXT, BLOCKED, or AUTH_GATE.

**Feature spec or source:** `docs/SPEC_v0.2.md` (product authority), `docs/GAME_DESIGN_REVIEW.md`, `DESIGN.md`, and the user's 2026-07-29 full-game implementation request
**Goal:** Turn the P0 probe into the complete local MVP game described by Spec §16: onboarding, focus session, rewards, equipment, veins, regions, streaks, prestige, local persistence, app UI, Live Activity, StandBy-shaped content, home widgets, Control Center control, haptics, sound, and basic statistics.
**Delivery boundary:** Gameplay-complete P1–P4 plus the P10 balance simulator and P11 QA artifacts. StoreKit, paid gating, store assets, server/login/sync, social/ranking/season/quest/combat/inventory, iPad/Watch apps, and external deployment are excluded. Basic statistics and all gameplay remain free. Physical-device P0 and system-surface validation remains release-blocking.
**Stack:** Swift 6, SwiftPM, SwiftUI, SwiftData, ActivityKit, WidgetKit, AppIntents, AlarmKit, FamilyControls, ManagedSettings, DeviceActivity, XcodeGen, XCTest
**Planned at:** a361d0c
**Plan schema:** 2
**Planned assurance:** Guarded
**Effective assurance:** Guarded
**Assurance rationale:** Versioned persistence, reward/prestige transitions, cross-process command idempotency, and permission-bearing system adapters are Guarded data and authorization boundaries.
**Visual test constraint:** Per the user's explicit instruction, screenshot and UI visual QA uses default `medium` Dynamic Type, dark appearance, and standard contrast only. The implementation still uses semantic text styles, VoiceOver labels, 44pt targets, non-color status cues, and Reduce Motion-safe transitions; oversized-type screenshot runs are intentionally not part of this delivery.

## Settled gameplay contracts

- `focusCredits = focusedMinutes / 25`. Reward base is `100 × focusCredits`; the existing 15/25/50 adjustments `1.0/1.1/1.3` are then applied. Growth is `1.04^min(lifetimeFocusCredits,20)` after the 30-day simulator rejected unlimited lifetime growth and run-reset growth; depth, regions, and prestige use run focus credits, while the third completed session still unlocks deep mining. Equal-time base ore is therefore 60/110/260 for 15/25/50 minutes before other multipliers.
- Equipment base prices are drill 100, cart 180, lamp 260 ore; every next level costs `basePrice × 1.38^(currentLevel-1)`, rounded up. Drill adds 10% base reward per level above 1. Cart adds 2% to the 25-minute adjustment and 5% to the 50-minute adjustment per level above 1. Lamp uses the vein-chance rule below. All cap at level 20. Upgrade efficiency uses the exact next-session marginal expected ore divided by price, with drill as the tie-break.
- `depth = floor(12 × runFocusCredits^1.15)`. Region thresholds are 0m 입구 갱도, 120m 수정 동굴, 480m 고대 유적, 1,200m 심연 균열. Region themes use the same four pigments; themes alter silhouettes/patterns, not palette.
- Deep abandonment loses only that session's reward. It never revokes a daily goal or streak already earned. Safe/survey abandonment grants 50% of elapsed-minute base reward. Time tampering downgrades to open; monotonic reset is `.rebooted`, uses wall time, and does not downgrade.
- Base vein chance is 12%. Survey multiplies it by three. Lamp levels 2–20 add 0.8 percentage points each; permanent resonance levels add 1 point each. After four consecutive misses, each later miss adds 8 points; the eighth eligible completion is guaranteed. The UI discloses the guarantee plainly. Type weights are blue 35, crystal 25, vault 15, resonance 15, abyss 10. Crystal awards `1 + regionIndex` crystals. Abyss adds 60 bonus depth meters without changing reward growth or prestige credit. Vault deterministically unlocks the first locked theme in `[crystal, ruins, abyss]`, then the first locked brass decoration in `[marker, rail, lamp, cart]`; after all are owned it converts to two crystals.
- Daily goal is configurable from 25–360 minutes in 5-minute steps, default 100. One automatic rest day is available per ISO week. Later missed days halve the streak rather than zeroing it. Calendar calculations use an injected calendar/time zone and have midnight/time-zone tests.
- First prestige requires 40 run focus credits; later targets multiply by 1.6. Prestige resets run focus credits, depth, ore, and equipment, and preserves lifetime totals, crystals, themes, history, daily state, and permanent upgrades. It grants `prestigeIndex + 1` core shards. Permanent upgrades cost `nextLevel` shards, max 10: excavation memory +8% base reward/level, resonance detection +1 percentage point/level, compressed time +5% to the 50-minute adjustment/level.
- Free basic statistics include weekly focused minutes, completed sessions, deepest return, plan mix, and vein history. Detailed paid analytics and StoreKit remain future Phase 5 work.
- The generated 24/48/72px miner sprite and four-pigment design pass already in the worktree are part of this implementation.

## File structure

- `PRODUCT.md` — concise derived product register; `docs/SPEC_v0.2.md` remains authoritative.
- `DeepMineCore/` — Foundation-only domain package plus balance CLI.
- `DeepMineApp/` — SwiftData repository, session orchestration, localization, design system, and player screens.
- `DeepMineProbe/` — retained P0 adapters/diagnostics and shared extension surfaces migrated into the `DeepMineApp` product target.
- `artifacts/ui/game-mvp-v1/` — default-spec simulator screenshots and read-back notes.
- `docs/{MIGRATION,BALANCE_REPORT,QA_CHECKLIST,DEFECTS,GAME_IMPLEMENTATION}.md` — durable implementation evidence.

## Seams

<seams>
  <seam id="reward-session"><interface>`SessionStateMachine`, `ClockIntegrityChecker`, and `RewardCalculator`</interface><behavior>Legal, deterministic, idempotent focus results with multiplier breakdowns and fatigue segmentation</behavior><test>`DeepMineCore/Tests/DeepMineCoreTests/SessionRewardTests.swift`</test></seam>
  <seam id="progression"><interface>`ProgressionEngine`, `UpgradeAdvisor`, `StreakEngine`, `VeinRoller`, and `PrestigeEngine`</interface><behavior>Produces all durable player progression from completed or abandoned session results</behavior><test>`DeepMineCore/Tests/DeepMineCoreTests/ProgressionTests.swift`</test></seam>
  <seam id="repository"><interface>`GameRepository` app-owned transaction boundary over explicit SwiftData models</interface><behavior>Migrates, round-trips, quarantines corruption, and restores all player state</behavior><test>`DeepMineAppTests/GamePersistenceTests.swift`</test></seam>
  <seam id="command-queue"><interface>locked App Group `GameCommandQueue` with pending/applied/quarantined states</interface><behavior>Extension commands are durably appended and applied at most once across crash/replay</behavior><test>`DeepMineAppTests/GameCommandQueueTests.swift`</test></seam>
  <seam id="orchestration"><interface>`GameStore` and injected `SessionSystemCoordinating`</interface><behavior>Persists first, coordinates system adapters second, and recovers session completion exactly once</behavior><test>`DeepMineAppTests/GameStoreTests.swift`</test></seam>
  <seam id="product-flow"><interface>`GameRootView` routes driven by deterministic launch fixtures</interface><behavior>Onboards, starts, completes/abandons, returns, upgrades, reviews history, changes settings/theme, and prestiges</behavior><test>`DeepMineAppUITests/GameFlowUITests.swift`</test></seam>
  <seam id="passive-surfaces"><interface>`DeepMineActivityAttributes`, Live Activity views, home widgets, and Control Widget</interface><behavior>Displays the same persisted session contract without direct production SwiftData writes</behavior><test>`DeepMineAppUITests/GameSurfaceScreenshotTests.swift`</test></seam>
</seams>

## Tasks

<task id="1" depends="" type="auto" kind="documentation" status="done">
  <name>Lock product, balance, gate, and QA contracts</name>
  <files><create>PRODUCT.md</create><create>docs/BALANCE_REPORT.md</create><create>docs/QA_CHECKLIST.md</create><create>docs/DEFECTS.md</create><modify>AGENTS.md</modify><modify>CONTEXT.md</modify><modify>docs/DECISIONS.md</modify></files>
  <read_first>docs/SPEC_v0.2.md; docs/GAME_DESIGN_REVIEW.md; docs/DEV_PLAYBOOK.md; DESIGN.md; AGENTS.md; CONTEXT.md</read_first>
  <action>Record this plan's settled gameplay formulas and free-statistics boundary, make PRODUCT a derived register, create an initial four-persona balance expectation table, and record that explicit user direction authorizes simulator-first gameplay work while physical P0 remains a release gate. QA_CHECKLIST classifies every Spec §20 concern as automated, simulator-manual, or physical-device. DEFECTS starts with known device-only unknowns, not invented passes.</action>
  <verify>`rg -n '^## (Register|Platform|Users|Product Purpose|Positioning|Brand Personality|Anti-references|Design Principles|Accessibility & Inclusion)$' PRODUCT.md`; `rg -n 'focusCredits|40|1\.6|8회|StoreKit|실기기' docs/BALANCE_REPORT.md docs/QA_CHECKLIST.md docs/DECISIONS.md AGENTS.md CONTEXT.md`</verify>
  <done>Implementation starts from explicit product, balance, scope, and evidence contracts without replacing the authoritative spec.</done>
  <commit>docs(product): lock the gameplay contract</commit>
</task>

<task id="2" depends="1" type="auto" kind="behavior" status="done">
  <name>Implement session, clock, fatigue, and reward calculations</name>
  <files><create>DeepMineCore/Package.swift</create><create>DeepMineCore/Sources/DeepMineCore/Balance.swift</create><create>DeepMineCore/Sources/DeepMineCore/GameTypes.swift</create><create>DeepMineCore/Sources/DeepMineCore/SessionStateMachine.swift</create><create>DeepMineCore/Sources/DeepMineCore/ClockIntegrityChecker.swift</create><create>DeepMineCore/Sources/DeepMineCore/RewardCalculator.swift</create><create>DeepMineCore/Tests/DeepMineCoreTests/SessionRewardTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §2–4; docs/BALANCE_REPORT.md; CLAUDE.md; DeepMineProbe/Shared/ClockProbe.swift</read_first>
  <action>Create the Foundation-only package and implement legal preparing→mining→completed/abandoned transitions, valid/rebooted/tampered clock results, verification grades, focus-credit base reward with `1.04^lifetimeFocusCredits` growth, per-minute 240/360 fatigue segmentation, plan/grade/streak/session-order/equipment/vein multipliers, overflow-safe Double results, and multiplier breakdowns. Completion IDs are idempotent.</action>
  <seams><seam ref="reward-session" /></seams><behavior>Every session outcome has one legal transition and one explainable reward.</behavior><examples>230 accumulated minutes plus 25 minutes splits 10 minutes at ×1 and 15 at ×0.5. Replaying a completion ID cannot award twice. A reboot accepts wall time; a 31-second clock delta downgrades.</examples>
  <verify>`swift test --package-path DeepMineCore --filter SessionRewardTests`; `rg -n 'import (SwiftUI|UIKit|ActivityKit|FamilyControls|SwiftData|Darwin)' DeepMineCore/Sources && exit 1 || true`; `find DeepMineCore/Sources -name '*.swift' -print0 | xargs -0 -n 1 sh -c 'lines=$(wc -l &lt; "$1"); test "$lines" -le 300 || { echo "$1:$lines"; exit 1; }' sh`</verify>
  <done>Session and reward calculations pass boundary, tamper/reboot, fatigue, idempotence, snapshot, and 500-session overflow tests.</done>
  <commit>feat(core): implement session reward engine</commit>
</task>

<task id="3" depends="2" type="auto" kind="behavior" status="done">
  <name>Implement equipment and focus-credit progression</name>
  <files><create>DeepMineCore/Sources/DeepMineCore/GameState.swift</create><create>DeepMineCore/Sources/DeepMineCore/EquipmentEngine.swift</create><create>DeepMineCore/Sources/DeepMineCore/ProgressionEngine.swift</create><create>DeepMineCore/Tests/DeepMineCoreTests/ProgressionTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §4–5; docs/BALANCE_REPORT.md; DeepMineCore/Sources/DeepMineCore/Balance.swift</read_first>
  <action>Implement Codable/Sendable player state, resources, history limits, focus-credit depth, deep unlock after three completions, exact drill/cart/lamp base prices and per-level effects, levels 1–20, price 1.38^(level-1), affordability, and one best recommendation by next-session marginal expected ore/cost with drill tie-break.</action>
  <seams><seam ref="progression" /></seams><behavior>A session result advances fair depth and allows only valid, affordable upgrades.</behavior><examples>15/25/50 minutes add 0.6/1/2 credits. Drill level 2 costs 100 and yields +10%; cart level 2 costs 180 and changes 25/50 adjustments to 1.12/1.35; lamp level 2 costs 260 and adds 0.8 points. Three completions unlock deep. A repeated upgrade command or level-20 purchase changes nothing.</examples>
  <verify>`swift test --package-path DeepMineCore --filter ProgressionTests`; `swift test --package-path DeepMineCore`</verify>
  <done>Player state and equipment progression are deterministic, bounded, and explainable.</done>
  <commit>feat(core): add equipment progression</commit>
</task>

<task id="4" depends="3" type="auto" kind="behavior" status="done">
  <name>Implement daily goals, streaks, and calendar recovery</name>
  <files><create>DeepMineCore/Sources/DeepMineCore/StreakEngine.swift</create><create>DeepMineCore/Tests/DeepMineCoreTests/StreakEngineTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §7; docs/GAME_DESIGN_REVIEW.md; DeepMineCore/Sources/DeepMineCore/GameState.swift</read_first>
  <action>Implement configurable 25–360-minute goals, daily records, once-per-ISO-week automatic rest day, half-streak miss policy, 1/3/7/14/30-day multipliers, and injected calendar/time zone. Deep abandonment never rolls back a goal already achieved.</action>
  <seams><seam ref="progression" /></seams><behavior>Daily progression remains stable across midnight, gaps, rest days, and time-zone changes.</behavior><examples>A first missed day consumes the weekly rest day; a second halves 7 to 3. A deep failure after 100 focused minutes preserves the earned streak.</examples>
  <verify>`swift test --package-path DeepMineCore --filter StreakEngineTests`; `swift test --package-path DeepMineCore`</verify>
  <done>Calendar and streak policy passes midnight, timezone, rest-day, and deep-failure tests.</done>
  <commit>feat(core): implement fair streak policy</commit>
</task>

<task id="5" depends="4" type="auto" kind="behavior" status="done">
  <name>Implement veins, regions, themes, and dry-spell protection</name>
  <files><create>DeepMineCore/Sources/DeepMineCore/VeinEngine.swift</create><create>DeepMineCore/Sources/DeepMineCore/WorldProgression.swift</create><create>DeepMineCore/Tests/DeepMineCoreTests/VeinWorldTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §6; docs/BALANCE_REPORT.md; DeepMineCore/Sources/DeepMineCore/Balance.swift</read_first>
  <action>Implement seeded vein rolls, exact base/survey/lamp/permanent/dry-spell probabilities, guaranteed eighth attempt, weighted five-type outcomes, blue ×1.5, `1 + regionIndex` crystal quantity, deterministic vault unlock/conversion order, one-session resonance ×2 carry-over, abyss +60 bonus meters, four region thresholds, and theme selection. Do not resolve or reveal veins during a session.</action>
  <seams><seam ref="progression" /></seams><behavior>Completion reveals at most one reproducible vein and advances world presentation without palette expansion.</behavior><examples>Seven misses guarantee the eighth roll. Survey triples only the pre-protection base chance. Region index 2 crystal grants three crystals. Abyss adds exactly 60 display meters. Vault unlocks crystal before ruins, then decorations, then converts to two crystals.</examples>
  <verify>`swift test --package-path DeepMineCore --filter VeinWorldTests`; `swift test --package-path DeepMineCore`</verify>
  <done>Vein distribution, dry-spell boundaries, effects, region thresholds, and theme idempotence are tested.</done>
  <commit>feat(core): add veins and mine regions</commit>
</task>

<task id="6" depends="5" type="auto" kind="behavior" status="done">
  <name>Implement prestige and permanent upgrades</name>
  <files><create>DeepMineCore/Sources/DeepMineCore/PrestigeEngine.swift</create><create>DeepMineCore/Tests/DeepMineCoreTests/PrestigeTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §8; docs/BALANCE_REPORT.md; DeepMineCore/Sources/DeepMineCore/GameState.swift</read_first>
  <action>Implement 40 × 1.6^prestigeIndex targets, loss-first eligibility preview, documented reset/preserve fields, prestigeIndex+1 shard grants, and the exact cost/effect/max rules for excavation memory, resonance detection, and compressed time.</action>
  <seams><seam ref="progression" /></seams><behavior>Prestige is deliberate, loss-transparent, idempotent, and repeatable.</behavior><examples>Prestige before 40 run credits fails without mutation. First prestige resets ore/equipment/run depth, grants one shard, and preserves crystals/history/themes/streak. Memory level 1 costs one shard and adds exactly 8% base reward.</examples>
  <verify>`swift test --package-path DeepMineCore --filter PrestigeTests`; `swift test --package-path DeepMineCore`</verify>
  <done>Prestige eligibility, reset/preserve, shard grant, upgrade cost/effects, cap, and replay tests pass.</done>
  <commit>feat(core): implement mine prestige</commit>
</task>

<task id="20" depends="6" type="auto" kind="artifact" status="done">
  <name>Build the 30-day balance simulator and report</name>
  <files><create>DeepMineCore/Sources/DeepMineBalanceCLI/main.swift</create><modify>DeepMineCore/Package.swift</modify><create>DeepMineCore/Tests/DeepMineCoreTests/BalanceSimulationTests.swift</create><modify>docs/BALANCE_REPORT.md</modify></files>
  <read_first>docs/DEV_PLAYBOOK.md P10; docs/BALANCE_REPORT.md; DeepMineCore/Sources/DeepMineCore/Balance.swift; DeepMineCore/Sources/DeepMineCore/ProgressionEngine.swift</read_first>
  <action>Create a seeded CLI for light, standard, heavy, and irregular 30-day personas using the shipping Core engine. Emit CSV plus a terminal summary and update the report with actual first upgrade, first prestige, heavy/light gap, soft-cap behavior, and equal-time 15/25/50 comparisons.</action>
  <verify>`swift test --package-path DeepMineCore --filter BalanceSimulationTests`; `swift run --package-path DeepMineCore DeepMineBalanceCLI --seed 260729 --days 30 --output /tmp/deepmine-balance.csv`; `test -s /tmp/deepmine-balance.csv`; `rg -n '라이트|스탠다드|헤비|불규칙|15분|25분|50분|첫 강화|첫 프레스티지|소프트캡' docs/BALANCE_REPORT.md`</verify>
  <done>The four personas and equal-time comparison are generated reproducibly from the shipping engine and documented.</done>
  <commit>test(balance): simulate the 30-day economy</commit>
</task>

<task id="7" depends="20" type="auto" kind="integration" status="done">
  <name>Create the product target and versioned SwiftData repository</name>
  <files><modify>project.yml</modify><modify>DeepMine.xcodeproj/project.pbxproj</modify><modify>DeepMineProbe/App/DeepMineProbeApp.swift</modify><create>DeepMineApp/Persistence/GameModels.swift</create><create>DeepMineApp/Persistence/GamePersistence.swift</create><create>DeepMineAppTests/GamePersistenceTests.swift</create><create>docs/MIGRATION.md</create></files>
  <read_first>project.yml; docs/DEV_PLAYBOOK.md P3; DeepMineProbe/Shared/ProbeSharedWrite.swift; DeepMineProbe/Shared/ProbeConstants.swift</read_first>
  <action>Rename the application/scheme and tests to DeepMineApp/DeepMineAppTests/DeepMineAppUITests, add local DeepMineCore, and preserve extension targets and SharedAssets. Put `DeepMine.store` in `group.com.eiraworks.deepmine`. Define schema-v1 PlayerStateEntity, EquipmentStateEntity, SessionRecordEntity, DailyRecordEntity, and PurchaseStateEntity, each with schemaVersion. App owns writes. Empty store creates defaults; unsupported versions fail closed; load corruption moves the store and sidecars to `CorruptStores/<timestamp>/` before reset and presents a recovery notice. Document v1 and future migration steps.</action>
  <seams><seam ref="repository" /></seams><behavior>Explicit models round-trip all Core state and recover without silently discarding the corrupt source.</behavior><examples>State with resources, gear, streak, history, themes, and prestige survives reload. Unknown schema is rejected. Corrupt bytes are quarantined before defaults are created.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppTests/GamePersistenceTests test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`; `rg -n 'PlayerStateEntity|EquipmentStateEntity|SessionRecordEntity|DailyRecordEntity|PurchaseStateEntity|schemaVersion|CorruptStores' DeepMineApp docs/MIGRATION.md`</verify>
  <done>The generated product target builds and explicit app-owned models migrate, round-trip, and quarantine corruption.</done>
  <commit>feat(app): add versioned game persistence</commit>
</task>

<task id="8" depends="7" type="auto" kind="integration" status="done">
  <name>Implement crash-safe extension command queue</name>
  <files><create>DeepMineCore/Sources/DeepMineCore/GameCommand.swift</create><create>DeepMineApp/Persistence/GameCommandQueue.swift</create><modify>DeepMineProbe/Shared/ProbeProcessLock.swift</modify><create>DeepMineAppTests/GameCommandQueueTests.swift</create><modify>docs/MIGRATION.md</modify></files>
  <read_first>DeepMineProbe/Shared/ProbeStore.swift; DeepMineProbe/Shared/ProbeProcessLock.swift; docs/DEV_PLAYBOOK.md P3</read_first>
  <action>Use `GameCommands.jsonl`, `GameCommands.lock`, and `AppliedCommands.json` in the App Group. Append under the existing process lock. Drain with pending→applying→applied receipts: persist game transaction and applied command ID atomically when app-owned SwiftData is available, then compact the file. On crash after apply, replay observes the receipt and cannot mutate twice. Malformed commands move to `GameCommands.quarantine.jsonl` while later valid commands continue. Bound files to 256KB/recent 500 records.</action>
  <seams><seam ref="command-queue" /></seams><behavior>Extensions enqueue only; the app applies each valid command at most once across concurrency, malformed data, and crash replay.</behavior><examples>100 concurrent appends decode. A crash fixture after repository commit but before queue compaction does not double-upgrade. A malformed middle line is quarantined without blocking the next line.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppTests/GameCommandQueueTests test`</verify>
  <done>Command round-trip, concurrency, quarantine, replay, and bounded retention tests pass.</done>
  <commit>feat(app): add idempotent command queue</commit>
</task>

<task id="9" depends="8" type="auto" kind="integration" status="done">
  <name>Orchestrate sessions through system adapters</name>
  <files><create>DeepMineApp/Session/GameStore.swift</create><create>DeepMineApp/Session/SessionSystemCoordinator.swift</create><modify>DeepMineProbe/App/AlarmProbe.swift</modify><modify>DeepMineProbe/App/ScreenTimeProbe.swift</modify><modify>DeepMineProbe/Shared/LiveActivityLifecycle.swift</modify><modify>DeepMineProbe/Shared/DeepMineActivityAttributes.swift</modify><modify>DeepMineProbe/Shared/ProbeShieldJournal.swift</modify><modify>DeepMineProbe/Monitor/DeepMineDeviceActivityMonitor.swift</modify><create>DeepMineAppTests/GameStoreTests.swift</create></files>
  <read_first>DeepMineProbe/App/ProbeViewModel.swift; DeepMineProbe/App/AlarmProbe.swift; DeepMineProbe/App/ScreenTimeProbe.swift; DeepMineProbe/Shared/LiveActivityLifecycle.swift; DeepMineProbe/Shared/ProbeShieldJournal.swift</read_first>
  <action>Persist a preparing/mining session before side effects, apply shield, Live Activity, AlarmKit with local-notification fallback, and recover expired sessions/shields. Permission denial degrades to open with a visible reason. Shield break marks collapsed. Clock tampering degrades to open. Adapter errors are bounded and shown. Relaunch completes or abandons exactly once. Keep the P0 diagnostics behind Settings > 개발 진단 and label it device-gate evidence.</action>
  <seams><seam ref="orchestration" /></seams><behavior>GameStore is the only app state-machine owner and never claims an unperformed system action succeeded.</behavior><examples>FamilyControls denial starts open mining. Alarm denial falls back locally. Relaunch after endsAt completes once. A stale monitor cannot clear a newer shield.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppTests/GameStoreTests -only-testing:DeepMineAppTests/ProbeSharedStoreTests test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`</verify>
  <done>Fake-adapter tests cover success, each permission denial, adapter failure, tamper/reboot, midnight completion, recovery, and idempotence.</done>
  <commit>feat(session): orchestrate focus mining</commit>
</task>

<task id="10" depends="9" type="auto" kind="integration" status="done">
  <name>Build the product design system, localization, and fixtures</name>
  <files><create>DeepMineApp/DesignSystem/</create><create>DeepMineApp/Resources/Localizable.xcstrings</create><create>DeepMineApp/GameFixtures.swift</create><create>DeepMineApp/GameRootView.swift</create><modify>DeepMineProbe/App/DeepMineProbeApp.swift</modify><create>DeepMineAppTests/DesignSystemContractTests.swift</create></files>
  <read_first>PRODUCT.md; DESIGN.md; DeepMineProbe/App/ProbeComponents.swift; DeepMineProbe/App/ProbeAdventureHeader.swift; DeepMineProbe/Shared/SharedAssets.xcassets</read_first>
  <action>Extract the four-pigment palette, riveted panels, pressable metal buttons, mine toggles, progress rails, equipment rows, number formatter, and accessible status markers. Create Korean and English player-language strings, deterministic fixtures for every screen/surface, reduced-motion-safe feedback, and root navigation. No new RGB colors, glow, glass, dashboard grids, or framework names. Reuse the generated miner sprite.</action>
  <seams><seam ref="product-flow" /></seams><behavior>Every later player screen renders from the same localized fixture contract and accessible four-pigment controls.</behavior><examples>Korean and English resolve all fixture keys. Every status pairs text/symbol with color. Interactive controls expose labels and at least 44pt hit targets. Reduced Motion disables positional press/reveal movement.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppTests/DesignSystemContractTests test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`; `rg -n '#[0-9A-Fa-f]{6}' DeepMineApp DeepMineProbe/Widget DeepMineProbe/Shared | rg -v '10100F|373630|E7E0CF|C58C39' && exit 1 || true`; `rg -n 'ActivityKit|AlarmKit|ManagedSettings|FamilyControls' DeepMineApp/Views DeepMineApp/DesignSystem && exit 1 || true`</verify>
  <done>The app has one reusable, localized, accessible mine UI grammar and deterministic fixture contract.</done>
  <commit>feat(ui): create the DeepMine design system</commit>
</task>

<task id="11" depends="10" type="auto" kind="behavior" status="done">
  <name>Implement onboarding and mine home</name>
  <files><create>DeepMineApp/Views/OnboardingFlowView.swift</create><create>DeepMineApp/Views/MineHomeView.swift</create><create>DeepMineAppUITests/OnboardingHomeUITests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §11–12; docs/GAME_DESIGN_REVIEW.md; PRODUCT.md; DESIGN.md</read_first>
  <action>Implement two concise premise pages, real persisted 90-second unshielded demo, demo return/upgrade, progressive FamilyControls→AlarmKit→notification permission prompts, and the one-screen mine home. Home shows resources/depth/today, plan and 15/25/50 selection, deep lock reason, one next 1–3-session promise, equipment summary, and one brass start action. Remember selection. Each denial still reaches a playable open-grade home.</action>
  <seams><seam ref="product-flow" /></seams><behavior>A first-time player understands the mine, finishes a demo, receives value, then chooses permissions; a returning player sees one clear next expedition.</behavior><examples>Demo reward persists. Deep is locked before three completions. All three permission denials remain playable. Korean and English fixtures do not expose framework terms.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/OnboardingHomeUITests test`</verify>
  <done>Onboarding and fresh/progressed home flows pass in Korean and English default-medium fixtures.</done>
  <commit>feat(ui): add onboarding and mine home</commit>
</task>

<task id="12" depends="11" type="auto" kind="behavior" status="done">
  <name>Implement preflight and active mining</name>
  <files><create>DeepMineApp/Views/SessionPreflightSheet.swift</create><create>DeepMineApp/Views/ActiveMineView.swift</create><create>DeepMineAppUITests/ActiveMineUITests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §2–3; PRODUCT.md; DESIGN.md; DeepMineApp/Session/GameStore.swift</read_first>
  <action>Implement plan/duration/reward/grade/readiness/consequence preflight, active timer/progress/region/verification surface, and explicit abandonment confirmation. Sealed setup can wait visibly; denial/failure explains open grade; active mining never animates ore or reveals veins. Safe/survey partial and deep-zero abandon results route to return.</action>
  <seams><seam ref="product-flow" /></seams><behavior>Starting and abandoning are deliberate, transparent, and match Core results.</behavior><examples>Deep preflight states full loss. Open-grade warning includes ×0.75. Abandon requires confirmation and cannot double-apply.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/ActiveMineUITests test`</verify>
  <done>Plan selection reaches correct preflight/active/abandon states with no mid-session reward theatre.</done>
  <commit>feat(ui): add active mining flow</commit>
</task>

<task id="13" depends="12" type="auto" kind="behavior" status="done">
  <name>Implement the three-beat return report and feedback</name>
  <files><create>DeepMineApp/Views/ReturnReportView.swift</create><create>DeepMineApp/Feedback/GameFeedback.swift</create><create>DeepMineAppUITests/ReturnReportUITests.swift</create></files>
  <read_first>docs/GAME_DESIGN_REVIEW.md; PRODUCT.md; DESIGN.md; DeepMineCore/Sources/DeepMineCore/VeinEngine.swift</read_first>
  <action>Render return confirmation, reward/vein reveal, then next promise/recommended upgrade as three deterministic beats. Use optional haptic and quiet system sound preferences; Reduce Motion reveals without movement. `마치기` and `다음 출정 준비` are equal hierarchy. Reopening a report never reapplies results or feedback.</action>
  <seams><seam ref="product-flow" /></seams><behavior>Completion is emotionally legible without pressuring immediate replay.</behavior><examples>No-vein still feels complete. Each five-vein fixture explains its effect. An unaffordable recommendation routes to equipment without fake purchase.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/ReturnReportUITests test`</verify>
  <done>Normal, abandoned, collapsed, and five vein return states are deterministic and idempotent.</done>
  <commit>feat(ui): add the mine return report</commit>
</task>

<task id="14" depends="13" type="auto" kind="behavior" status="done">
  <name>Implement equipment, journal, and basic statistics</name>
  <files><create>DeepMineApp/Views/EquipmentView.swift</create><create>DeepMineApp/Views/JournalView.swift</create><create>DeepMineApp/Views/StatisticsView.swift</create><create>DeepMineAppUITests/ProgressViewsUITests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §5,§11,§16; PRODUCT.md; docs/GAME_DESIGN_REVIEW.md</read_first>
  <action>Implement drill/cart/lamp choice and recommendation, empty/populated weekly journal, free weekly minutes/completions/deepest return/plan mix/vein history, large-number formatting, and meaningful empty/error/recovery states. Keep content as a mine ledger, not a SaaS chart grid.</action>
  <seams><seam ref="product-flow" /></seams><behavior>Players can understand what they earned, upgrade deliberately, and review their week without paid locks.</behavior><examples>Insufficient ore says how to earn it. Empty journal teaches the loop. Statistics remain readable at zero and at 500 sessions.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/ProgressViewsUITests test`</verify>
  <done>Equipment, journal, and free statistics work for empty, progressed, overflow, and recovery fixtures.</done>
  <commit>feat(ui): add mine progress screens</commit>
</task>

<task id="15" depends="14" type="auto" kind="behavior" status="done">
  <name>Implement themes, settings, and prestige confirmation</name>
  <files><create>DeepMineApp/Views/ThemeView.swift</create><create>DeepMineApp/Views/SettingsView.swift</create><create>DeepMineApp/Views/PrestigeView.swift</create><create>DeepMineAppUITests/SettingsPrestigeUITests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §7–8,§11; docs/MIGRATION.md; PRODUCT.md; DESIGN.md</read_first>
  <action>Implement unlocked-region theme selection, daily goal picker, rest-day explanation, block-list/permission status and retry, haptic/sound toggles, recovery notice, about/privacy, hidden P0 diagnostics, prestige preview, loss-first confirmation, shard allocation, and post-prestige return home. Keep all themes within four pigments.</action>
  <seams><seam ref="product-flow" /></seams><behavior>Settings change durable player preferences and prestige cannot occur without explicit loss disclosure.</behavior><examples>Locked theme states the depth requirement. Goal supports 25 and 360 boundaries. Prestige cancel is a no-op; confirmation resets only documented fields.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/SettingsPrestigeUITests test`</verify>
  <done>The remaining player screens persist choices and expose safe recovery/diagnostic paths.</done>
  <commit>feat(ui): add settings themes and prestige</commit>
</task>

<task id="16" depends="15" type="auto" kind="integration" status="done">
  <name>Connect Live Activity, lock screen, and StandBy-shaped content</name>
  <files><modify>DeepMineProbe/Shared/ProbeLockScreenContent.swift</modify><modify>DeepMineProbe/Widget/DeepMineLiveActivityWidget.swift</modify><modify>DeepMineProbe/Widget/ProbeIntents.swift</modify><modify>DeepMineProbe/Shared/PixelMinerIcon.swift</modify><modify>DeepMineProbe/Shared/SharedAssets.xcassets/</modify><create>DeepMineAppUITests/GameActivitySurfaceTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §9–10; DESIGN.md; DeepMineProbe/Shared/DeepMineActivityAttributes.swift; DeepMineProbe/Widget/DeepMineLiveActivityWidget.swift</read_first>
  <action>Map actual plan, region, depth, expected reward, streak, completion, and vein state into compact, minimal, expanded≤144pt, lock-screen≤160pt, and StandBy-shaped wide content. Preserve timer/progress/staleDate behavior and <4KB state. Use generated sprite and luminance structure that survives monochrome. Intents append idempotent commands or open the app; they never write production SwiftData.</action>
  <seams><seam ref="passive-surfaces" /></seams><behavior>All passive session surfaces tell the same quiet focus story and reveal reward only after return.</behavior><examples>Mining compact is sprite+timer. Completed expanded offers one recommendation. Unsupported intent opens the app without duplicate progression.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/GameActivitySurfaceTests test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`</verify>
  <done>Fixture-rendered activity surfaces meet size/content limits; actual SpringBoard/StandBy lifecycle remains device-gated.</done>
  <commit>feat(widget): connect game activity surfaces</commit>
</task>

<task id="17" depends="16" type="auto" kind="integration" status="done">
  <name>Implement small/medium home widgets and Control Center control</name>
  <files><modify>DeepMineProbe/Widget/ProbeCommandWidget.swift</modify><create>DeepMineProbe/Widget/DeepMineHomeWidget.swift</create><create>DeepMineProbe/Widget/DeepMineControlWidget.swift</create><create>DeepMineAppUITests/GameWidgetSurfaceTests.swift</create></files>
  <read_first>docs/SPEC_v0.2.md §9,§12,§16; DeepMineApp/Persistence/GameCommandQueue.swift; DeepMineProbe/Widget/ProbeIntents.swift</read_first>
  <action>Implement small and medium home widgets for today's progress and start/open actions, plus a 25-minute safe-mine Control Widget. Read snapshot DTOs only; enqueue commands or open app. Render waiting/mining/completed/vein/collapsed fixture states and explain when app opening is required.</action>
  <seams><seam ref="passive-surfaces" /></seams><behavior>System entry points are useful without becoming a second game-state writer.</behavior><examples>Control command is idempotent. Missing permissions opens preflight. Stale snapshot shows an app-open recovery state.</examples>
  <verify>`xcodegen generate --spec project.yml`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' -only-testing:DeepMineAppUITests/GameWidgetSurfaceTests test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`</verify>
  <done>Both widget families and Control Widget build, fixture-render, and respect command ownership.</done>
  <commit>feat(widget): add mine entry widgets</commit>
</task>

<task id="18" depends="17" type="auto" kind="artifact" status="done">
  <name>Capture default-spec simulator evidence and run the full automated gate</name>
  <files><create>DeepMineAppUITests/GameFlowUITests.swift</create><create>DeepMineAppUITests/GameSurfaceScreenshotTests.swift</create><create>artifacts/ui/game-mvp-v1/README.md</create><create>artifacts/ui/game-mvp-v1/screens/</create><modify>docs/QA_CHECKLIST.md</modify><modify>docs/DEFECTS.md</modify></files>
  <read_first>docs/QA_CHECKLIST.md; DeepMineAppUITests/; project.yml</read_first>
  <action>Regenerate the project and exercise the complete local game in deterministic default-medium, dark, standard-contrast Korean fixtures. Capture onboarding, home, preflight, active, return, equipment, journal, statistics, theme, settings, prestige, compact/expanded/minimal, lock-screen, StandBy-shaped, small/medium widget, and Control surfaces. Run an English fixture for clipping/copy and semantic accessibility assertions at medium, but no oversized text visual run. Read every PNG back and log visible defects.</action>
  <verify>`xcodegen generate --spec project.yml`; `swift test --package-path DeepMineCore`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro,OS=26.5' test`; `xcodebuild -project DeepMine.xcodeproj -scheme DeepMineApp -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`; `test "$(find artifacts/ui/game-mvp-v1/screens -name '*.png' | wc -l | tr -d ' ')" -ge 18`; `rg -n '자동|시뮬레이터|실기기' docs/QA_CHECKLIST.md`</verify>
  <done>Core, app tests, full simulator suite, unsigned generic build, and visually inspected default-spec screenshots have fresh evidence; defects are fixed or honestly recorded.</done>
  <commit>test(game): verify the complete local game</commit>
</task>

<task id="19" depends="18" type="auto" kind="documentation" status="done">
  <name>Close implementation and release-gate documentation</name>
  <files><modify>BUILD_REPORT.md</modify><modify>docs/PROJECT_STATUS.md</modify><modify>docs/TASKS.md</modify><modify>docs/DECISIONS.md</modify><modify>docs/CHANGELOG.md</modify><modify>docs/CODE_REVIEW.md</modify><modify>docs/MIGRATION.md</modify><modify>docs/BALANCE_REPORT.md</modify><modify>docs/QA_CHECKLIST.md</modify><modify>docs/DEFECTS.md</modify><create>docs/GAME_IMPLEMENTATION.md</create></files>
  <read_first>docs/SPEC_v0.2.md; docs/DEV_PLAYBOOK.md; BUILD_REPORT.md; PROBE_CHECKLIST.md; artifacts/ui/game-mvp-v1/README.md</read_first>
  <action>Document implemented architecture, game loop, balance deviations, localization, fixtures, persistence/migration/recovery, exact commands, verified simulator results, and every physical-device gate. Mark FamilyControls entitlement, real shield timing, AlarmKit/Live Activity coexistence, command queue across real extension processes, actual Dynamic Island/lock screen/StandBy/Control Widget, haptic/sound feel, and device accessibility as unverified until physical evidence exists. Keep StoreKit and paid analytics explicitly unimplemented.</action>
  <verify>`rg -n '검증됨|미검증|미구현' BUILD_REPORT.md`; `rg -n 'DeepMineApp|swift test|xcodebuild|StoreKit|실기기' docs/GAME_IMPLEMENTATION.md docs/PROJECT_STATUS.md docs/TASKS.md docs/QA_CHECKLIST.md`; `for f in docs/*.md PRODUCT.md DESIGN.md CONTEXT.md; do test -s "$f" || exit 1; done`</verify>
  <done>A future developer can build, test, migrate, inspect, and resume the gameplay-complete MVP without confusing simulator proof with release proof.</done>
  <commit>docs(game): document the gameplay-complete MVP</commit>
</task>

## Implementation state

**Execution base:** a361d0c33ae4ba5ef864d8417e871d1dacd64e95
**Declared scope:** `PRODUCT.md`, `AGENTS.md`, `CONTEXT.md`, `DeepMineCore/**`, `DeepMineApp/**`, `DeepMineAppTests/**`, `DeepMineAppUITests/**`, `DeepMineProbe/**`, `project.yml`, `DeepMine.xcodeproj/**`, `BUILD_REPORT.md`, `docs/**`, `.impeccable/**`, `artifacts/imagegen/dynamic-island-miner-v1/**`, `artifacts/ui/mine-ui-v3/**`, and `artifacts/ui/game-mvp-v1/**`
**Pre-existing dirty paths:** every file and SHA-256 is recorded in `docs/arc/baselines/2026-07-29-full-game.sha256`; these are the current conversation's generated miner/UI pass and are intentionally included in owned scope.
**Excluded metadata:** `docs/arc/plans/2026-07-29-full-game-implementation.md`, `docs/arc/plans/INDEX.md`, and `docs/arc/baselines/2026-07-29-full-game.sha256`
**Commit posture:** uncommitted — implementation is authorized, commit/push is not
**Last coherent commit:** a361d0c33ae4ba5ef864d8417e871d1dacd64e95
**Closeout:** complete — Core 73/73, Xcode 175/175, generic iOS unsigned build, 19-screen read-back, documentation and physical-device gate split completed 2026-07-30

## Decision log

- 2026-07-29: Effective assurance is Guarded because persistence, irreversible-looking prestige presentation, cross-process idempotency, and system permissions require the highest risk posture.
- 2026-07-29: Explicit user direction authorizes simulator-first gameplay-complete P1–P4 work despite the old default P0 order. Physical P0 remains release-blocking and cannot be marked verified by simulator/build evidence.
- 2026-07-29: “Full game” means Spec §16 gameplay-complete local MVP plus balance/QA artifacts. StoreKit and paid gating are future Phase 5 commerce, not required to play, and remain excluded.
- 2026-07-29: Focus-credit, deep/streak, dry-spell, prestige, and free-statistics contracts above resolve the five open decisions in `docs/GAME_DESIGN_REVIEW.md` before Core implementation.
- 2026-07-29: The prior generated miner sprite/UI work belongs to this same user request chain; its per-file baseline is durable and overlapping edits are intentional.
- 2026-07-29: Default-medium-only visual QA follows the user's explicit instruction. Accessibility implementation remains in scope, but oversized-text screenshots do not.
- 2026-07-29: The 30-day simulator invalidated unlimited lifetime growth (261,767.864794× heavy/light ore gap) and run-reset growth (147.788782× plus a prestige production penalty). Growth is now capped at 20 lifetime focus credits; the automated guardrails are ≤10× focus/depth and ≤25× gross ore.
- 2026-07-29: The product target/scheme/bundle are renamed DeepMineApp, while `PRODUCT_MODULE_NAME=DeepMineProbe` remains temporarily to keep existing P0 `@testable import` sources building during the staged migration. Final review will either remove the compatibility name or document it as technical debt.
