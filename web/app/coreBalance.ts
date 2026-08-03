export const METERS_PER_SEGMENT = 4;

const BASE_SEGMENT_INTEGRITY = 10;
const SEGMENT_INTEGRITY_GROWTH_RATE = 1.058;
const BASE_SEGMENT_ORE = 4;
const SEGMENT_ORE_GROWTH_RATE = 1.07;
const SEAM_SEGMENT_INTERVAL = 25;
const SEAM_INTEGRITY_MULTIPLIER = 6;
const SEAM_ORE_MULTIPLIER = 15;

export const CRYSTAL_REGION_DEPTH = 240;
export const RUINS_REGION_DEPTH = 800;
export const ABYSS_REGION_DEPTH = 1_600;
const ENTRY_REGION_ORE_MULTIPLIER = 1;
const CRYSTAL_REGION_ORE_MULTIPLIER = 1.35;
const RUINS_REGION_ORE_MULTIPLIER = 1.8;
const ABYSS_REGION_ORE_MULTIPLIER = 2.4;

const BASE_TAP_DAMAGE = 1;
const DRILL_REWARD_GROWTH_RATE = 1.12;
const BASE_CRITICAL_CHANCE = 0.05;
const BASE_CRITICAL_MULTIPLIER = 2.5;
const LAMP_CRITICAL_CHANCE_INCREASE_PER_LEVEL = 0.01;
const LAMP_CRITICAL_MULTIPLIER_INCREASE_PER_LEVEL = 0.03;
const MAXIMUM_CRITICAL_CHANCE = 0.6;

export const IMPACT_METER_MAXIMUM = 100;
export const IMPACT_PER_TAP = 7;
export const IMPACT_DECAY_PER_SECOND = 9;
const IMPACT_FULL_DAMAGE_MULTIPLIER = 2;

const AUTOMATION_DAMAGE_PER_LEVEL = 0.5;
const AUTOMATION_GROWTH_RATE = 1.12;

export const MINIMUM_EQUIPMENT_LEVEL = 1;
export const EQUIPMENT_LEVEL_ARITHMETIC_BOUND = 100_000;
export const EQUIPMENT_PRICE_GROWTH_RATE = 1.34;
const DRILL_BASE_PRICE = 100;
const CART_BASE_PRICE = 180;
const LAMP_BASE_PRICE = 200;
export const EQUIPMENT_LEVEL_UNLOCK_BASE = 5;
export const EQUIPMENT_LEVEL_UNLOCK_DEPTH_STEP = 15;
export const REMEMBERED_REBUY_DISCOUNT = 0.5;

export const EQUIPMENT_MODIFICATION_UNLOCK_LEVEL = 5;
export const DRILL_MODIFICATION_COST = 460;
export const CART_MODIFICATION_COST = 560;
export const LAMP_MODIFICATION_COST = 660;
const IMPACT_MODIFICATION_DAMAGE_MULTIPLIER = 1.35;
const FLEET_MODIFICATION_AUTOMATION_MULTIPLIER = 1.25;
const FREIGHT_MODIFICATION_ORE_MULTIPLIER = 1.25;
const FORTUNE_MODIFICATION_CRITICAL_CHANCE = 0.08;

export const REFINEMENT_LEVEL_INTERVAL = 6;
export const REFINEMENT_DAMAGE_MULTIPLIER = 2.5;
export const REFINEMENT_COST_MULTIPLIER = 20;

export const MAXIMUM_SUPPORT_CREW = 4;
export const SUPPORT_CREW_LEVEL_OFFSET = 10;
export const MAXIMUM_CARTS = 4;
export const MAXIMUM_CARGO_SLOTS = 3;
export const MAXIMUM_SERVICE_LAMPS = 5;
export const RIG_UPGRADE_CELLS_PER_GENERATION = 4;
export const MAXIMUM_VISIBLE_REFINEMENT_BANDS = 3;
const CART_GROWTH_LEVEL_STEP = 2;

export type EquipmentKind = "drill" | "cart" | "lamp";
export type MineRegion = "entry" | "crystal" | "ruins" | "abyss";
export type EquipmentLevels = Record<EquipmentKind, number>;
export type RigToolVisualState = {
  level: number;
  artTier: number;
  upgradeCells: number;
  generation: number;
  housingVariant: number;
  refinementTier: number;
  refinementBands: number;
};

function safeLevel(level: number) {
  return Math.max(MINIMUM_EQUIPMENT_LEVEL, Math.floor(level));
}

function levelsAboveBase(level: number) {
  return Math.max(0, safeLevel(level) - MINIMUM_EQUIPMENT_LEVEL);
}

export function segmentIndexForDepth(depth: number) {
  return Math.max(0, Math.floor(depth / METERS_PER_SEGMENT));
}

export function regionForDepth(depth: number): MineRegion {
  if (depth >= ABYSS_REGION_DEPTH) return "abyss";
  if (depth >= RUINS_REGION_DEPTH) return "ruins";
  if (depth >= CRYSTAL_REGION_DEPTH) return "crystal";
  return "entry";
}

