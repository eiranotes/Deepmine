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
const miningAudio = readFileSync(join(projectRoot, "app/useMiningAudio.ts"), "utf8");

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
  assert.match(prototype, /function cartFleetSize/);
  assert.match(prototype, /function cartCargoSlots/);
  assert.match(prototype, /function serviceLampCount/);
  assert.match(prototype, /function supportCrewSize/);
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
