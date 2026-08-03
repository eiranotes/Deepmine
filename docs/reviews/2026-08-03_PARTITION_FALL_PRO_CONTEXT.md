# DeepMine partition-break fall review context

Date: 2026-08-03
Repository: `github.com/eiranotes/Deepmine`
Public build: `https://eiranotes.github.io/Deepmine/`
Review authority: current implementation and current project docs first. `docs/SPEC_v0.2.md` is intentionally updated only after the implementation decision is settled.

## User direction

The current moving work face feels awkward. Keep the miner and work face composed inside one 4 m partition while the rock is destroyed from top to bottom. When the whole partition is broken, play a real fall into the next partition. If one hit, skill, or upgrade destroys several partitions, combine that result into one proportionally longer fall. Harder late-game rock should make falls less frequent without adding an artificial cooldown.

## Current published behavior being replaced

Decision D-081 derives `headDepth`, `cameraDepth`, and `headScreenOffsetPx` continuously from the current damage percentage. The miner, frontier lip, fracture, and open shaft descend during every hit; after 65% progress the camera catches up. This removed a modulo background jump, but it makes the work face itself appear to slide rather than making the character finish a rock partition and fall.

```ts
// web/app/miningCamera.ts, current published model
const headDepth = baseDepth + progress * metersPerSegment;
const followWindow = (progress - 0.65) / 0.35;
const cameraProgress = progress <= 0.65
  ? 0
  : Math.min(progress, smoothstep(followWindow));
const cameraDepth = baseDepth + cameraProgress * metersPerSegment;
const headScreenOffsetPx = (headDepth - cameraDepth) * pixelsPerMeter;
```

## Current economic truth and multi-break behavior

`MineState` is the sole gameplay state. `depth` is the start of the current 4 m face and advances immediately when a face is broken. One damage contact can cross several faces in the loop below. Rewards, depth, bore history, and remaining damage must stay immediate and deterministic; visual staging must not become a second gameplay state.

```ts
// web/app/MinePrototype.tsx, simplified current applyDamage loop
let damage = current.damage + rawDamage;
let depth = current.depth;
let broken = current.brokenLayers;
let faceIntegrity = integrityAt(depth);

while (damage >= faceIntegrity) {
  damage -= faceIntegrity;
  ore += layerOreAt(depth, payoutMultiplier);
  depth += 4;
  broken += 1;
  boreHistory = [...boreHistory, drillLevel].slice(-7);
  faceIntegrity = integrityAt(depth);
}
```

The existing effect only detects that `brokenLayers` increased and plays a fixed 560 ms collapse. It discards the segment delta:

```ts
if (mine.brokenLayers <= previousBrokenLayersRef.current) return;
previousBrokenLayersRef.current = mine.brokenLayers;
setIsBreaking(true);
playCollapseSound();
breakTimerRef.current = window.setTimeout(() => setIsBreaking(false), 560);
```

## Candidate event boundary for review

Keep `mine` as economic truth. Observe the committed `brokenLayers` delta and create a render-only fall event:

```ts
type PartitionFallEvent = {
  id: number;
  segments: number;
  fromDepth: number;
  toDepth: number;
  durationMs: number;
  visualDistancePx: number;
};

delta = mine.brokenLayers - previousBrokenLayers;
fromDepth = mine.depth - delta * 4;
toDepth = mine.depth;
```

A single contact that breaks N faces must produce one event with `segments=N`, not N separate 560 ms animations. If new automatic damage breaks more faces while a fall is active, it may be accumulated and consumed as the next combined fall; rewards and saved depth still update immediately. Screen travel should stay bounded, but duration, repeated strata motion, depth readout, and a `N개 구간 · 4N m` cue should communicate the full result.

## Visual target

1. Dig phase: work group remains at one stable partition contact point. Damage reveals a top-to-bottom excavation cut/fracture through the 4 m partition. Hits do not move the camera.
2. Break phase: the completed partition splits and clears.
3. Fall phase: the miner/rig drops and the world travels upward into the next face. A multi-segment result has a longer, more forceful fall without moving the actor outside the viewport.
4. Land phase: 6-10 px compression, dust/contact response, then the next face is stable before digging resumes.
5. Reduced Motion: instant partition swap plus an accessible `N개 구간 돌파 · 4N m 하강` status; no long spatial tween.

Existing assets available in the project are `MinerMiningStrip.png`, `ShaftFrontierLip.png`, `ShaftSurface.png`, entry rock, and light/medium/heavy vertical fractures. Prefer CSS/DOM composition first. Recommend a new fall/landing sprite only if the current four-frame mining strip cannot carry a credible freeze/fall/compress pose.

## Questions for the Pro review

1. What is the smallest robust single-source state/event architecture for one- and multi-partition breaks?
2. Give an exact dig -> break -> fall -> land timeline, including duration/distance scaling for 1, 2, 5, and 20 broken partitions.
3. How should new breaks be handled while a fall is already active so high DPS remains responsive without economic/visual mismatch?
4. Which DOM/CSS layers should move, and which should remain stable, to read as character fall rather than repeating static assets?
5. Are new sprite assets required now? If yes, specify frames, dimensions, anchors, and transparent-background requirements.
6. Define desktop, 390 px mobile, and Reduced Motion acceptance checks and likely edge cases.
