export const MINING_PIXELS_PER_METER = 28;
export const CAMERA_FOLLOW_START_PROGRESS = 0.65;

export type MiningCameraPose = {
  cameraDepth: number;
  headDepth: number;
  headScreenOffsetPx: number;
};

function clampUnit(value: number): number {
  return Math.min(1, Math.max(0, value));
}

function smoothstep(value: number): number {
  const progress = clampUnit(value);
  return progress * progress * (3 - 2 * progress);
}

/**
 * Keeps the camera parked while the miner opens a new segment, then lets it
 * catch the head before breakthrough. This is derived rendering state: the
 * mine's economy and saved depth remain the only gameplay source of truth.
 */
export function miningCameraPose(
  baseDepth: number,
  segmentProgress: number,
  metersPerSegment: number,
  pixelsPerMeter = MINING_PIXELS_PER_METER,
): MiningCameraPose {
  const progress = clampUnit(segmentProgress);
  const headDepth = baseDepth + progress * metersPerSegment;
  const followWindow = (progress - CAMERA_FOLLOW_START_PROGRESS)
    / (1 - CAMERA_FOLLOW_START_PROGRESS);
  const cameraProgress = progress <= CAMERA_FOLLOW_START_PROGRESS
    ? 0
    : Math.min(progress, smoothstep(followWindow));
  const cameraDepth = baseDepth + cameraProgress * metersPerSegment;

  return {
    cameraDepth,
    headDepth,
    headScreenOffsetPx: (headDepth - cameraDepth) * pixelsPerMeter,
  };
}