function regionOreMultiplier(region: MineRegion) {
  switch (region) {
    case "abyss": return ABYSS_REGION_ORE_MULTIPLIER;
    case "ruins": return RUINS_REGION_ORE_MULTIPLIER;
    case "crystal": return CRYSTAL_REGION_ORE_MULTIPLIER;
    default: return ENTRY_REGION_ORE_MULTIPLIER;
  }
}

export function isSeamSegment(index: number) {
  return index > 0 && index % SEAM_SEGMENT_INTERVAL === 0;
}

export function segmentIntegrity(index: number) {
  const safeIndex = Math.max(0, Math.floor(index));
  return BASE_SEGMENT_INTEGRITY
    * Math.pow(SEGMENT_INTEGRITY_GROWTH_RATE, safeIndex)
    * (isSeamSegment(safeIndex) ? SEAM_INTEGRITY_MULTIPLIER : 1);
}

export function segmentOre(index: number) {
  const safeIndex = Math.max(0, Math.floor(index));
  const region = regionForDepth(safeIndex * METERS_PER_SEGMENT);
  return BASE_SEGMENT_ORE
    * Math.pow(SEGMENT_ORE_GROWTH_RATE, safeIndex)
    * (isSeamSegment(safeIndex) ? SEAM_ORE_MULTIPLIER : 1)
    * regionOreMultiplier(region);
}

export function refinementTiersUnlocked(level: number) {
  return Math.floor(levelsAboveBase(level) / REFINEMENT_LEVEL_INTERVAL);
}

export function refinementMultiplier(tier: number) {
  return Math.pow(REFINEMENT_DAMAGE_MULTIPLIER, Math.max(0, Math.floor(tier)));
}

export function tapDamage(drillLevel: number, impactModification = false, refinementTier = 0) {
  return BASE_TAP_DAMAGE
    * Math.pow(DRILL_REWARD_GROWTH_RATE, levelsAboveBase(drillLevel))
    * refinementMultiplier(refinementTier)
    * (impactModification ? IMPACT_MODIFICATION_DAMAGE_MULTIPLIER : 1);
}

export function automationDamagePerSecond(
  cartLevel: number,
  fleetModification = false,
  refinementTier = 0,
) {
  const steps = levelsAboveBase(cartLevel);
  if (steps <= 0) return 0;
  return AUTOMATION_DAMAGE_PER_LEVEL
    * steps
    * Math.pow(AUTOMATION_GROWTH_RATE, steps)
    * refinementMultiplier(refinementTier)
    * (fleetModification ? FLEET_MODIFICATION_AUTOMATION_MULTIPLIER : 1);
}

export function criticalChance(lampLevel: number, fortuneModification = false) {
  return Math.min(
    MAXIMUM_CRITICAL_CHANCE,
    BASE_CRITICAL_CHANCE
      + levelsAboveBase(lampLevel) * LAMP_CRITICAL_CHANCE_INCREASE_PER_LEVEL
      + (fortuneModification ? FORTUNE_MODIFICATION_CRITICAL_CHANCE : 0),
  );
}

export function criticalMultiplier(lampLevel: number, refinementTier = 0) {
  const refinementMultiplier = Math.pow(
    REFINEMENT_DAMAGE_MULTIPLIER,
    Math.max(0, refinementTier) * 0.5,
  );
  return BASE_CRITICAL_MULTIPLIER * refinementMultiplier
    + levelsAboveBase(lampLevel) * LAMP_CRITICAL_MULTIPLIER_INCREASE_PER_LEVEL;
}

export function expectedTapDamage(levels: EquipmentLevels, lampRefinement = 0) {
  const tap = tapDamage(levels.drill);
  const chance = criticalChance(levels.lamp);
  return tap * (1 + chance * (criticalMultiplier(levels.lamp, lampRefinement) - 1));
}

export function freightOreMultiplier(freightModification: boolean) {
  return freightModification ? FREIGHT_MODIFICATION_ORE_MULTIPLIER : 1;
}

export function impactDamageMultiplier(impactValue: number) {
  const fraction = Math.min(1, Math.max(0, impactValue / IMPACT_METER_MAXIMUM));
  return 1 + fraction * (IMPACT_FULL_DAMAGE_MULTIPLIER - 1);
}

export function requiredDepthForLevel(level: number) {
  return Math.max(0, level - EQUIPMENT_LEVEL_UNLOCK_BASE)
    * EQUIPMENT_LEVEL_UNLOCK_DEPTH_STEP;
}

export function unlockedMaximumLevel(depthMeters: number) {
  return EQUIPMENT_LEVEL_UNLOCK_BASE
    + Math.floor(Math.max(0, depthMeters) / EQUIPMENT_LEVEL_UNLOCK_DEPTH_STEP);
}

function equipmentBasePrice(kind: EquipmentKind) {
  switch (kind) {
    case "drill": return DRILL_BASE_PRICE;
    case "cart": return CART_BASE_PRICE;
    case "lamp": return LAMP_BASE_PRICE;
  }
}

