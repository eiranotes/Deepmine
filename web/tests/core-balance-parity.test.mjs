import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

/**
 * The other contract test greps the prototype for strings, which proves a name is present
 * and nothing about behaviour. This one reads the actual Swift constants and fails when
 * `coreBalance.ts` drifts from them, so "the web follows Core" is enforced rather than
 * asserted in a document.
 */

const projectRoot = new URL("../", import.meta.url).pathname;
const repoRoot = join(projectRoot, "..");
const coreSources = join(repoRoot, "DeepMineCore/Sources/DeepMineCore");

const swift = [
  readFileSync(join(coreSources, "Balance.swift"), "utf8"),
  readFileSync(join(coreSources, "Balance+Clicker.swift"), "utf8"),
].join("\n");
const equipmentEngine = readFileSync(join(coreSources, "EquipmentEngine.swift"), "utf8");
const web = readFileSync(join(projectRoot, "app/coreBalance.ts"), "utf8");

function swiftConstant(name) {
  const match = swift.match(
    new RegExp(`static let ${name}\\b[^=]*=\\s*([0-9_.]+)`),
  );
  assert.ok(match, `Balance.${name} should exist in Swift`);
  return Number(match[1].replaceAll("_", ""));
}

function webConstant(name) {
  const match = web.match(new RegExp(`${name}\\s*=\\s*([0-9_.]+)`));
  assert.ok(match, `${name} should exist in coreBalance.ts`);
  return Number(match[1].replaceAll("_", ""));
}

/** Swift name → TypeScript name. Every economy number the prototype uses is listed. */
const mirroredConstants = {
  metersPerSegment: "METERS_PER_SEGMENT",

  baseSegmentIntegrity: "BASE_SEGMENT_INTEGRITY",
  segmentIntegrityGrowthRate: "SEGMENT_INTEGRITY_GROWTH_RATE",
  baseSegmentOre: "BASE_SEGMENT_ORE",
  segmentOreGrowthRate: "SEGMENT_ORE_GROWTH_RATE",
  seamSegmentInterval: "SEAM_SEGMENT_INTERVAL",
  seamIntegrityMultiplier: "SEAM_INTEGRITY_MULTIPLIER",
  seamOreMultiplier: "SEAM_ORE_MULTIPLIER",

  crystalRegionDepth: "CRYSTAL_REGION_DEPTH",
  ruinsRegionDepth: "RUINS_REGION_DEPTH",
  abyssRegionDepth: "ABYSS_REGION_DEPTH",
  entryRegionOreMultiplier: "ENTRY_REGION_ORE_MULTIPLIER",
  crystalRegionOreMultiplier: "CRYSTAL_REGION_ORE_MULTIPLIER",
  ruinsRegionOreMultiplier: "RUINS_REGION_ORE_MULTIPLIER",
  abyssRegionOreMultiplier: "ABYSS_REGION_ORE_MULTIPLIER",

  baseTapDamage: "BASE_TAP_DAMAGE",
  drillRewardGrowthRate: "DRILL_REWARD_GROWTH_RATE",
  baseCriticalChance: "BASE_CRITICAL_CHANCE",
  baseCriticalMultiplier: "BASE_CRITICAL_MULTIPLIER",
  lampCriticalChanceIncreasePerLevel: "LAMP_CRITICAL_CHANCE_INCREASE_PER_LEVEL",
  lampCriticalMultiplierIncreasePerLevel: "LAMP_CRITICAL_MULTIPLIER_INCREASE_PER_LEVEL",
  maximumCriticalChance: "MAXIMUM_CRITICAL_CHANCE",

  impactMeterMaximum: "IMPACT_METER_MAXIMUM",
  impactPerTap: "IMPACT_PER_TAP",
  impactDecayPerSecond: "IMPACT_DECAY_PER_SECOND",
  impactFullDamageMultiplier: "IMPACT_FULL_DAMAGE_MULTIPLIER",

  automationDamagePerLevel: "AUTOMATION_DAMAGE_PER_LEVEL",
  automationGrowthRate: "AUTOMATION_GROWTH_RATE",

  minimumEquipmentLevel: "MINIMUM_EQUIPMENT_LEVEL",
  maximumEquipmentLevel: "MAXIMUM_EQUIPMENT_LEVEL",
  equipmentPriceGrowthRate: "EQUIPMENT_PRICE_GROWTH_RATE",
  drillBasePrice: "DRILL_BASE_PRICE",
  cartBasePrice: "CART_BASE_PRICE",
  lampBasePrice: "LAMP_BASE_PRICE",

  equipmentModificationUnlockLevel: "EQUIPMENT_MODIFICATION_UNLOCK_LEVEL",
  drillModificationCost: "DRILL_MODIFICATION_COST",
  cartModificationCost: "CART_MODIFICATION_COST",
  lampModificationCost: "LAMP_MODIFICATION_COST",
  impactModificationDamageMultiplier: "IMPACT_MODIFICATION_DAMAGE_MULTIPLIER",
  fleetModificationAutomationMultiplier: "FLEET_MODIFICATION_AUTOMATION_MULTIPLIER",
  freightModificationOreMultiplier: "FREIGHT_MODIFICATION_ORE_MULTIPLIER",
  fortuneModificationCriticalChance: "FORTUNE_MODIFICATION_CRITICAL_CHANCE",
};

test("every mirrored constant equals the Swift Balance value", () => {
  for (const [swiftName, webName] of Object.entries(mirroredConstants)) {
    assert.equal(
      webConstant(webName),
      swiftConstant(swiftName),
      `${webName} must equal Balance.${swiftName}`,
    );
  }
});

test("equipment sprite tiers use the same boundaries as EquipmentEngine.visualTier", () => {
  const boundaries = [...equipmentEngine.matchAll(/case \.\.\.(\d+):/g)].map((match) =>
    Number(match[1]),
  );
  assert.deepEqual(boundaries.slice(0, 2), [4, 14]);

  const webBoundaries = [...web.matchAll(/clamped <= (\d+)\) return \d/g)].map((match) =>
    Number(match[1]),
  );
  assert.deepEqual(webBoundaries, boundaries.slice(0, 2));
});

test("the prototype reads the economy from coreBalance rather than its own numbers", () => {
  const prototype = readFileSync(join(projectRoot, "app/MinePrototype.tsx"), "utf8");
  assert.match(prototype, /from "\.\/coreBalance"/);
  assert.match(prototype, /segmentIntegrity\(segmentIndexForDepth\(depth\)\)/);
  assert.match(prototype, /segmentOre\(segmentIndexForDepth\(depth\)\)/);
  assert.match(prototype, /tapDamage\(equipment\.drill/);
  assert.match(prototype, /automationDamagePerSecond\(/);
  // The demo-tuned curve must not come back: these are the constants it was built from.
  assert.doesNotMatch(prototype, /1\.018|1\.16|1\.22|1\.31/);
  assert.doesNotMatch(prototype, /190|270|340/);
});
