import {
  rigToolVisualState,
  type EquipmentKind,
  type RigToolVisualState,
} from "./coreBalance.ts";

const equipmentCodes: Record<EquipmentKind, string> = {
  drill: "D",
  cart: "C",
  lamp: "L",
};

export function rigHousingAssetName(visual: RigToolVisualState) {
  return `assets/rig/RigHousing_generation${visual.housingVariant}.png`;
}

/// The installation message names the physical object that changed. This keeps a level
/// purchase from collapsing into an abstract damage or production percentage.
export function rigUpgradePhysicalDetail(
  kind: EquipmentKind,
  beforeLevel: number,
  afterLevel: number,
) {
  const before = rigToolVisualState(beforeLevel);
  const after = rigToolVisualState(afterLevel);
  const code = equipmentCodes[kind];
  const prefix = `${code}${after.level}`;

  if (after.generation !== before.generation) {
    return `${prefix} · G${after.generation} · ${after.housingVariant}형 하우징 교체`;
  }
  if (after.artTier !== before.artTier) {
    return `${prefix} · T${before.artTier}→T${after.artTier} 본체 교체 · 정비 셀 ${after.upgradeCells}/4`;
  }
  return `${prefix} · 정비 셀 ${before.upgradeCells}→${after.upgradeCells}/4 증설`;
}