export function upgradeCost(
  kind: EquipmentKind,
  currentLevel: number,
  rememberedLevel = MINIMUM_EQUIPMENT_LEVEL,
) {
  if (currentLevel < MINIMUM_EQUIPMENT_LEVEL
      || currentLevel >= EQUIPMENT_LEVEL_ARITHMETIC_BOUND) return null;
  const unrounded = equipmentBasePrice(kind)
    * Math.pow(EQUIPMENT_PRICE_GROWTH_RATE, currentLevel - MINIMUM_EQUIPMENT_LEVEL);
  const discounted = currentLevel < rememberedLevel
    ? unrounded * REMEMBERED_REBUY_DISCOUNT
    : unrounded;
  return Number.isFinite(discounted) ? Math.ceil(discounted) : Number.POSITIVE_INFINITY;
}

export function refinementCost(kind: EquipmentKind, tier: number) {
  const unlockLevel = MINIMUM_EQUIPMENT_LEVEL
    + Math.max(1, tier) * REFINEMENT_LEVEL_INTERVAL;
  const levelCost = upgradeCost(kind, unlockLevel);
  return levelCost == null
    ? Number.POSITIVE_INFINITY
    : Math.ceil(levelCost * REFINEMENT_COST_MULTIPLIER);
}

export function recommendMiningUpgrade(
  levels: EquipmentLevels,
  ore: number,
  depthMeters: number,
): EquipmentKind | null {
  const unlocked = unlockedMaximumLevel(depthMeters);
  const currentDps = automationDamagePerSecond(levels.cart);
  const cartCost = upgradeCost("cart", levels.cart);
  if (currentDps === 0
      && levels.cart < unlocked
      && cartCost != null
      && automationDamagePerSecond(levels.cart + 1) > 0) return "cart";

  const currentTap = expectedTapDamage(levels);
  const candidates = (["drill", "cart", "lamp"] as EquipmentKind[]).flatMap((kind) => {
    const cost = upgradeCost(kind, levels[kind]);
    if (cost == null || cost > ore || levels[kind] >= unlocked) return [];
    const projected = { ...levels, [kind]: levels[kind] + 1 };
    const tapGain = Math.max(0, expectedTapDamage(projected) / currentTap - 1);
    const projectedDps = automationDamagePerSecond(projected.cart);
    const dpsGain = currentDps === 0
      ? (projectedDps > 0 ? 10 : 0)
      : Math.max(0, projectedDps / currentDps - 1);
    return [{ kind, score: (tapGain + dpsGain * 1.5) / cost }];
  });
  candidates.sort((a, b) => b.score - a.score);
  return candidates[0]?.kind ?? null;
}

export function equipmentTier(level: number) {
  const clamped = safeLevel(level);
  if (clamped <= 1) return 1;
  if (clamped <= 4) return 2;
  return 3;
}

/**
 * Canonical physical state for one rig subsystem. Major levels swap generated art;
 * every in-between level fills a service cell or advances the stamped housing
 * generation. The exact level and refinement tier remain visible after the small
 * decorative bands reach their readability cap.
 */
export function rigToolVisualState(
  level: number,
  refinementTier = 0,
): RigToolVisualState {
  const clamped = safeLevel(level);
  const investment = clamped - MINIMUM_EQUIPMENT_LEVEL;
  const exactRefinement = Math.max(0, Math.floor(refinementTier));
  return {
    level: clamped,
    artTier: equipmentTier(clamped),
    upgradeCells: investment % RIG_UPGRADE_CELLS_PER_GENERATION,
    generation: Math.floor(investment / RIG_UPGRADE_CELLS_PER_GENERATION),
    housingVariant: Math.floor(investment / RIG_UPGRADE_CELLS_PER_GENERATION) % 4 + 1,
    refinementTier: exactRefinement,
    refinementBands: Math.min(MAXIMUM_VISIBLE_REFINEMENT_BANDS, exactRefinement),
  };
}

export function supportCrewSize(drill: number, cart: number, lamp: number) {
  const total = safeLevel(drill) + safeLevel(cart) + safeLevel(lamp);
  return Math.min(MAXIMUM_SUPPORT_CREW, Math.max(1, total - SUPPORT_CREW_LEVEL_OFFSET));
}

export function cartFleetSize(level: number, fleetModification: boolean) {
  const clamped = safeLevel(level);
  if (clamped <= MINIMUM_EQUIPMENT_LEVEL) return 0;
  const earned = 1 + Math.floor((clamped - MINIMUM_EQUIPMENT_LEVEL - 1) / CART_GROWTH_LEVEL_STEP);
  return Math.min(MAXIMUM_CARTS, earned + (fleetModification ? 1 : 0));
}

export function cartCargoSlots(level: number, freightModification: boolean) {
  const clamped = safeLevel(level);
  if (clamped <= MINIMUM_EQUIPMENT_LEVEL) return 0;
  const earned = 1 + Math.floor((clamped - MINIMUM_EQUIPMENT_LEVEL - 1) / CART_GROWTH_LEVEL_STEP);
  return Math.min(MAXIMUM_CARGO_SLOTS, earned + (freightModification ? 1 : 0));
}

export function serviceLampCount(level: number, reachModification: boolean) {
  return Math.min(MAXIMUM_SERVICE_LAMPS, safeLevel(level) + (reachModification ? 1 : 0));
}
