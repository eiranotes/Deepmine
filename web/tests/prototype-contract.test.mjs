import assert from "node:assert/strict";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

const projectRoot = new URL("../", import.meta.url).pathname;
const prototype = readFileSync(join(projectRoot, "app/MinePrototype.tsx"), "utf8");
const styles = readFileSync(join(projectRoot, "app/mine.module.css"), "utf8");
const resonance = readFileSync(join(projectRoot, "app/useResonanceEvent.ts"), "utf8");
const resonanceView = readFileSync(join(projectRoot, "app/ResonanceEvent.tsx"), "utf8");
const strikeFeedback = readFileSync(join(projectRoot, "app/strikeFeedback.ts"), "utf8");
const partitionFall = readFileSync(join(projectRoot, "app/partitionFall.ts"), "utf8");
const miningAudio = readFileSync(join(projectRoot, "app/useMiningAudio.ts"), "utf8");
const pagesEntry = readFileSync(join(projectRoot, "pages-game/main.tsx"), "utf8");
const pagesConfig = readFileSync(join(projectRoot, "vite.pages.config.ts"), "utf8");
const pagesWorkflow = readFileSync(join(projectRoot, "../.github/workflows/pages.yml"), "utf8");

test("GitHub Pages ships the playable React game instead of the logic report", () => {
  assert.match(pagesEntry, /MinePrototype/);
  assert.match(pagesConfig, /\/Deepmine\//);
  assert.match(pagesWorkflow, /npm run build:pages/);
  assert.match(pagesWorkflow, /DEEPMINE \/ PLAYABLE WEB/);
  assert.doesNotMatch(pagesWorkflow, /cp pages-static/);
  assert.doesNotMatch(pagesWorkflow, /rg -q/);
});

test("the playable web game begins before automation and follows the Core recommendation", () => {
  assert.match(prototype, /initialEquipment: EquipmentState = \{ drill: 1, cart: 1, lamp: 1 \}/);
  assert.match(prototype, /recommendMiningUpgrade\(equipment, mine\.ore, mine\.depth\)/);
  assert.match(prototype, /automation > 0 \? "자동 굴착 중" : "직접 타격"/);
});

test("partition break and fall contract remains explicit", () => {
  assert.match(prototype, /boreHistory/);
  assert.match(prototype, /--rock-phase/);
  assert.doesNotMatch(prototype, /cameraDepth \* PIXELS_PER_METER\) % 320/);
  assert.match(prototype, /--surface-y/);
  assert.match(prototype, /data-camera-depth=\{cameraDepth\.toFixed\(2\)\}/);
  assert.match(prototype, /data-fall-segments=\{fallEvent\?\.segments \?\? 0\}/);
  assert.match(prototype, /\(depth - cameraDepth\) \* PIXELS_PER_METER/);
  assert.match(prototype, /partitionDigPose\(mine\.depth, progress, METERS_PER_LAYER\)/);
  assert.match(prototype, /partitionFallMotion/);
  assert.match(partitionFall, /Math\.log2\(segments\)/);
  assert.match(prototype, /passageHistory/);
  assert.match(prototype, /styles\.openShaft/);
  assert.match(prototype, /styles\.workLine/);
  assert.match(prototype, /displayedHeadDepth\.toFixed\(1\)/);
  assert.match(styles, /\.rockWorld/);
  assert.match(styles, /@keyframes partition-world-fall/);
  assert.match(styles, /@keyframes miner-partition-fall/);
  assert.match(styles, /background-position: center var\(--rock-phase\)/);
  assert.doesNotMatch(prototype, /다음 약속|연속 일수|출정 횟수/);
});

test("automatic descent and page-wide tap acceleration stay explicit", () => {
  assert.match(prototype, /AUTO_STRIKE_MS/);
  assert.match(prototype, /strikeTiming/);
  assert.match(prototype, /automation \* \(AUTO_STRIKE_MS \/ 1000\)/);
  assert.match(prototype, /queueStrike/);
  assert.match(prototype, /onPointerDown=\{handleMinePointerDown\}/);
  assert.match(prototype, /onPointerUp=\{handleMinePointerUp\}/);
  assert.match(prototype, /isSecondaryControl/);
  assert.match(prototype, /자동 굴착 중/);
});

