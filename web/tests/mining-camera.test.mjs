import assert from "node:assert/strict";
import test from "node:test";

import {
  CAMERA_FOLLOW_START_PROGRESS,
  MINING_PIXELS_PER_METER,
  miningCameraPose,
} from "../app/miningCamera.ts";

const baseDepth = 8;
const segmentMeters = 4;

test("the miner descends before the camera starts following", () => {
  const start = miningCameraPose(baseDepth, 0, segmentMeters);
  const quarter = miningCameraPose(baseDepth, 0.25, segmentMeters);
  const followStart = miningCameraPose(
    baseDepth,
    CAMERA_FOLLOW_START_PROGRESS,
    segmentMeters,
  );

  assert.deepEqual(start, {
    cameraDepth: baseDepth,
    headDepth: baseDepth,
    headScreenOffsetPx: 0,
  });
  assert.equal(quarter.cameraDepth, baseDepth);
  assert.equal(quarter.headScreenOffsetPx, 28);
  assert.ok(followStart.headScreenOffsetPx >= 70);
  assert.ok(followStart.headScreenOffsetPx <= 80);
});

test("the camera catches the head without leading it", () => {
  const offsets = Array.from({ length: 101 }, (_, index) => {
    const pose = miningCameraPose(baseDepth, index / 100, segmentMeters);
    assert.ok(pose.cameraDepth <= pose.headDepth);
    assert.ok(pose.headScreenOffsetPx >= 0);
    return pose.headScreenOffsetPx;
  });

  assert.ok(offsets[75] < offsets[65]);
  assert.ok(offsets[90] < offsets[75]);
  assert.ok(Math.abs(offsets[75] - 61.8) < 0.2);
  assert.ok(Math.abs(offsets[85] - 27.3) < 0.2);
  assert.equal(offsets[100], 0);
});

test("one complete segment resolves to the next face with no screen drift", () => {
  const complete = miningCameraPose(baseDepth, 1, segmentMeters);

  assert.equal(complete.headDepth, baseDepth + segmentMeters);
  assert.equal(complete.cameraDepth, complete.headDepth);
  assert.equal(complete.headScreenOffsetPx, 0);
  assert.equal(MINING_PIXELS_PER_METER * segmentMeters, 112);
});
