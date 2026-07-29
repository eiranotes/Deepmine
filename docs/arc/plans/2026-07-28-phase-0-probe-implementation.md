# Phase 0 Device Probe Implementation Plan

> **For Arc:** Use /arc:implement. Build agents report DONE, DONE_WITH_CONCERNS,
> NEEDS_CONTEXT, BLOCKED, or AUTH_GATE.

**Feature spec or source:** `docs/SPEC_v0.2.md` §17–18 and `docs/DEV_PLAYBOOK.md` P0
**Goal:** Build a minimal iOS 26 probe that makes DeepMine's Live Activity, AlarmKit, Screen Time, clock-integrity, and App Group risks observable on a physical device.
**Stack:** Swift 6, SwiftUI, SwiftData, ActivityKit, WidgetKit, AppIntents, AlarmKit, FamilyControls, ManagedSettings, DeviceActivity, XcodeGen, XCTest
**Planned at:** unborn
**Plan schema:** 2
**Planned assurance:** Guarded
**Effective assurance:** Guarded
**Assurance rationale:** User permission, app shielding, alarm delivery, extension processes, shared SwiftData storage, and Live Activity lifecycle are Guarded boundaries; the highest-risk permission and shared-data signals set the floor.
**Out of scope:** DeepMineCore economy, production persistence schema, production UI, StoreKit, release assets, push, and entitlement submission.

## File structure

- `project.yml` — reproducible app, widget, monitor, and test target definition.
- `DeepMineProbe/Shared/` — activity contract, cross-process locks/logs, shield journal, shared SwiftData model/container, clock types, and pixel icon.
- `DeepMineProbe/App/` — dashboard and adapters for ActivityKit, AlarmKit, Screen Time, clock, and shared-store reads.
- `DeepMineProbe/Widget/` — Live Activity surfaces, restart intent, and SwiftData write widget.
- `DeepMineProbe/Monitor/` — DeviceActivity callbacks and shield cleanup.
- `DeepMineProbe/Tests/` — deterministic log, SwiftData, and clock evidence.
- `artifacts/phase0/` — simulator screenshot evidence.
- `PROBE_CHECKLIST.md` — physical-device pass/fail rubric.

<seams>
  <seam id="probe-log">
    <interface>`ProbeJSONLStore` append/read API and dashboard log list</interface>
    <behavior>Every action records success or a bounded, path-redacted error summary in the App Group log and the app surfaces the same record; full error reflection stays private in OSLog</behavior>
    <test>`DeepMineProbe/Tests/ProbeLogStoreTests.swift`</test>
  </seam>
  <seam id="live-activity">
    <interface>`DeepMineActivityAttributes`, `LiveActivityLifecycle`, and `RestartProbeIntent`</interface>
    <behavior>A 60-second activity renders from timer APIs; app and intent serialize replacement through one App Group lock, re-read and await `.immediate` end before request; stale rendering needs no update loop</behavior>
    <test>`PROBE_CHECKLIST.md` items 1, 2, 6, and 8 plus generic iOS compile evidence</test>
  </seam>
  <seam id="alarm-coexistence">
    <interface>`AlarmProbe.schedule60SecondAlarm` and concurrently active `DeepMineActivityAttributes`</interface>
    <behavior>Alarm authorization and scheduling are observable independently, and a concurrent custom Live Activity exposes Dynamic Island collision or duplication</behavior>
    <test>`PROBE_CHECKLIST.md` item 3</test>
  </seam>
  <seam id="screen-time">
    <interface>`ScreenTimeProbe` authorization, selection, shield, and DeviceActivity boundary methods</interface>
    <behavior>Selected applications/categories use a per-session monitor/journal under a shared process lock; only a matching callback releases them while denial or missing entitlement remains an isolated logged failure</behavior>
    <test>`PROBE_CHECKLIST.md` items 4 and 5</test>
  </seam>
  <seam id="shared-swiftdata">
    <interface>`ProbeSharedWrite`, `ProbeModelContainer`, widget `WriteProbeRecordIntent`, and app record consumption</interface>
    <behavior>The widget writes directly to the App Group SwiftData store and the app observes the same record after foregrounding</behavior>
    <test>`DeepMineProbe/Tests/ProbeSharedStoreTests.swift` plus `PROBE_CHECKLIST.md` item 10</test>
  </seam>
  <seam id="clock-observation">
    <interface>`ClockProbe.start` and `ClockProbe.finish` with an injectable monotonic source</interface>
    <behavior>Wall and continuous elapsed times produce `.valid`, `.tampered` above 30 seconds drift, or `.rebooted` when the monotonic counter resets</behavior>
    <test>`DeepMineProbe/Tests/ClockProbeTests.swift` plus `PROBE_CHECKLIST.md` item 9</test>
  </seam>
  <seam id="probe-dashboard">
    <interface>`ProbeDashboardView` and `ProbeViewModel` at iPhone portrait size with Dynamic Type and VoiceOver metadata</interface>
    <behavior>Seven probe groups stay independently actionable, status and safe error diagnostics remain visible, and large content sizes do not hide controls</behavior>
    <test>`artifacts/phase0/iphone-17-pro.png` plus simulator launch and accessibility-labelled source inspection</test>
  </seam>
