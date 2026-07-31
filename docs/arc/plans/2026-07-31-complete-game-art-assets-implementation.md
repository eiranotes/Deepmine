# Complete Game Art Assets Implementation

Status: IN PROGRESS
Priority: P1
Effort: L
Assurance: Standard
Created: 2026-07-31
Last touched: 2026-07-31
Source: User request, `docs/PIXEL_ART_PROMPTS.md`, current SwiftUI surfaces

## Goal

Generate and integrate the remaining 40 PNG-only game-art assets so DeepMine's
progression, resources, equipment, themes, activities, decorations, prestige,
and onboarding use one coherent four-pigment visual system.

## Product and Art Contract

- Palette: coal `#10100F`, shale `#373630`, limestone `#E7E0CF`, brass `#C58C39`.
- Brass stays below 10% of opaque pixels and is used as a focal accent.
- Outputs are PNG only, nearest-neighbor resized, and validated mechanically.
- Compact sprites use binary alpha. Scene art is opaque and keeps UI-safe zones.
- Existing safe-plan `MinerSprite` remains the safe-plan source of truth.
- Existing achievement badge work remains in place and is not regenerated.
- No persistence schema, activity payload version, or localization catalog change.

## Inventory

| Family | Count | Asset names |
|---|---:|---|
| Veins | 5 | `Vein_blue`, `Vein_crystal`, `Vein_vault`, `Vein_resonance`, `Vein_abyss` |
| Equipment | 9 | `Equipment_{drill,cart,lamp}_tier{1,2,3}` |
| Theme scenes | 4 | `ThemeScene_{entry,crystal,ruins,abyss}` |
| Decorations | 4 | `Decoration_{marker,rail,lamp,cart}` |
| Miner plan variants | 2 | `MinerPlan_{deep,survey}` |
| Dynamic Island banners | 4 | `DIBanner_{entry,crystal,ruins,abyss}` |
| StandBy backgrounds | 4 | `StandBy_{entry,crystal,ruins,abyss}` |
| Resources | 3 | `Resource_{ore,crystal,coreShard}` |
| Permanent upgrades | 3 | `PermanentUpgrade_{excavationMemory,resonanceDetection,compressedTime}` |
| Onboarding | 2 | `Onboarding_{blocks,sessions}` |

## Affected Areas

- `docs/PIXEL_ART_PROMPTS.md`
- `scripts/process_game_assets.py`
- `artifacts/imagegen/game-assets-v1/`
- `DeepMineProbe/Shared/SharedAssets.xcassets/`
- SwiftUI presentation files under `DeepMineApp/Views/`,
  `DeepMineApp/DesignSystem/`, and `DeepMineProbe/Shared/`
- Focused app tests and project status documentation

## Existing Implementation to Inspect

- Region/theme/decorations: `DeepMineCore/.../WorldProgression.swift`
- Equipment/vein models: `DeepMineCore/.../GameTypes.swift`
- Activity snapshot seam: `DeepMineProbe/Shared/GameSurfaceSnapshot.swift`
- App surfaces: home, active mine, return report, progress, equipment, prestige,
  onboarding, theme, and decoration views
- System surfaces: compact/expanded Dynamic Island and StandBy content

## Baseline and Ownership

Implementation baseline: `40d2119dbeec851b8da4034925cb292217992689`

Attributable pre-plan work from this task:

- 35 achievement imagesets under
  `DeepMineProbe/Shared/SharedAssets.xcassets/AchievementBadge_*.imageset/`
- `artifacts/imagegen/achievement-badges-v1/`
- `scripts/process_achievement_badges.py`
- Achievement presentation and related report/status/task/changelog edits

Pre-existing or separately owned dirty files excluded from this plan:

- `DeepMine.xcodeproj/project.pbxproj`
- `DeepMine.xcodeproj/xcshareddata/xcschemes/DeepMineApp.xcscheme`
- `DeepMineApp/Resources/Localizable.xcstrings`

Those excluded files must not be edited, generated, reverted, staged, or treated
as evidence for this implementation.

## Implementation Slices

### 1. Refresh the authoring contract and manifest

- Reconcile `docs/PIXEL_ART_PROMPTS.md` with the four-pigment design decision,
  four shipped regions, equipment levels 1–60, and the complete inventory.
- Add a manifest-driven processing script with exact size, palette, alpha, and
  filename validation.

Acceptance:

- Documentation and manifest enumerate the same 40 asset IDs.
- A mechanical validation command fails on missing, non-PNG, wrong-size,
  off-palette, or invalid-alpha output.
- Every manifest entry records its final prompt, distinct raw ImageGen source,
  processed source, family contract, and installed imageset; placeholders and
  duplicated stand-ins are rejected.
