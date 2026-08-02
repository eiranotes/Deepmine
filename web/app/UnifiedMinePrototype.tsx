"use client";

import { useEffect, useMemo, useState } from "react";
import {
  METERS_PER_SEGMENT,
  type EquipmentKind,
  type EquipmentLevels,
  automationDamagePerSecond,
  criticalChance,
  criticalMultiplier,
  recommendMiningUpgrade,
  refinementCost,
  refinementMultiplier,
  refinementTiersUnlocked,
  segmentIndexForDepth,
  segmentIntegrity,
  segmentOre,
  tapDamage,
  unlockedMaximumLevel,
  upgradeCost,
} from "./coreBalance";
import styles from "./unified-mine.module.css";

type Mine = { depth: number; ore: number; damage: number; broken: number };
type Refinement = Record<EquipmentKind, number>;
const kinds: EquipmentKind[] = ["drill", "cart", "lamp"];
const labels = { drill: "드릴", cart: "광차", lamp: "램프" };
const initialEquipment: EquipmentLevels = { drill: 1, cart: 1, lamp: 1 };
const initialRefinement: Refinement = { drill: 0, cart: 0, lamp: 0 };
const initialMine: Mine = { depth: 8, ore: 100, damage: 0, broken: 2 };

function format(value: number) {
  if (!Number.isFinite(value)) return "∞";
  if (Math.abs(value) >= 1e9) return value.toExponential(2);
  return new Intl.NumberFormat("ko-KR", { maximumFractionDigits: value < 100 ? 2 : 0 }).format(value);
}

export function UnifiedMinePrototype() {
  const [mine, setMine] = useState(initialMine);
  const [equipment, setEquipment] = useState<EquipmentLevels>(initialEquipment);
  const [refinement, setRefinement] = useState<Refinement>(initialRefinement);
  const index = segmentIndexForDepth(mine.depth);
  const integrity = segmentIntegrity(index);
  const tap = tapDamage(equipment.drill, false, refinement.drill);
  const dps = automationDamagePerSecond(equipment.cart, false, refinement.cart);
  const critical = criticalChance(equipment.lamp);
  const criticalPower = criticalMultiplier(equipment.lamp, refinement.lamp);
  const unlocked = unlockedMaximumLevel(mine.depth);
  const recommended = recommendMiningUpgrade(equipment, mine.ore, mine.depth);
  const progress = Math.min(1, mine.damage / integrity);

  const stats = useMemo(() => [
    ["심도", `${mine.depth}m`], ["광석", format(mine.ore)],
    ["탭", format(tap)], ["자동 DPS", format(dps)],
    ["크리티컬", `${Math.round(critical * 100)}% ×${format(criticalPower)}`],
    ["구매 가능 레벨", `${unlocked}`],
  ], [mine.depth, mine.ore, tap, dps, critical, criticalPower, unlocked]);

  function applyDamage(amount: number) {
    setMine((current) => {
      let damage = current.damage + amount;
      let depth = current.depth;
      let ore = current.ore;
      let broken = current.broken;
      let face = segmentIntegrity(segmentIndexForDepth(depth));
      while (damage >= face) {
        const currentIndex = segmentIndexForDepth(depth);
        damage -= face;
        ore += segmentOre(currentIndex);
        depth += METERS_PER_SEGMENT;
        broken += 1;
        face = segmentIntegrity(segmentIndexForDepth(depth));
      }
      return { depth, ore, damage, broken };
    });
  }

  useEffect(() => {
    if (dps <= 0) return;
    const timer = window.setInterval(() => applyDamage(dps / 4), 250);
    return () => window.clearInterval(timer);
  }, [dps]);

  function buy(kind: EquipmentKind, count = 1) {
    setMine((currentMine) => {
      let ore = currentMine.ore;
      let level = equipment[kind];
      let bought = 0;
      while (bought < count && level < unlocked) {
        const cost = upgradeCost(kind, level);
        if (cost == null || cost > ore) break;
        ore -= cost;
        level += 1;
        bought += 1;
      }
      if (bought > 0) setEquipment((current) => ({ ...current, [kind]: level }));
      return { ...currentMine, ore };
    });
  }

  function refine(kind: EquipmentKind) {
    const next = refinement[kind] + 1;
    if (next > refinementTiersUnlocked(equipment[kind])) return;
    const cost = refinementCost(kind, next);
    if (cost > mine.ore) return;
    setMine((current) => ({ ...current, ore: current.ore - cost }));
    setRefinement((current) => ({ ...current, [kind]: next }));
  }

  return (
    <main className={styles.shell}>
      <header className={styles.header}>
        <p>DEEPMINE · UNIFIED CORE</p>
        <h1>연속 갱도</h1>
        <span>웹과 iOS가 같은 암반·장비·정련 규칙을 사용합니다.</span>
      </header>
      <section className={styles.stats}>
        {stats.map(([label, value]) => <div key={label}><span>{label}</span><strong>{value}</strong></div>)}
      </section>
      <section className={styles.face} onClick={() => applyDamage(tap)}>
        <div className={styles.rock} style={{ opacity: 1 - progress * 0.35 }} />
        <div className={styles.faceCopy}>
          <span>암반 #{index}</span><strong>{Math.round(progress * 100)}%</strong>
          <small>눌러서 타격 · 파괴 보상 {format(segmentOre(index))}</small>
        </div>
      </section>
      <section className={styles.recommendation}>
        <span>현재 추천</span>
        <strong>{recommended ? `${labels[recommended]} Lv.${equipment[recommended] + 1}` : "구매 가능 장비 없음"}</strong>
        {recommended && <button onClick={() => buy(recommended)}>추천 구매</button>}
      </section>
      <section className={styles.equipment}>
        {kinds.map((kind) => {
          const level = equipment[kind];
          const cost = upgradeCost(kind, level);
          const nextTier = refinement[kind] + 1;
          const canRefine = nextTier <= refinementTiersUnlocked(level);
          return <article key={kind}>
            <h2>{labels[kind]} <b>Lv.{level}</b></h2>
            <p>{kind === "drill" ? `탭 ${format(tap)}` : kind === "cart" ? `자동 ${format(dps)}/초` : `크리티컬 ${Math.round(critical * 100)}%`}</p>
            <div className={styles.actions}>
              <button disabled={level >= unlocked || cost == null || cost > mine.ore} onClick={() => buy(kind)}>+1 · {cost == null ? "—" : format(cost)}</button>
              <button disabled={level >= unlocked} onClick={() => buy(kind, 10)}>×10</button>
            </div>
            <button className={styles.refine} disabled={!canRefine || refinementCost(kind, nextTier) > mine.ore} onClick={() => refine(kind)}>
              정련 {refinement[kind]} → {nextTier} · ×{format(refinementMultiplier(nextTier))}
            </button>
          </article>;
        })}
      </section>
      <button className={styles.reset} onClick={() => { setMine(initialMine); setEquipment(initialEquipment); setRefinement(initialRefinement); }}>초기화</button>
    </main>
  );
}
