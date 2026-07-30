# DeepMine game MVP simulator evidence

This folder contains the deterministic Korean default-spec visual gate for the local game MVP.

- Device profile: iPhone 17 Pro simulator, iOS 26.5
- Appearance: dark
- Text size: default medium
- Contrast: standard
- Palette: coal `#10100F`, shale `#373630`, limestone `#E7E0CF`, brass `#C58C39`
- Coverage: onboarding, home, preflight, active mine, return, equipment, journal, statistics, themes, settings, prestige, Activity surfaces, lock-screen/StandBy-shaped content, home widgets, and Control fixture
- Files: `screens/01-onboarding.png` through `screens/19-control-center.png`
- Overview: `contact-sheet.png`
- Read-back: all 19 PNGs were visually inspected for clipping, unexpected alerts, palette drift, hierarchy, and state meaning

The Activity, lock-screen, StandBy, widget, and Control images are production-view fixtures. Actual SpringBoard placement, Dynamic Island lifecycle, lock-screen lifecycle, StandBy, Control Center registration, and App Group cross-process behavior require a physical-device gate.
