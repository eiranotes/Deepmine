/**
 * Mirror of `DeepMineCore/Sources/DeepMineCore/Balance.swift` and
 * `Balance+Clicker.swift`.
 *
 * The prototype used to carry its own tuned-for-demo numbers — a 104 base integrity, a
 * 1.31 price exponent, tier boundaries at 5/9. That made the web the fastest way to see a
 * game the app does not play: an ETA, a reward, or a purchase rhythm confirmed here did
 * not transfer. Core owns the economy because its curve is the one the 180-day simulation
 * and the depth-inversion gates are tuned against (D-044), so every number below is copied
 * from Swift rather than chosen here.
 *
 * When a Balance constant changes in Swift, change it here in the same commit.
 */

// MARK: Segment geometry

export const METERS_PER_SEGMENT = 4;

// MARK: Integrity and yield

const BASE_SEGMENT_INTEGRITY = 10;
const SEGMENT_INTEGRITY_GROWTH_RATE = 1.058;
const BASE_SEGMENT_ORE = 4;
const SEGMENT_ORE_GROWTH_RATE = 1.07;
const SEAM_SEGMENT_INTERVAL = 25;
const SEAM_INTEGRITY_MULTIPLIER = 6;
const SEAM_ORE_MULTIPLIER = 15;

// MARK: Regions

const CRYSTAL_REGION_DEPTH = 240;
const RUINS_REGION_DEPTH = 800;
const ABYSS_REGION_DEPTH = 1_600;

const ENTRY_REGION_ORE_MULTIPLIER = 1.0;
const CRYSTAL_REGION_ORE_MULTIPLIER = 1.35;
const RUINS_REGION_ORE_MULTIPLIER = 1.8;
const ABYSS_REGION_ORE_MULTIPLIER = 2.4;

export type MineRegion = "entry" | "crystal" | "ruins" | "abyss";

// MARK: Striking

const BASE_TAP_DAMAGE = 1.0;
const DRILL_REWARD_GROWTH_RATE = 1.12;
const BASE_CRITICAL_CHANCE = 0.05;
const BASE_CRITICAL_MULTIPLIER = 2.5;
const LAMP_CRITICAL_CHANCE_INCREASE_PER_LEVEL = 0.01;
const LAMP_CRITICAL_MULTIPLIER_INCREASE_PER_LEVEL = 0.03;
const MAXIMUM_CRITICAL_CHANCE = 0.6;

// MARK: Impact meter

export const IMPACT_METER_MAXIMUM = 100;
export const IMPACT_PER_TAP = 7;
export const IMPACT_DECAY_PER_SECOND = 9;
const IMPACT_FULL_DAMAGE_MULTIPLIER = 2.0;

// MARK: Automation

const AUTOMATION_DAMAGE_PER_LEVEL = 0.5;
const AUTOMATION_GROWTH_RATE = 1.12;

// MARK: Equipment

export const MINIMUM_EQUIPMENT_LEVEL = 1;
export const MAXIMUM_EQUIPMENT_LEVEL = 200;
const EQUIPMENT_PRICE_GROWTH_RATE = 1.34;
const DRILL_BASE_PRICE = 100;
const CART_BASE_PRICE = 180;
const LAMP_BASE_PRICE = 200;

// MARK: Equipment modifications

export const EQUIPMENT_MODIFICATION_UNLOCK_LEVEL = 5;
export const DRILL_MODIFICATION_COST = 460;
export const CART_MODIFICATION_COST = 560;
export const LAMP_MODIFICATION_COST = 660;
const IMPACT_MODIFICATION_DAMAGE_MULTIPLIER = 1.35;
const FLEET_MODIFICATION_AUTOMATION_MULTIPLIER = 1.25;
const FREIGHT_MODIFICATION_ORE_MULTIPLIER = 1.25;
const FORTUNE_MODIFICATION_CRITICAL_CHANCE = 0.08;

export type EquipmentKind = "drill" | "cart" | "lamp";

/// `Balance.levelsAboveBase`
function levelsAboveBase(level: number) {
  return Math.max(
    0,
    Math.min(MAXIMUM_EQUIPMENT_LEVEL, level) - MINIMUM_EQUIPMENT_LEVEL,
  );
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
    case "abyss":
      return ABYSS_REGION_ORE_MULTIPLIER;
    case "ruins":
      return RUINS_REGION_ORE_MULTIPLIER;
    case "crystal":
      return CRYSTAL_REGION_ORE_MULTIPLIER;
    default:
      return ENTRY_REGION_ORE_MULTIPLIER;
  }
}

/// `RockGenerator.segment(at:).isSeam`
export function isSeamSegment(index: number) {
  return index > 0 && index % SEAM_SEGMENT_INTERVAL === 0;
}

/// `RockGenerator.segment(at:).maximumIntegrity`
export function segmentIntegrity(index: number) {
  const safeIndex = Math.max(0, index);
  return (
    BASE_SEGMENT_INTEGRITY
    * Math.pow(SEGMENT_INTEGRITY_GROWTH_RATE, safeIndex)
    * (isSeamSegment(safeIndex) ? SEAM_INTEGRITY_MULTIPLIER : 1)
  );
}

/// `RockGenerator.segment(at:).oreYield`
export function segmentOre(index: number) {
  const safeIndex = Math.max(0, index);
  const region = regionForDepth(safeIndex * METERS_PER_SEGMENT);
  return (
    BASE_SEGMENT_ORE
    * Math.pow(SEGMENT_ORE_GROWTH_RATE, safeIndex)
    * (isSeamSegment(safeIndex) ? SEAM_ORE_MULTIPLIER : 1)
    * regionOreMultiplier(region)
  );
}

