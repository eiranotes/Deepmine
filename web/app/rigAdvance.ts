export const MINING_PIXELS_PER_METER = 28;
export const RIG_UNLOCK_DURATION_MS = 140;
export const RIG_LOCK_DURATION_MS = 160;

export type RigDigPose = {
  cameraDepth: number;
  headDepth: number;
  headScreenOffsetPx: 0;
};

export type RigAdvanceMotion = {
  segments: number;
  meters: number;
  visualDistancePx: number;
  strataTravelPx: number;
  rigDipPx: number;
  unlockDurationMs: number;
  travelDurationMs: number;
  lockDurationMs: number;
  totalDurationMs: number;
};

/**
 * The cage is locked to one work face while the tool cuts it. Damage progress
 * belongs to the rock and HUD, not to an actor pretending to move through space.
 */
export function rigDigPose(
  baseDepth: number,
  segmentProgress: number,
  metersPerSegment: number,
): RigDigPose {
  const progress = Number.isFinite(segmentProgress)
    ? Math.min(1, Math.max(0, segmentProgress))
    : 0;
  const segmentMeters = Number.isFinite(metersPerSegment)
    ? Math.max(0, metersPerSegment)
    : 0;
  return {
    cameraDepth: baseDepth,
    headDepth: baseDepth + progress * segmentMeters,
    headScreenOffsetPx: 0,
  };
}

/**
 * A committed break releases the rail clamps, runs the winch, streams the
 * surrounding strata upward and locks the cage onto the next face. Large
 * catch-up batches compress many economic segments into one bounded machine
 * cycle instead of making a person fall repeatedly.
 */
export function rigAdvanceMotion(
  rawSegments: number,
  metersPerSegment: number,
  reducedMotion = false,
): RigAdvanceMotion {
  if (!Number.isFinite(rawSegments) || rawSegments <= 0) {
    throw new RangeError("rig advance requires at least one broken segment");
  }

  const segments = Math.max(1, Math.floor(rawSegments));
  const meters = segments * metersPerSegment;
  if (reducedMotion) {
    return {
      segments,
      meters,
      visualDistancePx: 0,
      strataTravelPx: 0,
      rigDipPx: 0,
      unlockDurationMs: 0,
      travelDurationMs: 0,
      lockDurationMs: 0,
      totalDurationMs: 1,
    };
  }

  const batchScale = Math.log2(segments);
  const visualDistancePx = Math.round(Math.min(260, 112 + batchScale * 42));
  const represented = Math.min(
    7168,
    segments * metersPerSegment * MINING_PIXELS_PER_METER,
  );
  const strataTravelPx = Math.max(0, represented - visualDistancePx);
  const rigDipPx = Math.round(Math.min(14, 7 + batchScale * 2));
  const travelDurationMs = Math.round(Math.min(900, 320 + batchScale * 140));

  return {
    segments,
    meters,
    visualDistancePx,
    strataTravelPx,
    rigDipPx,
    unlockDurationMs: RIG_UNLOCK_DURATION_MS,
    travelDurationMs,
    lockDurationMs: RIG_LOCK_DURATION_MS,
    totalDurationMs: RIG_UNLOCK_DURATION_MS + travelDurationMs + RIG_LOCK_DURATION_MS,
  };
}
