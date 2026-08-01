import assert from "node:assert/strict";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

const projectRoot = new URL("../", import.meta.url).pathname;
const prototype = readFileSync(join(projectRoot, "app/MinePrototype.tsx"), "utf8");
const styles = readFileSync(join(projectRoot, "app/mine.module.css"), "utf8");

test("continuous shaft contract remains explicit", () => {
  assert.match(prototype, /boreHistory/);
  assert.match(prototype, /--head-top/);
  assert.match(prototype, /47 \+ progress \* 18/);
  assert.match(prototype, /headDepth\.toFixed\(1\)/);
  assert.match(styles, /\.boreSegment/);
  assert.match(styles, /top: var\(--head-top\)/);
  assert.doesNotMatch(prototype, /다음 약속|연속 일수|출정 횟수/);
});

test("each equipment owns a visible scene effect and a branch choice", () => {
  for (const kind of ["drill", "cart", "lamp"]) {
    assert.match(prototype, new RegExp(`${kind}: \\[`, "m"));
    assert.match(prototype, new RegExp(`Equipment_\\$\\{kind\\}_tier`));
  }
  assert.match(prototype, /installedLamp/);
  assert.match(prototype, /movingCart/);
  assert.match(prototype, /drillRig/);
  assert.match(prototype, /debrisCloud/);
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
    "public/og/deepmine-shaft-social.png",
  ];

  for (const asset of assets) {
    const path = join(projectRoot, asset);
    assert.equal(existsSync(path), true, `${asset} should exist`);
    assert.ok(statSync(path).size > 0, `${asset} should not be empty`);
  }
});