</seams>

<task id="1" depends="" type="auto" kind="artifact" status="done">
  <name>Establish the source and project-management baseline</name>
  <files><create>`CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, `.gitignore`, supplied documents under `docs/`, project-management docs, `BUILD_REPORT.md`, and `PROBE_CHECKLIST.md`</create></files>
  <read_first>`docs/SPEC_v0.2.md`, `docs/PIXEL_ART_PROMPTS.md`, and `docs/DEV_PLAYBOOK.md`</read_first>
  <action>Preserve the supplied documents byte-for-byte and record the P0-before-P1 development gate.</action>
  <verify>`shasum -a 256` for the three copied documents equals the three attachment source hashes.</verify>
  <done>The repository contains byte-identical source documents and an explicit P0 device gate.</done>
  <commit>docs(project): establish DeepMine source baseline</commit>
</task>

<task id="2" depends="1" type="auto" kind="artifact" status="done">
  <name>Scaffold the reproducible multi-target Xcode project</name>
  <files><create>`project.yml`, `DeepMineProbe/App/DeepMineProbe.entitlements`, `DeepMineProbe/Widget/DeepMineProbeWidget.entitlements`, `DeepMineProbe/Monitor/DeepMineDeviceActivityMonitor.entitlements`, `DeepMineProbe/App/Info.plist`, `DeepMineProbe/Widget/Info.plist`, `DeepMineProbe/Monitor/Info.plist`, `DeepMineProbe/App/DeepMineProbeApp.swift`, `DeepMineProbe/Widget/DeepMineProbeWidgetBundle.swift`, `DeepMineProbe/Monitor/DeepMineDeviceActivityMonitor.swift`, and generated `DeepMine.xcodeproj`</create></files>
  <read_first>`CLAUDE.md`, `docs/DEV_PLAYBOOK.md`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/ActivityKit.framework/Modules/ActivityKit.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/AppIntents.framework/Modules/AppIntents.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/AlarmKit.framework/Modules/AlarmKit.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/FamilyControls.framework/Modules/FamilyControls.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/ManagedSettings.framework/Modules/ManagedSettings.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/DeviceActivity.framework/Modules/DeviceActivity.swiftmodule/arm64e-apple-ios.swiftinterface`, `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/SwiftData.framework/Modules/SwiftData.swiftmodule/arm64e-apple-ios.swiftinterface`, and `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS26.5.sdk/System/Library/Frameworks/WidgetKit.framework/Modules/WidgetKit.swiftmodule/arm64e-apple-ios.swiftinterface`</read_first>
  <action>Define an iOS 26 Swift 6 app, Widget Extension, DeviceActivityMonitor Extension, and unit-test target with App Group, FamilyControls, Live Activity, and AlarmKit configuration and no runtime dependencies. Give all three production targets minimal compiling entry points so every later slice starts from a buildable project; later slices modify those exact entry files.</action>
  <verify>`xcodegen generate --spec project.yml` and `xcodebuild -project DeepMine.xcodeproj -list` exit 0 and list `DeepMineProbe`, `DeepMineProbeWidget`, `DeepMineDeviceActivityMonitor`, and `DeepMineProbeTests`.</verify>
  <done>The generated project is reproducible and all required targets and embedding relationships are explicit.</done>
  <commit>chore(probe): scaffold phase zero targets</commit>
