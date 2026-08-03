import assert from "node:assert/strict";
import test from "node:test";

import {
  MINING_PIXELS_PER_METER,
  partitionDigPose,
  partitionFallMotion,
} from "../app/partitionFall.ts";

const baseDepth = 8;
const segmentMeters = 4;

test("digging stays staged in one partition until the face breaks", () => {
  const start = partitionDigPose(baseDepth, 0, segmentMeters);
  const middle = partitionDigPose(baseDepth, 0.5, segmentMeters);
  const complete = partitionDigPose(baseDepth, 1, segmentMeters);

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

test("one broken partition travels one real 4m screen distance", () => {
  const motion = partitionFallMotion(1, segmentMeters);

  assert.equal(motion.meters, 4);
  assert.equal(motion.visualDistancePx, MINING_PIXELS_PER_METER * segmentMeters);
  assert.equal(motion.strataTravelPx, 0);
  assert.equal(motion.actorDropPx, 46);
  assert.equal(motion.totalDurationMs, 760);
});

test("multi-break falls become longer but remain viewport bounded", () => {
  const one = partitionFallMotion(1, segmentMeters);
  const two = partitionFallMotion(2, segmentMeters);
  const five = partitionFallMotion(5, segmentMeters);
  const twenty = partitionFallMotion(20, segmentMeters);

  assert.deepEqual(
    [one.totalDurationMs, two.totalDurationMs, five.totalDurationMs, twenty.totalDurationMs],
    [760, 940, 1178, 1538],
  );
  assert.deepEqual(
    [one.visualDistancePx, two.visualDistancePx, five.visualDistancePx, twenty.visualDistancePx],
    [112, 162, 228, 300],
  );
  assert.equal(twenty.meters, 80);
  assert.equal(twenty.strataTravelPx + twenty.visualDistancePx, 2240);
  assert.equal(twenty.actorDropPx, 72);
  assert.ok(twenty.visualDistancePx <= 300);
  assert.ok(twenty.totalDurationMs < 1600);
});

test("Reduced Motion preserves the result while skipping spatial travel", () => {
  const motion = partitionFallMotion(5, segmentMeters, true);

  assert.equal(motion.segments, 5);
  assert.equal(motion.meters, 20);
  assert.equal(motion.visualDistancePx, 0);
  assert.equal(motion.strataTravelPx, 0);
  assert.equal(motion.actorDropPx, 0);
  assert.equal(motion.totalDurationMs, 1);
});

test("a partition fall cannot be created without a committed break", () => {
  assert.throws(() => partitionFallMotion(0, segmentMeters), RangeError);
  assert.throws(() => partitionFallMotion(Number.NaN, segmentMeters), RangeError);
});
