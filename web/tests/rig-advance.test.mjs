import assert from "node:assert/strict";
import test from "node:test";

import {
  MINING_PIXELS_PER_METER,
  rigDigPose,
  rigAdvanceMotion,
} from "../app/rigAdvance.ts";

const baseDepth = 8;
const segmentMeters = 4;

test("economic head depth advances while the cage and camera stay on one workline", () => {
  const start = rigDigPose(baseDepth, 0, segmentMeters);
  const middle = rigDigPose(baseDepth, 0.5, segmentMeters);
  const complete = rigDigPose(baseDepth, 1, segmentMeters);

  assert.deepEqual(start, {
    cameraDepth: baseDepth,
    headDepth: baseDepth,
    headScreenOffsetPx: 0,
  });
  assert.equal(middle.cameraDepth, baseDepth);
  assert.equal(middle.headDepth, baseDepth + 2);
  assert.equal(middle.headScreenOffsetPx, 0);
  assert.equal(complete.cameraDepth, baseDepth);
  assert.equal(complete.headDepth, baseDepth + segmentMeters);
});

test("invalid cutting progress cannot move the economic head outside the face", () => {
  assert.equal(rigDigPose(baseDepth, -2, segmentMeters).headDepth, baseDepth);
  assert.equal(rigDigPose(baseDepth, 8, segmentMeters).headDepth, baseDepth + segmentMeters);
  assert.equal(rigDigPose(baseDepth, Number.NaN, segmentMeters).headDepth, baseDepth);
});

test("one broken partition runs one physical lowering cycle", () => {
  const motion = rigAdvanceMotion(1, segmentMeters);

  assert.equal(motion.meters, 4);
  assert.equal(motion.visualDistancePx, MINING_PIXELS_PER_METER * segmentMeters);
  assert.equal(motion.strataTravelPx, 0);
  assert.equal(motion.rigDipPx, 7);
  assert.equal(motion.totalDurationMs, 620);
});

test("multi-break batches stream more strata but keep the cage bounded", () => {
  const one = rigAdvanceMotion(1, segmentMeters);
  const two = rigAdvanceMotion(2, segmentMeters);
  const five = rigAdvanceMotion(5, segmentMeters);
  const twenty = rigAdvanceMotion(20, segmentMeters);

  assert.deepEqual(
    [one.totalDurationMs, two.totalDurationMs, five.totalDurationMs, twenty.totalDurationMs],
    [620, 760, 945, 1200],
  );
  assert.deepEqual(
    [one.visualDistancePx, two.visualDistancePx, five.visualDistancePx, twenty.visualDistancePx],
    [112, 154, 210, 260],
  );
  assert.equal(twenty.meters, 80);
  assert.equal(twenty.strataTravelPx + twenty.visualDistancePx, 2240);
  assert.equal(twenty.rigDipPx, 14);
  assert.ok(twenty.visualDistancePx <= 260);
  assert.ok(twenty.totalDurationMs <= 1200);
});

test("Reduced Motion preserves the result while skipping spatial travel", () => {
  const motion = rigAdvanceMotion(5, segmentMeters, true);

  assert.equal(motion.segments, 5);
  assert.equal(motion.meters, 20);
  assert.equal(motion.visualDistancePx, 0);
  assert.equal(motion.strataTravelPx, 0);
  assert.equal(motion.rigDipPx, 0);
  assert.equal(motion.totalDurationMs, 1);
});

test("a lowering cycle cannot exist without a committed break", () => {
  assert.throws(() => rigAdvanceMotion(0, segmentMeters), RangeError);
  assert.throws(() => rigAdvanceMotion(Number.NaN, segmentMeters), RangeError);
});