- Family contracts declare exact logical and 1x/2x/3x dimensions, opacity policy,
  binary-alpha policy where applicable, brass-pixel ratio below 10%, and complete
  `Contents.json` filename/scale mappings.

### 2. Generate and process compact art

- Generate veins, equipment, decorations, miner variants, resources, permanent
  upgrades, and onboarding illustrations.
- Remove chroma for transparent families, quantize, resize, and install imagesets.

Acceptance:

- 28 compact/onboarding assets have valid 1x/2x/3x PNG renditions.
- Transparent families use binary alpha and exact RGB pigments.
- Equipment tiers map levels 1–20, 21–40, and 41–60; tests cover 1, 20, 21,
  40, 41, 60, and clamped invalid values.

### 3. Generate and process scene art

- Generate four theme scenes, four Dynamic Island banners, and four StandBy
  backgrounds.
- Crop to declared aspect ratios, preserve UI-safe zones, quantize, and install.

Acceptance:

- 12 scene assets have valid opaque 1x/2x/3x PNG renditions.
- Contact sheets demonstrate four visibly distinct regions at target aspect ratio.
- Overlay masks demonstrate the Dynamic Island top-center exclusion and StandBy
  left-third safe area after final cropping; grayscale inspection remains legible.
- Mining-time scene art is phase-neutral and does not disclose a rare vein or
  reward before session completion.

### 4. Integrate art into presentation seams

- Centralize model-to-asset naming helpers.
- Replace generic SF Symbol placeholders where the new custom asset is the
  product identity, while retaining semantic/system symbols where appropriate.
- Apply selected theme art to app mine surfaces and region-specific art to
  activity surfaces using existing snapshot fields.

Acceptance:

- All 40 asset IDs have at least one concrete SwiftUI consumer or an explicit
  tier/region selection path.
- No persistence or activity schema version changes.
- Existing accessibility labels remain meaningful.
- Unknown raw `planID`, `regionID`, and `veinID` values use tested safe fallbacks
  instead of resolving to missing image names.
- Decorative images are accessibility-hidden; identity-bearing rows retain
  combined localized labels and foreground controls remain readable in grayscale
  and Increase Contrast.

### 5. Verify and close documentation

- Run the asset validator and focused tests first, then project test/build checks.
- Render contact sheets and recapture relevant UI fixtures where available.
- Update build report, status, tasks, changelog, this plan, and plan index.

Acceptance:

- Asset validator passes for all 40 assets.
- Focused and broader checks pass, or exact environmental blockers are recorded.
- The implementation receives a fresh whole-change review before closeout.
- Deterministic rendered evidence covers all four region scenes/banners/StandBy
  backgrounds, all three miner plans, all three equipment tiers, both onboarding
  pages, theme selection, decorations, veins, resources, and permanent upgrades.
- The stale 19-screen artifact set is recaptured. Actual Dynamic Island hardware
  and StandBy Night Mode readability remain `미검증(실기기 필요)` unless tested
  on a physical device.

## Risk Points

- Generated art may contain antialiasing or extra colors before quantization.
- Wide scene generation may crop important detail; safe zones must be validated
  after final aspect-ratio processing.
- Shared activity views have constrained layouts; backgrounds must preserve
  contrast and Night Mode readability.
- Asset catalog changes must compile without regenerating project files.
- Existing dirty work must remain intact and distinguishable.

## Verification Path

1. `python3 scripts/process_game_assets.py --validate-only`
2. Inspect generated contact sheets at target resolution.
3. Run focused app/unit tests covering asset-name mappings.
4. Run `swift test` for `DeepMineCore`.
5. Run the existing Xcode test suite without project regeneration.
6. Run `xcodebuild -scheme DeepMineApp -destination 'generic/platform=iOS' build`
   so both app and widget/activity asset consumers compile.
7. Recapture the deterministic 19-screen simulator fixture set.
8. Review `git diff` and confirm excluded dirty files are unchanged.

## Documentation to Update

- `docs/PIXEL_ART_PROMPTS.md`
- `BUILD_REPORT.md`
- `docs/PROJECT_STATUS.md`
- `docs/TASKS.md`
- `docs/CHANGELOG.md`
- This plan and `docs/arc/plans/INDEX.md`

## Decisions

- 2026-07-31: Use Standard assurance because this is a visual/artifact and
  presentation integration with no versioned data-contract change.
- 2026-07-31: Keep the existing safe miner sprite and generate only deep/survey
  variants.
- 2026-07-31: Treat all 40 assets as one coherent delivery, while processing
  compact and scene families as independent evidence-producing slices.
- 2026-07-31: Plan review corrected compact inventory to 28, fixed equipment
  tier boundaries at 1–20/21–40/41–60, and made provenance, fallback, safe-zone,
  accessibility, and rendered-evidence requirements explicit.

## Evidence

Pending.
