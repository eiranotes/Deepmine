import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

import { rigToolVisualState } from "../app/coreBalance.ts";
import {
  rigHousingAssetName,
  rigUpgradePhysicalDetail,
} from "../app/rigVisual.ts";

const projectRoot = new URL("../", import.meta.url).pathname;

test("every housing generation boundary swaps an authored web asset", () => {
  let previous = rigToolVisualState(1);
  for (let level = 2; level <= 40; level += 1) {
    const current = rigToolVisualState(level);
    if (current.generation !== previous.generation) {
      assert.notEqual(rigHousingAssetName(current), rigHousingAssetName(previous));
      assert.equal(
        existsSync(join(projectRoot, "public", rigHousingAssetName(current))),
        true,
        `level ${level} housing art must ship`,
      );
    }
    previous = current;
  }
});

test("early, service-cell, and housing upgrades name different physical work", () => {
  assert.equal(
    rigUpgradePhysicalDetail("drill", 1, 2),
    "D2 · T1→T2 본체 교체 · 정비 셀 1/4",
  );
  assert.equal(
    rigUpgradePhysicalDetail("drill", 2, 3),
    "D3 · 정비 셀 1→2/4 증설",
  );
  assert.equal(
    rigUpgradePhysicalDetail("drill", 4, 5),
    "D5 · G1 · 2형 하우징 교체",
  );
});

test("late generations keep changing silhouette even after the T3 drill cap", () => {
  const checkpoints = [5, 9, 13, 17].map((level) => {
    const visual = rigToolVisualState(level);
    return [visual.generation, visual.housingVariant, rigHousingAssetName(visual)];
  });
  assert.deepEqual(checkpoints, [
    [1, 2, "assets/rig/RigHousing_generation2.png"],
    [2, 3, "assets/rig/RigHousing_generation3.png"],
    [3, 4, "assets/rig/RigHousing_generation4.png"],
    [4, 1, "assets/rig/RigHousing_generation1.png"],
  ]);
});