</task>

<task id="3" depends="2" type="auto" kind="behavior" status="done">
  <name>Build the shared observable log</name>
  <files><create>`DeepMineProbe/Shared/ProbeConstants.swift`, `DeepMineProbe/Shared/ProbeModels.swift`, `DeepMineProbe/Shared/ProbeStore.swift`, and `DeepMineProbe/Tests/ProbeLogStoreTests.swift`</create></files>
  <read_first>`docs/DEV_PLAYBOOK.md` P0 and `docs/CODE_REVIEW.md`</read_first>
  <action>Implement an injectable JSONL App Group log that preserves chronological records and bounded, redacted error descriptions for every process without replacing the separate SwiftData consistency test. Serialize cross-process reads, appends, and retention compaction with a file lock.</action>
  <seams><seam ref="probe-log" /></seams>
  <behavior>Appending records preserves order, reading returns all complete records, and malformed lines fail with the exact line number.</behavior>
  <examples>Two entries read back in insertion order. A malformed second line produces `invalidJSONLine(2)`.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro iOS 26.5,OS=26.5' -only-testing:DeepMineProbeTests/ProbeLogStoreTests test` exits 0.</verify>
  <done>Focused tests prove the shared log's success and corruption behavior.</done>
  <commit>test(probe): add observable shared log</commit>
</task>

<task id="4" depends="3,7" type="auto" kind="integration" status="done">
  <name>Implement Live Activity lifecycle and surfaces</name>
  <files><create>`DeepMineProbe/Shared/DeepMineActivityAttributes.swift`, `DeepMineProbe/Shared/LiveActivityLifecycle.swift`, `DeepMineProbe/Shared/PixelMinerIcon.swift`, `DeepMineProbe/Widget/ProbeIntents.swift`, and `DeepMineProbe/Widget/DeepMineLiveActivityWidget.swift`</create><modify>`DeepMineProbe/Widget/DeepMineProbeWidgetBundle.swift`</modify></files>
  <read_first>`docs/SPEC_v0.2.md` §9–10, `docs/PIXEL_ART_PROMPTS.md` §2.1, and the installed ActivityKit, AppIntents, WidgetKit, and SwiftUI interfaces listed in task 2</read_first>
  <action>Build 60-second start/restart flows using staleDate, timer text/progress, and isStale. Serialize app/intent end→request with an App Group lock, re-read active activities, and refuse a new request if any cannot end. Render compact, minimal, lock-screen, and under-144pt expanded states with a restart intent and task 7's direct SwiftData-write intent plus a hand-authored 24pt silhouette.</action>
  <seams><seam ref="live-activity" /><seam ref="probe-log" /></seams>
  <behavior>Start creates one activity; restart cannot overlap the old one; stale state needs no background loop; both expanded buttons execute named intents; failures remain visible.</behavior>
  <examples>A restart log records end completion before the new ID. The two expanded controls restart the activity and write a shared-store probe record.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` exits 0; checklist items 1, 2, 6, and 8 remain `미검증` pending a device.</verify>
  <done>All required Live Activity states and both expanded actions compile with device-observable lifecycle logs.</done>
  <commit>feat(probe): add live activity lifecycle checks</commit>
</task>

<task id="5" depends="3,4" type="auto" kind="integration" status="done">
  <name>Implement AlarmKit coexistence probe</name>
  <files><create>`DeepMineProbe/App/AlarmProbe.swift`</create></files>
  <read_first>`docs/SPEC_v0.2.md` §10.5 and §18 item 3 plus the installed AlarmKit interface listed in task 2</read_first>
  <action>Request AlarmKit authorization and schedule a 60-second timer while the custom Live Activity can remain active. Preserve bounded authorization and scheduling diagnostics.</action>
  <seams><seam ref="alarm-coexistence" /><seam ref="probe-log" /></seams>
  <behavior>Denied authorization is isolated; authorized scheduling yields an alarm ID; an active custom LA remains available for collision observation.</behavior>
  <examples>Denied authorization logs `authorizationDenied` without ending an LA. Authorized scheduling records an alarm ID while `Activity.activities` remains non-empty.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build` exits 0; checklist item 3 remains `미검증` pending a device.</verify>
  <done>The app exposes a concurrent 60-second AlarmKit/Live Activity observation path.</done>
  <commit>feat(probe): add alarm coexistence check</commit>