test("strike poses, contact feedback, and damage share one timing contract", () => {
  assert.match(strikeFeedback, /quick: \{ durationMs: 560, contactMs: 202 \}/);
  assert.match(strikeFeedback, /heavy: \{ durationMs: 690, contactMs: 249 \}/);
  assert.match(strikeFeedback, /critical: \{ durationMs: 760, contactMs: 274 \}/);
  assert.match(strikeFeedback, /REDUCED_STRIKE_TIMING/);
  assert.match(prototype, /manualStrikeGuardUntilRef/);
  assert.match(prototype, /pendingAutomaticDamageRef\.current \+= automaticDamage/);
  assert.match(prototype, /rawDamage \+ pendingAutomaticDamage/);
  assert.match(prototype, /data-strike-variant=\{strikeVariant\}/);
  assert.match(prototype, /playStrikeSound\(variant\)/);
  assert.match(prototype, /playCollapseSound\(\)/);
  assert.match(prototype, /aria-pressed=\{soundEnabled\}/);
  assert.match(styles, /--strike-contact-delay/);
  assert.match(styles, /miner-heavy-strike/);
  assert.match(styles, /miner-critical-strike/);
  assert.match(prototype, /data-impact-coverage="wide"/);
  assert.match(prototype, /styles\.strikeArc/);
  assert.match(prototype, /styles\.impactField/);
  assert.match(styles, /width: min\(76%, 570px\)/);
  assert.match(styles, /impact-wave/);
  assert.match(styles, /impact-branch/);
  assert.match(miningAudio, /AudioContext/);
  assert.match(miningAudio, /oscillator\.type = "square"/);
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

test("resonance is a rare explicit reward event, not automatic income", () => {
  assert.match(resonance, /RESONANCE_MIN_DELAY_MS = 120_000/);
  assert.match(resonance, /RESONANCE_MAX_DELAY_MS = 300_000/);
  assert.match(resonance, /RESONANCE_ACTIVE_MS = 12_000/);
  assert.match(resonance, /RESONANCE_BOOST_MS = 18_000/);
  assert.match(resonance, /visibilitychange/);
  assert.match(resonance, /phase !== "waiting" \|\| !pageVisible/);
  assert.match(resonance, /setPhase\("missed"\)/);
  assert.match(resonance, /const claim = useCallback/);
  assert.match(prototype, /resonance\.boostActive \? RESONANCE_MULTIPLIER : 1/);
  assert.match(resonanceView, /공명 결절 회수/);
  assert.match(resonanceView, /data-no-mine/);
  assert.match(resonanceView, /aria-live="assertive"/);
  assert.match(styles, /\.resonanceNode:focus-visible/);
  assert.match(styles, /\.resonanceMissed/);
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

test("equipment upgrades accumulate visible production infrastructure", () => {
  // The derivations moved into coreBalance so the app and the web build the same rig
  // from the same levels (D-065); the prototype must not grow private copies again.
  assert.doesNotMatch(prototype, /function (cartFleetSize|cartCargoSlots|serviceLampCount|supportCrewSize)/);
  assert.match(prototype, /cartFleetSize\(/);
  assert.match(prototype, /cartCargoSlots\(/);
  assert.match(prototype, /serviceLampCount\(/);
  assert.match(prototype, /supportCrewSize\(/);
  assert.match(prototype, /data-cart-count=\{cartCount\}/);
  assert.match(prototype, /data-cart-load=\{cartLoad\}/);
  assert.match(prototype, /data-crew-count=\{crewCount\}/);
  assert.match(prototype, /data-service-light-count=\{serviceLights\}/);
  assert.match(prototype, /data-infrastructure-tier=\{crewCount\}/);
  assert.match(prototype, /설비 증설 완료/);
  assert.match(prototype, /specializationInstallationDetail/);
  assert.match(prototype, /presentInstallation/);
  assert.match(prototype, /styles\.cartRun/);
  assert.match(prototype, /styles\.serviceCrew/);
  assert.match(prototype, /styles\.serviceLights/);
  assert.match(prototype, /styles\.crewStation/);
  assert.match(prototype, /styles\.crewDeck/);
  assert.match(prototype, /styles\.operationsReadout/);
  assert.match(prototype, /styles\.constructionPulse/);
  assert.match(styles, /\.installationToast/);
  assert.match(styles, /\.newestCart/);
  assert.match(styles, /\.newestCrew/);
  assert.match(styles, /\.newestLamp/);
  assert.match(styles, /\.expandedRail/);
  assert.match(styles, /\.operationsReadout/);
  assert.match(styles, /\.constructionPulse/);
  assert.match(styles, /transform: translateY\(var\(--cart-rest\)\)/);
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
    "public/assets/shaft/MinerDescentStrip.png",
    "public/assets/shaft/ShaftFrontierLip.png",
    "public/assets/events/ResonanceNode.png",
    "public/og/deepmine-shaft-social.png",
  ];

  for (const asset of assets) {
    const path = join(projectRoot, asset);
    assert.equal(existsSync(path), true, `${asset} should exist`);
    assert.ok(statSync(path).size > 0, `${asset} should not be empty`);
  }
});
