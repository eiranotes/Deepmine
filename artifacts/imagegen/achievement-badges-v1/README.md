# Achievement badge image generation

- Generated: 2026-07-30
- Mode: built-in `imagegen`
- Prompt source: `docs/ACHIEVEMENT_ART_PROMPTS.md`
- Output: 35 opaque PNG badge sets in `SharedAssets.xcassets`
- Palette: `#10100F`, `#373630`, `#E7E0CF`, `#C58C39`

Each ID was generated in a separate built-in image-generation call. The shared style block from
the prompt document was normalized into a production prompt with these fixed constraints:

- square DeepMine achievement badge source art
- flat coal background and only the D-013 four-color palette
- front-facing, chunky pixel-art silhouette readable at 48 px
- one restrained brass focal element
- no text, watermark, gradients, soft effects, 3D rendering, or decorative badge frame

The exact per-ID subjects remain the table in `docs/ACHIEVEMENT_ART_PROMPTS.md`. Small wording
clarifications only prevented tally marks from becoming text, represented glass as solid limestone
pixels, and grouped repeated brass hardware into one visual focal assembly.

## Contents

- `sources/`: the 35 unmodified 1254×1254 built-in generation results
- `sources.json`: stable ID-to-source mapping
- `verification.json`: output dimensions, colors, and imageset paths
- `contact-sheet.png`: 48 px output enlarged with nearest-neighbor for visual review

## Rebuild

From the repository root:

```sh
python3 scripts/process_achievement_badges.py \
  --manifest artifacts/imagegen/achievement-badges-v1/sources.json \
  --catalog DeepMineProbe/Shared/SharedAssets.xcassets \
  --contact-sheet artifacts/imagegen/achievement-badges-v1/contact-sheet.png \
  --report artifacts/imagegen/achievement-badges-v1/verification.json
```

The processor quantizes without dithering, creates a 96×96 logical grid, and exports opaque
48×48, 96×96, and 144×144 PNG files with nearest-neighbor scaling.