</task>

<task id="6" depends="3" type="auto" kind="integration" status="done">
  <name>Implement Screen Time permission and shield probe</name>
  <files><create>`DeepMineProbe/App/ScreenTimeProbe.swift`</create><modify>`DeepMineProbe/Monitor/DeepMineDeviceActivityMonitor.swift`</modify></files>
  <read_first>`docs/SPEC_v0.2.md` §2 and §18 items 4–5 plus the installed FamilyControls, ManagedSettings, and DeviceActivity interfaces listed in task 2</read_first>
  <action>Request Individual authorization, persist picker selection, and protect app/monitor lifecycle operations with one App Group lock. Use a unique monitor name in each expiry journal so stale callbacks cannot clear a newer shield. Register the boundary and journal before applying shields, measure latency, roll back partial failure, and clear at matching interval end or startup fail-safe recovery.</action>
  <seams><seam ref="screen-time" /><seam ref="probe-log" /></seams>
  <behavior>Denial does not disable other probes; a non-empty selection maps to shields; manual clear and interval end both release shields.</behavior>
  <examples>Denied permission produces one error record. A selected application appears in shield settings and clear resets all settings.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -target DeepMineDeviceActivityMonitor -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` and `xcodebuild -project DeepMine.xcodeproj -target DeepMineProbe -sdk iphoneos CODE_SIGNING_ALLOWED=NO build` exit 0; checklist items 4–5 remain `미검증` pending entitlement/device evidence.</verify>
  <done>Authorization, picker, shield, latency, rollback, and fail-safe release operations compile and expose safe diagnostics.</done>
  <commit>feat(probe): add screen time checks</commit>
</task>

<task id="7" depends="2" type="auto" kind="behavior" status="done">
  <name>Implement App Group SwiftData consistency probe</name>
  <files><create>`DeepMineProbe/Shared/ProbeSharedWrite.swift`, `DeepMineProbe/Widget/ProbeCommandWidget.swift`, and `DeepMineProbe/Tests/ProbeSharedStoreTests.swift`</create><modify>`PROBE_CHECKLIST.md`</modify></files>
  <read_first>`docs/DEV_PLAYBOOK.md` P0 item 7, `docs/SPEC_v0.2.md` §18 item 10, and the installed SwiftData interface listed in task 2</read_first>
  <action>Place a minimal SwiftData container at an explicit App Group URL. Let a widget AppIntent insert and save a record; let the app fetch and acknowledge it on foreground. Do not preemptively substitute the future command-queue fallback. Replace `PROBE_CHECKLIST.md` item 10 with direct widget-to-app App Group SwiftData wording.</action>
  <seams><seam ref="shared-swiftdata" /></seams>
  <behavior>A saved widget record survives container recreation and is fetched by ID; the app does not claim cross-process consistency until device item 10 passes.</behavior>
  <examples>An in-memory insert/fetch round trip keeps UUID and source. A disk-backed test container reopened at the same temporary URL returns the saved record.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro iOS 26.5,OS=26.5' -only-testing:DeepMineProbeTests/ProbeSharedStoreTests test` exits 0; item 10 stays `미검증` for the real extension boundary.</verify>
  <done>Automated storage tests pass, checklist item 10 names direct SwiftData consistency, and the widget-to-app flow is ready for device verification.</done>
  <commit>test(probe): add shared swiftdata consistency check</commit>
