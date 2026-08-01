# Final ImageGen Prompts

## MinerMiningStrip

```text
Use case: stylized-concept
Asset type: 2D pixel-art game animation sprite sheet
Input images: Image 1 is the exact DeepMine miner character identity and palette reference.
Primary request: Create one horizontal sprite strip containing exactly four evenly spaced, equal-width animation frames of the same miner performing one forceful downward pickaxe strike.
Frame order left to right: 1 neutral ready stance with both feet planted and both hands gripping the pickaxe; 2 anticipation with knees bent, torso twisted back, shoulders and pickaxe raised; 3 impact with the whole torso lunging down, front knee compressed, boots grounded, arms driving the pickaxe head into one exact point directly below and slightly right of the miner; 4 recoil with shoulders pulled back while both hands still grip the tool.
Subject: preserve the miner's helmet lamp, face, proportions, dark work clothes, brass trim and boots from Image 1. The pickaxe is part of every frame and remains physically connected to both hands.
Style/medium: crisp chunky low-resolution pixel art, orthographic side view, game-ready animation keys, no antialiasing look.
Composition/framing: four equal cells in a single straight horizontal row; identical ground baseline, identical character scale and camera in every cell; generous padding; no dividers or labels.
Color palette: only near-black #10100F, shale #373630, limestone #E7E0CF, sparse brass #C58C39. Never use the background key color in the subject.
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background for local removal.
Constraints: background is one uniform #00FF00 with no shadows, gradients, texture, floor plane, lighting variation or seams. Strong readable silhouettes. Exactly one miner and one pickaxe per frame. Hands must stay attached to the handle; feet must convey planted weight. No text, no numbers, no UI, no watermark, no extra tools, no detached limbs, no motion blur, no cast shadow.
```

Reference image: `web/public/assets/miner.png`

## ShaftFrontierLip

```text
Use case: stylized-concept
Asset type: transparent 2D pixel-art game environment overlay
Input images: Image 1 is the exact DeepMine entry-rock texture and four-pigment style reference, not an edit target.
Primary request: Create a panoramic front-facing mine working-frontier overlay that visually joins an already-open vertical tunnel above to the solid unbroken rock below.
Subject: two broad connected rock shoulders at left and right, their inner edges forming one irregular jagged U-shaped tunnel throat in the upper center. The upper central 32 percent must remain completely empty chroma background so it reads as the same open shaft continuing downward. Both shoulders must visibly merge into a single rough rock lip across the lower third. At the exact bottom center of the U, add a small chipped contact notch where a vertical crack can begin below. Include a few attached rubble teeth and one sparse brass glint, but no detached floating debris.
Style/medium: crisp chunky orthographic pixel art matching Image 1's connected sedimentary strata, straight-on game layer, no antialiasing look.
Composition/framing: wide 5:2 overlay, full width. Rock mass touches the far left and far right edges. The central tunnel opening is symmetrical only in overall placement but organically jagged. Keep the bottom center readable and unobstructed for a crack overlay.
Color palette: only near-black #10100F, shale #373630, limestone #E7E0CF, sparse brass #C58C39. Never use the key color in the rock.
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background for local removal.
Constraints: one uniform #00FF00 background with no shadow, gradient, texture, floor plane or lighting variation. The upper center must be green/empty, not filled with black. No frame, gantry, rails, props, character, tool, text, UI, glow, watermark, separate boulders, horizontal rectangular platform, or flat straight cut line.
```

Reference image: `web/public/assets/shaft/ShaftRock_entry.png`
