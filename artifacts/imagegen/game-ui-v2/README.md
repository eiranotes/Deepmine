# DeepMine game UI image assets

Generated with the built-in ImageGen tool on 2026-07-29. The selected sources are preserved beside this file; the app consumes palette-quantized, nearest-neighbor versions from `DeepMineProbe/App/Assets.xcassets`.

## Mine entry hero

- Use case: `stylized-concept`
- Asset type: wide iOS game hero background
- Prompt: 16-bit side-view mine entrance with a tiny miner, sealed gate, alarm bell, supply cart, rails, and a distant violet vein. Uniform pixel grid, hard edges, grayscale-readable composition, no text/UI/watermark, and the DeepMine fixed palette.
- Final processing: 384×216 nearest-neighbor reduction, fixed-palette remap, 3× nearest-neighbor export.

## Expedition gear

- Use case: `stylized-concept`
- Asset type: isolated game UI illustration
- Prompt: compact cluster of a lamp helmet, alarm bell, padlock, pocket watch, and supply chest on a flat green chroma-key background. Uniform 16-bit pixels, clear silhouettes, no text/UI/watermark.
- Final processing: chroma-key removal, square crop, 192×192 fixed-palette remap, 3× nearest-neighbor export.

## App icon

- Use case: `logo-brand`
- Asset type: iOS app icon master
- Prompt: symmetrical front-facing mine shaft with a circular black opening, stone arch, one violet crystal, and one warm lamp. Bold 16-bit silhouette, no text/UI/watermark, and no pre-rendered rounded-square mask.
- Final processing: 128×128 fixed-palette reduction, 8× nearest-neighbor export to an opaque 1024×1024 master; separate 40×40 legibility check retained with the sources.