</task>

<task id="8" depends="2" type="auto" kind="behavior" status="done">
  <name>Implement time-integrity observation</name>
  <files><create>`DeepMineProbe/Shared/ClockProbe.swift` and `DeepMineProbe/Tests/ClockProbeTests.swift`</create><modify>`PROBE_CHECKLIST.md`</modify></files>
  <read_first>`docs/SPEC_v0.2.md` §2.4 and §18 item 9 plus `docs/DEV_PLAYBOOK.md` P2 clock rules</read_first>
  <action>Abstract mach_continuous_time behind an injectable source and compare it with Date using a 30-second threshold. Classify normal drift as valid, threshold excess as tampered, and counter rollback as rebooted without downgrade. Replace `PROBE_CHECKLIST.md` item 9 with explicit `.valid/.tampered/.rebooted` acceptance.</action>
  <seams><seam ref="clock-observation" /></seams>
  <behavior>Signed drift is visible; exactly 30 seconds remains valid; more than 30 seconds is tampered; monotonic rollback is rebooted.</behavior>
  <examples>60s wall/54s monotonic is valid with +6s drift. 60s/29s is tampered. Counter rollback is rebooted with wall duration retained.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro iOS 26.5,OS=26.5' -only-testing:DeepMineProbeTests/ClockProbeTests test` exits 0.</verify>
  <done>Focused tests prove all three integrity classifications and checklist item 9 names their device acceptance behavior.</done>
  <commit>test(probe): cover continuous clock integrity</commit>
</task>

<task id="9" depends="4,5,6,7,8" type="auto" kind="integration" status="done">
  <name>Wire and inspect the accessible probe dashboard</name>
  <files><create>`DeepMineProbe/App/ProbeViewModel.swift`, `DeepMineProbe/App/ProbeDashboardView.swift`, and `artifacts/phase0/iphone-17-pro.png`</create><modify>`DeepMineProbe/App/DeepMineProbeApp.swift`, `BUILD_REPORT.md`, `PROBE_CHECKLIST.md`, `docs/PROJECT_STATUS.md`, `docs/TASKS.md`, and `docs/CHANGELOG.md`</modify></files>
  <read_first>`docs/DEV_PLAYBOOK.md`, `docs/CODE_REVIEW.md`, `DeepMineProbe/Shared/DeepMineActivityAttributes.swift`, `DeepMineProbe/Shared/LiveActivityLifecycle.swift`, `DeepMineProbe/Shared/PixelMinerIcon.swift`, `DeepMineProbe/Widget/ProbeIntents.swift`, `DeepMineProbe/Widget/DeepMineLiveActivityWidget.swift`, `DeepMineProbe/App/AlarmProbe.swift`, `DeepMineProbe/App/ScreenTimeProbe.swift`, `DeepMineProbe/Monitor/DeepMineDeviceActivityMonitor.swift`, `DeepMineProbe/Shared/ProbeSharedWrite.swift`, and `DeepMineProbe/Shared/ClockProbe.swift`</read_first>
  <action>Expose seven named probe groups and their latest states on one native scroll view. Preserve independent controls, errors, Dynamic Type, VoiceOver labels, high contrast, and foreground SwiftData refresh. Update evidence documents only from observed commands.</action>
  <seams><seam ref="probe-dashboard" /><seam ref="probe-log" /><seam ref="live-activity" /><seam ref="alarm-coexistence" /><seam ref="screen-time" /><seam ref="shared-swiftdata" /><seam ref="clock-observation" /></seams>
  <behavior>Every probe stays operable after another fails; large text wraps without hiding controls; foreground entry displays widget-written SwiftData records; safe error diagnostics remain selectable.</behavior>
  <examples>A FamilyControls error leaves AlarmKit enabled. xxxLarge text keeps every action visible by scrolling. Returning from the widget displays its record UUID.</examples>
  <verify>`xcodebuild -project DeepMine.xcodeproj -scheme DeepMineProbe -destination 'platform=iOS Simulator,name=Adelie iPhone 17 Pro iOS 26.5,OS=26.5' -derivedDataPath DerivedData/Phase0 test` and the generic build command from task 4 exit 0; `if rg -n 'TODO|FIXME|fatalError\(|preconditionFailure\(' DeepMineProbe; then exit 1; fi` exits 0; `xcrun simctl boot 'Adelie iPhone 17 Pro iOS 26.5' || true`, `xcrun simctl install booted DerivedData/Phase0/Build/Products/Debug-iphonesimulator/DeepMineProbe.app`, `xcrun simctl launch booted com.eiraworks.deepmine.probe`, and `xcrun simctl io booted screenshot artifacts/phase0/iphone-17-pro.png` succeed and the controller inspects the image.</verify>
  <done>The screenshot and commands show a complete seven-group dashboard without placeholder code; device-only behavior remains explicitly unverified.</done>
  <commit>feat(probe): complete phase zero dashboard</commit>
