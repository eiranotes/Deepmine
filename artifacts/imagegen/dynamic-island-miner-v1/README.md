# Dynamic Island miner sprite v1

Generated with the built-in ImageGen tool, then processed locally for the DeepMine UI.

## Final prompt

```text
Use case: stylized-concept
Asset type: Dynamic Island compact-leading game sprite source, later reduced to a 24 x 24 logical pixel grid
Primary request: Generate one complete pixel-art miner character sprite for DeepMine, clearly more expressive than a geometric dot icon.
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background for removal; one uniform color, no shadow, no gradient, no texture, no floor.
Subject: a single small full-body underground miner in a strong readable silhouette, facing slightly right, wearing a broad hard hat with one brass headlamp, holding a short diagonal pickaxe over the right shoulder. Distinguishable helmet brim, face opening, torso, two separated boots, one arm, and pickaxe. Keep the pose compact and centered with generous padding.
Style/medium: authentic hand-placed 16-bit pixel-art game sprite, chunky square pixels of one consistent grid size, crisp hard edges, deliberately simplified clusters, no antialiasing, no subpixel texture, no painterly detail, no vector smoothness.
Color palette: subject uses only coal black #10100F, shale gray #373630, limestone #E7E0CF, and lamp brass #C58C39. Brass only on the lamp and one tiny equipment accent. Do not use #00FF00 in the subject.
Composition/framing: exactly one sprite, centered, isolated, square canvas, no sprite sheet, no alternate poses, no border, no badge, no background scenery.
Constraints: must remain recognizable when reduced to 24 x 24 pixels; prioritize silhouette and pickaxe over facial detail; transparent extraction-ready; no cast shadow, no contact shadow, no reflection.
Avoid: text, letters, numbers, watermark, UI frame, circle container, gradients, glow, neon colors, extra tools, extra characters, scattered particles, realistic rendering, 3D rendering.
```

## Pipeline

1. Built-in ImageGen source on removable green chroma key.
2. Chroma-key removal with the ImageGen skill helper.
3. Nearest-neighbor reduction to a 24×24 logical grid.
4. RGB remap to coal `#10100F`, shale `#373630`, limestone `#E7E0CF`, and lamp brass `#C58C39`.
5. Binary alpha cleanup and nearest-neighbor 48×48 / 72×72 exports.

The production files are copied to `DeepMineProbe/Shared/SharedAssets.xcassets/MinerSprite.imageset` and are shared by the app and Widget Extension.
