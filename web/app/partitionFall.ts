export const MINING_PIXELS_PER_METER = 28;
export const PARTITION_BREAK_DURATION_MS = 180;
export const PARTITION_LANDING_DURATION_MS = 220;

export type PartitionDigPose = {
  cameraDepth: number;
  headDepth: number;
  headScreenOffsetPx: 0;
};

export type PartitionFallMotion = {
  segments: number;
  meters: number;
  visualDistancePx: number;
  strataTravelPx: number;
  actorDropPx: number;
  breakDurationMs: number;
  travelDurationMs: number;
  landingDurationMs: number;
  totalDurationMs: number;
};

function clampUnit(value: number): number {
  return Math.min(1, Math.max(0, value));
}

/**
 * Damage still advances the numeric head depth inside a partition, but the
 * camera and mining rig remain staged at one stable contact point. Spatial
 * movement is reserved for a committed partition-break event.
 */
export function partitionDigPose(
  baseDepth: number,
  segmentProgress: number,
  metersPerSegment: number,
): PartitionDigPose {
  const progress = clampUnit(segmentProgress);
  return {
    cameraDepth: baseDepth,
    headDepth: baseDepth + progress * metersPerSegment,
    headScreenOffsetPx: 0,
  };
}

/**
 * Communicates every broken segment without letting large late-game hits send
 * the actor outside the viewport. Distance and time grow logarithmically: one
 * face travels its real 112 px, while large batches gain a longer stream of
 * strata, a depth/count cue, and a bounded landing.
 */
export function partitionFallMotion(
  rawSegments: number,
  metersPerSegment: number,
  reducedMotion = false,
): PartitionFallMotion {
  if (!Number.isFinite(rawSegments) || rawSegments <= 0) {
    throw new RangeError("partition fall requires at least one broken segment");
  }

  const segments = Math.max(1, Math.floor(rawSegments));
  const meters = segments * metersPerSegment;
  if (reducedMotion) {
    return {
      segments,
      meters,
      visualDistancePx: 0,
      strataTravelPx: 0,
      actorDropPx: 0,
      breakDurationMs: 0,
      travelDurationMs: 0,
      landingDurationMs: 0,
      totalDurationMs: 1,
    };
  }

  const batchScale = Math.log2(segments);
  const visualDistancePx = Math.round(Math.min(300, 112 + batchScale * 50));
  const representedWorldDistancePx = Math.min(7168, segments * metersPerSegment * MINING_PIXELS_PER_METER);
  const strataTravelPx = Math.max(0, representedWorldDistancePx - visualDistancePx);
  const actorDropPx = Math.round(Math.min(72, 46 + batchScale * 8));
  const travelDurationMs = Math.round(Math.min(1160, 360 + batchScale * 180));
  const breakDurationMs = PARTITION_BREAK_DURATION_MS;
  const landingDurationMs = PARTITION_LANDING_DURATION_MS;

  return {
    segments,
    meters,
    visualDistancePx,
    strataTravelPx,
    actorDropPx,
    breakDurationMs,
    travelDurationMs,
    landingDurationMs,
    totalDurationMs: breakDurationMs + travelDurationMs + landingDurationMs,
  };
}
