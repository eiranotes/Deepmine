import assert from "node:assert/strict";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

const projectRoot = new URL("../", import.meta.url).pathname;
const prototype = readFileSync(join(projectRoot, "app/MinePrototype.tsx"), "utf8");
const styles = readFileSync(join(projectRoot, "app/mine.module.css"), "utf8");

test("continuous shaft contract remains explicit", () => {
  assert.match(prototype, /boreHistory/);
  assert.match(prototype, /--rock-phase/);
  assert.match(prototype, /--surface-y/);
  assert.match(prototype, /passageHistory/);
  assert.match(prototype, /styles\.openShaft/);
  assert.match(prototype, /styles\.workLine/);
  assert.match(prototype, /headDepth\.toFixed\(1\)/);
  assert.match(styles, /\.rockWorld/);
  assert.match(styles, /top: var\(--workline\)/);
  assert.match(styles, /background-position: center var\(--rock-phase\)/);
  assert.doesNotMatch(prototype, /다음 약속|연속 일수|출정 횟수/);
});

test("automatic descent and page-wide tap acceleration stay explicit", () => {
  assert.match(prototype, /AUTO_STRIKE_MS/);
  assert.match(prototype, /STRIKE_CONTACT_MS/);
  assert.match(prototype, /automation \* \(AUTO_STRIKE_MS \/ 1000\)/);
  assert.match(prototype, /queueStrike/);
  assert.match(prototype, /onPointerDown=\{handleMinePointerDown\}/);
  assert.match(prototype, /onPointerUp=\{handleMinePointerUp\}/);
  assert.match(prototype, /isSecondaryControl/);
  assert.match(prototype, /자동 굴착 중/);
});

test("the first viewport closes the rock reward to equipment loop", () => {
  assert.match(prototype, /expectedLayerOre/);
  assert.match(prototype, /automaticBreakEta/);
  assert.match(prototype, /recommendedUpgrade/);
  assert.match(prototype, /파쇄 시 ◆/);
  assert.match(prototype, /지금 강화/);
  assert.match(prototype, /data-no-mine/);
  assert.match(styles, /\.quickLoop/);
  assert.match(styles, /\.workRewardPromise/);
  assert.match(styles, /\.quickUpgrade:focus-visible/);
});

test("each equipment owns a visible scene effect and a branch choice", () => {
  for (const kind of ["drill", "cart", "lamp"]) {
    assert.match(prototype, new RegExp(`${kind}: \\[`, "m"));
    assert.match(prototype, new RegExp(`Equipment_\\$\\{kind\\}_tier`));
  }
  assert.match(prototype, /continuousLamp/);
  assert.match(prototype, /continuousCart/);
  assert.match(prototype, /continuousDrill/);
  assert.match(prototype, /continuousDebris/);
  assert.match(prototype, /miningActor/);
  assert.match(prototype, /frontierLip/);
  assert.doesNotMatch(prototype, /styles\.miningPickaxe/);
  assert.match(styles, /--cart-duration/);
  assert.match(styles, /fortuneBuild/);
});

test("all prototype art is project-local and deployable", () => {
  const assets = [
    "public/assets/miner.png",
    "public/assets/shaft/ShaftSurface.png",
    "public/assets/shaft/ShaftGantry.png",
    "public/assets/shaft/ShaftRock_entry.png",
    "public/assets/shaft/ShaftRock_crystal.png",
    "public/assets/shaft/ShaftRock_ruins.png",
    "public/assets/shaft/ShaftRock_abyss.png",
    "public/assets/shaft/SeamVein.png",
    "public/assets/shaft/MiningPickaxe.png",
    "public/assets/shaft/ShaftFractureVertical_light.png",
    "public/assets/shaft/ShaftFractureVertical_medium.png",
    "public/assets/shaft/ShaftFractureVertical_heavy.png",
    "public/assets/shaft/MinerMiningStrip.png",
    "public/assets/shaft/ShaftFrontierLip.png",
    "public/og/deepmine-shaft-social.png",
  ];

  for (const asset of assets) {
    const path = join(projectRoot, asset);
    assert.equal(existsSync(path), true, `${asset} should exist`);
    assert.ok(statSync(path).size > 0, `${asset} should not be empty`);
  }
});