</task>

<task id="10" depends="9" type="checkpoint:verify" status="in_progress">
  <name>Verify Phase 0 on a physical iPhone within five business days</name>
  <files><modify>`PROBE_CHECKLIST.md`, `BUILD_REPORT.md`, `docs/PROJECT_STATUS.md`, and `docs/TASKS.md` after device observations</modify></files>
  <read_first>`PROBE_CHECKLIST.md` and `docs/SPEC_v0.2.md` §18</read_first>
  <action>Install on an iOS 26 Dynamic Island device and execute all ten observations, including permission variants, force termination, StandBy Night Mode, clock changes, and widget-to-app SwiftData round trip.</action>
  <verify>Within five business days every checklist row records pass/fail, device/OS, and exact behavior/error. Any #1 or #3 failure applies the documented spec response before P1; unresolved items remain named risks after the timebox.</verify>
  <done>The user supplies device results and explicitly authorizes or blocks P1 based on the gate.</done>
  <commit>none — checkpoint creates no commit</commit>
</task>

## Implementation state

**Execution base:** none — unborn repository
**Declared scope:** entire new `/Users/tofu/HermesWorkspace/project/DeepMine` tree
**Pre-existing dirty paths:** none — the target directory did not exist before this request
**Excluded metadata:** none; the plan and index are part of the initial baseline
**Commit posture:** initial baseline requested on 2026-07-29
**Last coherent commit:** none before the requested baseline commit
**Closeout:** generic iOS build and 13/13 automated tests passed on 2026-07-29; nine default-spec UI surfaces were inspected; physical-device checkpoint remains pending

## Decision log

- 2026-07-28: `Planned at` and execution base are `unborn` because the user requested a new folder and did not authorize an initial commit; drift cannot be SHA-verified and is not treated as clean.
- 2026-07-28: JSONL is limited to human-readable probe logs. Device item 10 uses direct App Group SwiftData exactly as the supplied P0 protocol requires; command-queue fallback is considered only after observed failure.
- 2026-07-28: Guarded review required process-wide log locking/retention, bounded diagnostics, and shield expiry rollback/recovery before automated closeout.
- 2026-07-29: The user requested the complete verified worktree as the initial local baseline commit; pushing remains out of scope.
- 2026-07-28: iOS 26.5 simulator tests passed 11/11 and the generic iOS build passed. The ad-hoc simulator products had empty signed entitlements, so App Group, FamilyControls, AlarmKit presentation, Live Activity, and DeviceActivity behavior remain physical-device evidence only.
- 2026-07-28: Independent review found cross-process races in LA replacement and stale shield callbacks. Both lifecycles now use App Group locks; shield journals carry a unique monitor name and a regression test proves stale removal is rejected.
- 2026-07-28: Design-skill audit replaced the generic repeated-card UI with a technical/industrial SHAFT hierarchy using the supplied fixed palette. App, Live Activity, and command widget now share the same status, miner, and data-link language; default and Accessibility Extra Large + Increase Contrast screenshots were inspected.