/// `StrikeEngine.power(...).tapDamage`
export function tapDamage(drillLevel: number, impactModification = false) {
  return (
    BASE_TAP_DAMAGE
    * Math.pow(DRILL_REWARD_GROWTH_RATE, levelsAboveBase(drillLevel))
    * (impactModification ? IMPACT_MODIFICATION_DAMAGE_MULTIPLIER : 1)
  );
}

/// `StrikeEngine.power(...).damagePerSecond`. A cart at base level hauls nothing: the
/// first cart upgrade is the moment the mine starts running without the player.
export function automationDamagePerSecond(cartLevel: number, fleetModification = false) {
  const steps = levelsAboveBase(cartLevel);
  if (steps <= 0) return 0;
  return (
    AUTOMATION_DAMAGE_PER_LEVEL
    * steps
    * Math.pow(AUTOMATION_GROWTH_RATE, steps)
    * (fleetModification ? FLEET_MODIFICATION_AUTOMATION_MULTIPLIER : 1)
  );
}

export function criticalChance(lampLevel: number, fortuneModification = false) {
  return Math.min(
    MAXIMUM_CRITICAL_CHANCE,
    BASE_CRITICAL_CHANCE
      + levelsAboveBase(lampLevel) * LAMP_CRITICAL_CHANCE_INCREASE_PER_LEVEL
      + (fortuneModification ? FORTUNE_MODIFICATION_CRITICAL_CHANCE : 0),
  );
}

export function criticalMultiplier(lampLevel: number) {
  return (
    BASE_CRITICAL_MULTIPLIER
    + levelsAboveBase(lampLevel) * LAMP_CRITICAL_MULTIPLIER_INCREASE_PER_LEVEL
  );
}

export function freightOreMultiplier(freightModification: boolean) {
  return freightModification ? FREIGHT_MODIFICATION_ORE_MULTIPLIER : 1;
}

/// `ImpactMeter.damageMultiplier`
export function impactDamageMultiplier(impactValue: number) {
  const fraction = Math.min(1, Math.max(0, impactValue / IMPACT_METER_MAXIMUM));
  return 1 + fraction * (IMPACT_FULL_DAMAGE_MULTIPLIER - 1);
}

/// `EquipmentEngine.upgradeCost`. Returns null at the ceiling, like the Swift optional.
export function upgradeCost(kind: EquipmentKind, currentLevel: number) {
  if (currentLevel < MINIMUM_EQUIPMENT_LEVEL) return null;
  if (currentLevel >= MAXIMUM_EQUIPMENT_LEVEL) return null;
  const base =
    kind === "drill"
      ? DRILL_BASE_PRICE
      : kind === "cart"
        ? CART_BASE_PRICE
        : LAMP_BASE_PRICE;
  return Math.ceil(
    base * Math.pow(EQUIPMENT_PRICE_GROWTH_RATE, currentLevel - MINIMUM_EQUIPMENT_LEVEL),
  );
}

/// `EquipmentEngine.visualTier`. Three shipped sprite families, boundaries at 4 and 14.
export function equipmentTier(level: number) {
  const clamped = Math.max(MINIMUM_EQUIPMENT_LEVEL, level);
  if (clamped <= 4) return 1;
  if (clamped <= 14) return 2;
  return 3;
}

// MARK: Infrastructure

/// Mirror of `MineInfrastructureEngine`. Counts are deliberately small: four carts on a
/// rail read as an operation, twelve read as clutter (D-059).
export const MAXIMUM_SUPPORT_CREW = 4;
export const SUPPORT_CREW_LEVEL_OFFSET = 10;
export const MAXIMUM_CARTS = 4;
export const MAXIMUM_CARGO_SLOTS = 3;
export const MAXIMUM_SERVICE_LAMPS = 5;
const CART_GROWTH_LEVEL_STEP = 2;

function clampedLevel(level: number) {
  return Math.min(MAXIMUM_EQUIPMENT_LEVEL, Math.max(MINIMUM_EQUIPMENT_LEVEL, level));
}

/// Crew follows total investment rather than any single tool, so no upgrade path leaves
/// the passage empty.
export function supportCrewSize(drill: number, cart: number, lamp: number) {
  const total = clampedLevel(drill) + clampedLevel(cart) + clampedLevel(lamp);
  return Math.min(MAXIMUM_SUPPORT_CREW, Math.max(1, total - SUPPORT_CREW_LEVEL_OFFSET));
}

export function cartFleetSize(level: number, fleetModification: boolean) {
  const clamped = clampedLevel(level);
  if (clamped <= MINIMUM_EQUIPMENT_LEVEL) return 0;
  const earned = 1
    + Math.floor((clamped - MINIMUM_EQUIPMENT_LEVEL - 1) / CART_GROWTH_LEVEL_STEP);
  return Math.min(MAXIMUM_CARTS, earned + (fleetModification ? 1 : 0));
}

export function cartCargoSlots(level: number, freightModification: boolean) {
  const clamped = clampedLevel(level);
  if (clamped <= MINIMUM_EQUIPMENT_LEVEL) return 0;
  const earned = 1
    + Math.floor((clamped - MINIMUM_EQUIPMENT_LEVEL - 1) / CART_GROWTH_LEVEL_STEP);
  return Math.min(MAXIMUM_CARGO_SLOTS, earned + (freightModification ? 1 : 0));
}

export function serviceLampCount(level: number, reachModification: boolean) {
  return Math.min(
    MAXIMUM_SERVICE_LAMPS,
    Math.max(1, clampedLevel(level)) + (reachModification ? 1 : 0),
  );
}
