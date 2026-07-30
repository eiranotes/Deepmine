# DeepMine mine UI v3 evidence

Captured on `Adelie iPhone 17 Pro iOS 26.5` at the default `medium` content size, dark appearance, and standard contrast.

## Screens

- `screens/01-overview.png`
- `screens/02-return-signal.png`
- `screens/03-mine-gate.png`
- `screens/04-time-and-supplies.png`
- `screens/05-mining-journal.png`
- `screens/06-device-gate.png`
- `screens/07-dynamic-island-compact.png`
- `screens/08-dynamic-island-expanded.png`
- `screens/09-lock-screen-live-activity.png`

The current visual pass intentionally does not include an accessibility-extra-large capture. Dynamic Type support remains in code, but the user requested default-spec visual testing for this iteration.

The lock-screen image renders the exact `ProbeLockScreenContent` shared by the Widget Extension inside its 160pt content constraint. Simulator's `Device → Lock` command was disabled, so it does not prove SpringBoard's final composition, system crop behavior, or the physical-device lifecycle.

The current nine screenshots use the generated `MinerSprite` asset instead of the earlier code-drawn rectangle silhouette. Its source and 24×24 four-pigment processing evidence are in `artifacts/imagegen/dynamic-island-miner-v1/`.

The latest closeout result bundle remains ignored build evidence: 11 unit tests and two UI tests pass. The UI suite proves the app started a Live Activity, returned to SpringBoard, rendered the compact Dynamic Island, expanded it by long press, and rendered the shared lock-screen content. It does not prove AlarmKit coexistence, approved FamilyControls/App Group entitlements, or physical-device lifecycle behavior.
