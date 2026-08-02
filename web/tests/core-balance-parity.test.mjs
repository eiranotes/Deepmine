import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";

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
  const match = swift.match(new RegExp(`static let ${name}\\b[^=]*=\\s*([0-9_.]+)`));
  assert.ok(match, `Balance.${name} should exist in Swift`);
  return Number(match[1].replaceAll("_", ""));
}

function webConstant(name) {
  const match = web.match(new RegExp(`${name}\\s*=\\s*([0-9_.]+)`));
  assert.ok(match, `${name} should exist in coreBalance.ts`);
  return Number(match[1].replaceAll("_", ""));
}

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
  equipmentLevelArithmeticBound: "EQUIPMENT_LEVEL_ARITHMETIC_BOUND",
  equipmentPriceGrowthRate: "EQUIPMENT_PRICE_GROWTH_RATE",
  drillBasePrice: "DRILL_BASE_PRICE",
  cartBasePrice: "CART_BASE_PRICE",
  lampBasePrice: "LAMP_BASE_PRICE",
  equipmentLevelUnlockBase: "EQUIPMENT_LEVEL_UNLOCK_BASE",
  equipmentLevelUnlockDepthStep: "EQUIPMENT_LEVEL_UNLOCK_DEPTH_STEP",
  rememberedRebuyDiscount: "REMEMBERED_REBUY_DISCOUNT",
  maximumSupportCrew: "MAXIMUM_SUPPORT_CREW",
  supportCrewLevelOffset: "SUPPORT_CREW_LEVEL_OFFSET",
  maximumCarts: "MAXIMUM_CARTS",
  maximumCargoSlots: "MAXIMUM_CARGO_SLOTS",
  maximumServiceLamps: "MAXIMUM_SERVICE_LAMPS",
  cartGrowthLevelStep: "CART_GROWTH_LEVEL_STEP",
  equipmentModificationUnlockLevel: "EQUIPMENT_MODIFICATION_UNLOCK_LEVEL",
  drillModificationCost: "DRILL_MODIFICATION_COST",
  cartModificationCost: "CART_MODIFICATION_COST",
  lampModificationCost: "LAMP_MODIFICATION_COST",
  impactModificationDamageMultiplier: "IMPACT_MODIFICATION_DAMAGE_MULTIPLIER",
  fleetModificationAutomationMultiplier: "FLEET_MODIFICATION_AUTOMATION_MULTIPLIER",
  freightModificationOreMultiplier: "FREIGHT_MODIFICATION_ORE_MULTIPLIER",
  fortuneModificationCriticalChance: "FORTUNE_MODIFICATION_CRITICAL_CHANCE",
  refinementLevelInterval: "REFINEMENT_LEVEL_INTERVAL",
  refinementDamageMultiplier: "REFINEMENT_DAMAGE_MULTIPLIER",
  refinementCostMultiplier: "REFINEMENT_COST_MULTIPLIER",
};

test("every mirrored constant equals the current Swift Balance value", () => {
  for (const [swiftName, webName] of Object.entries(mirroredConstants)) {
    assert.equal(webConstant(webName), swiftConstant(swiftName), `${webName} must equal Balance.${swiftName}`);
  }
});

test("equipment sprite tiers use the same boundaries as EquipmentEngine.visualTier", () => {
  const boundaries = [...equipmentEngine.matchAll(/case \.\.\.(\d+):/g)].map((match) => Number(match[1]));
  assert.deepEqual(boundaries.slice(0, 2), [4, 14]);
  const webBoundaries = [...web.matchAll(/clamped <= (\d+)\) return \d/g)].map((match) => Number(match[1]));
  assert.deepEqual(webBoundaries, boundaries.slice(0, 2));
});

test("infrastructure counts are derived in one place for both surfaces", () => {
  const engine = readFileSync(join(coreSources, "MineInfrastructure.swift"), "utf8");
  assert.match(engine, /guard level > Balance\.minimumEquipmentLevel else \{ return 0 \}/);
  assert.match(web, /if \(clamped <= MINIMUM_EQUIPMENT_LEVEL\) return 0;/);
  assert.match(engine, /total - Balance\.supportCrewLevelOffset/);
  assert.match(web, /total - SUPPORT_CREW_LEVEL_OFFSET/);
});

test("the prototype reads the economy from coreBalance rather than its own numbers", () => {
  const prototype = readFileSync(join(projectRoot, "app/UnifiedMinePrototype.tsx"), "utf8");
  assert.match(prototype, /from "\.\/coreBalance"/);
  assert.match(prototype, /segmentIntegrity\(/);
  assert.match(prototype, /segmentOre\(/);
  assert.match(prototype, /tapDamage\(equipment\.drill/);
  assert.match(prototype, /automationDamagePerSecond\(equipment\.cart/);
  assert.match(prototype, /recommendMiningUpgrade\(/);
  assert.doesNotMatch(prototype, /1\.018|1\.16|1\.22|1\.31/);
  assert.doesNotMatch(prototype, /190|270|340/);
});

test("the first cart remains the savings target before it is affordable", () => {
  assert.match(
    web,
    /currentDps === 0[\s\S]*cartCost != null[\s\S]*return "cart";/,
  );
  assert.doesNotMatch(web, /cartCost <= ore/);
});

test("lamp refinement multiplies the base critical value before additive levels", () => {
  assert.match(
    web,
    /BASE_CRITICAL_MULTIPLIER \* refinementMultiplier\s*\+\s*levelsAboveBase\(lampLevel\)/,
  );
});

test("the prototype consumes every long-depth geology asset at its exact threshold", () => {
  const prototype = readFileSync(join(projectRoot, "app/UnifiedMinePrototype.tsx"), "utf8");
  assert.match(prototype, /depth >= 5_000.*ShaftRock_pressure-v2\.png/);
  assert.match(prototype, /depth >= 20_000.*ShaftRock_fault-v2\.png/);
  assert.match(prototype, /depth >= 100_000.*ShaftRock_core-v2\.png/);
});
