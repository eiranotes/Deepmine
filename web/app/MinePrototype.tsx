"use client";

/* eslint-disable @next/next/no-img-element */
import { CSSProperties, useCallback, useEffect, useMemo, useState } from "react";
import styles from "./mine.module.css";

type EquipmentKind = "drill" | "cart" | "lamp";

type MineState = {
  depth: number;
  recordDepth: number;
  ore: number;
  damage: number;
  brokenLayers: number;
  boreHistory: number[];
};

type EquipmentState = Record<EquipmentKind, number>;
type Specializations = {
  drill: "wide" | "impact" | null;
  cart: "fleet" | "freight" | null;
  lamp: "reach" | "fortune" | null;
};

const METERS_PER_LAYER = 4;

const equipmentCopy: Record<
  EquipmentKind,
  { name: string; note: string; action: string }
> = {
  drill: {
    name: "드릴",
    note: "한 번의 타격과 균열 범위",
    action: "타격",
  },
  cart: {
    name: "광차",
    note: "자동 굴착과 운반 횟수",
    action: "자동",
  },
  lamp: {
    name: "램프",
    note: "앞으로 보이는 지층과 급소",
    action: "시야",
  },
};

const initialEquipment: EquipmentState = { drill: 4, cart: 3, lamp: 2 };
const initialSpecializations: Specializations = { drill: null, cart: null, lamp: null };

const specializationOptions = {
  drill: [
    { id: "wide", title: "확폭 비트", detail: "통로 폭과 파편 범위 증가" },
    { id: "impact", title: "충격 비트", detail: "통로는 좁게, 탭 위력 ×1.35" },
  ],
  cart: [
    { id: "fleet", title: "쌍선 레일", detail: "광차 한 대 추가, 자동 굴착 ×1.25" },
    { id: "freight", title: "대형 호퍼", detail: "지층마다 얻는 광석 ×1.25" },
  ],
  lamp: [
    { id: "reach", title: "장거리 반사경", detail: "아래 지층 시야가 크게 확장" },
    { id: "fortune", title: "광맥 렌즈", detail: "급소 확률 +8%p" },
  ],
} as const;

function integrityAt(depth: number) {
  return Math.round(104 * Math.pow(1.018, depth / METERS_PER_LAYER));
}

function tapPower(level: number) {
  return Math.round(12 * Math.pow(1.16, level - 1));
}

function automationPower(level: number) {
  return level <= 1 ? 0 : Math.round(5 * Math.pow(1.22, level - 2));
}

function criticalChance(level: number) {
  return Math.min(0.42, 0.08 + level * 0.025);
}

function upgradeCost(kind: EquipmentKind, level: number) {
  const base = { drill: 190, cart: 270, lamp: 340 }[kind];
  return Math.ceil(base * Math.pow(1.31, level - 1));
}

function equipmentTier(level: number) {
  if (level >= 9) return 3;
  if (level >= 5) return 2;
  return 1;
}

function formatNumber(value: number) {
  return new Intl.NumberFormat("ko-KR", { maximumFractionDigits: 0 }).format(value);
}

export function MinePrototype() {
  const [mine, setMine] = useState<MineState>({
    depth: 104,
    recordDepth: 148,
    ore: 1840,
    damage: 62,
    brokenLayers: 26,
    boreHistory: [2, 2, 3, 3, 3, 4, 4],
  });
  const [equipment, setEquipment] = useState<EquipmentState>(initialEquipment);
  const [specializations, setSpecializations] =
    useState<Specializations>(initialSpecializations);
  const [hitPulse, setHitPulse] = useState(0);
  const [lastGain, setLastGain] = useState<number | null>(null);
  const [isCritical, setIsCritical] = useState(false);

  const integrity = integrityAt(mine.depth);
  const progress = Math.min(1, mine.damage / integrity);
  const tap = Math.round(
    tapPower(equipment.drill) * (specializations.drill === "impact" ? 1.35 : 1),
  );
  const automation = Math.round(
    automationPower(equipment.cart) * (specializations.cart === "fleet" ? 1.25 : 1),
  );
  const chance = Math.min(
    0.5,
    criticalChance(equipment.lamp) + (specializations.lamp === "fortune" ? 0.08 : 0),
  );
  const oreMultiplier = specializations.cart === "freight" ? 1.25 : 1;
  const headDepth = mine.depth + progress * METERS_PER_LAYER;
  const cartCount =
    equipment.cart <= 1
      ? 0
      : Math.min(
          4,
          Math.max(1, equipmentTier(equipment.cart))
            + (specializations.cart === "fleet" ? 1 : 0),
        );
  const installedLampCount = Math.min(
    7,
    Math.max(1, equipmentTier(equipment.lamp) + 1)
      + (specializations.lamp === "reach" ? 2 : 0),
  );
  const debrisCount = Math.min(
    10,
    3 + equipmentTier(equipment.drill) * 2
      + (specializations.drill === "wide" ? 2 : 0),
  );

  const applyDamage = useCallback(
    (rawDamage: number, critical = false, drillLevel = 1, payoutMultiplier = 1) => {
      setMine((current) => {
        let damage = current.damage + rawDamage;
        let depth = current.depth;
        let ore = current.ore;
        let broken = current.brokenLayers;
        let boreHistory = current.boreHistory;
        let gained = 0;
        let faceIntegrity = integrityAt(depth);

        while (damage >= faceIntegrity) {
          damage -= faceIntegrity;
          const layerOre = Math.round(
            (28 + depth * 0.12 + (broken % 7 === 6 ? 38 : 0)) * payoutMultiplier,
          );
          gained += layerOre;
          ore += layerOre;
          depth += METERS_PER_LAYER;
          broken += 1;
          boreHistory = [...boreHistory, drillLevel].slice(-7);
          faceIntegrity = integrityAt(depth);
        }

        if (gained > 0) {
          setLastGain(gained);
          window.setTimeout(() => setLastGain(null), 900);
        }

        return {
          depth,
          recordDepth: Math.max(current.recordDepth, depth),
          ore,
          damage,
          brokenLayers: broken,
          boreHistory,
        };
      });
      setIsCritical(critical);
      setHitPulse((value) => value + 1);
    },
    [],
  );

  useEffect(() => {
    if (automation <= 0) return;
    const timer = window.setInterval(
      () => applyDamage(automation / 5, false, equipment.drill, oreMultiplier),
      200,
    );
    return () => window.clearInterval(timer);
  }, [applyDamage, automation, equipment.drill, oreMultiplier]);

  const strike = () => {
    const criticalEvery = Math.max(2, Math.round(1 / chance));
    const critical = (hitPulse + 1) % criticalEvery === 0;
    applyDamage(critical ? tap * 3 : tap, critical, equipment.drill, oreMultiplier);
  };

  const upgrade = (kind: EquipmentKind) => {
    const cost = upgradeCost(kind, equipment[kind]);
    if (mine.ore < cost) return;
    setMine((current) => ({ ...current, ore: current.ore - cost }));
    setEquipment((current) => ({ ...current, [kind]: current[kind] + 1 }));
  };

  const specialize = (kind: EquipmentKind, option: string) => {
    if (specializations[kind] !== null) return;
    const cost = { drill: 460, cart: 560, lamp: 660 }[kind];
    if (mine.ore < cost) return;
    setMine((current) => ({ ...current, ore: current.ore - cost }));
    setSpecializations((current) => ({ ...current, [kind]: option } as Specializations));
  };

  const sceneStyle = useMemo(
    () =>
      ({
        "--break-progress": progress.toFixed(3),
        "--cut-width": `${24 + Math.min(9, equipment.drill * 0.9) + (specializations.drill === "wide" ? 8 : 0)}%`,
        "--lamp-radius": `${18 + Math.min(20, equipment.lamp * 2.4) + (specializations.lamp === "reach" ? 8 : 0)}%`,
        "--geology-shift": `${-(mine.brokenLayers - 26 + progress) * 14}px`,
        "--head-top": `${47 + progress * 18}%`,
        "--hole-width": `${42 + progress * 96 + (specializations.drill === "wide" ? 26 : 0)}px`,
        "--hole-height": `${24 + progress * 96}px`,
        "--fracture-size": `${90 + progress * 96}px`,
        "--fracture-opacity": `${0.4 + progress * 0.55}`,
        "--cart-duration": `${Math.max(1.9, 4.8 - equipment.cart * 0.18 - (specializations.cart === "fleet" ? 0.65 : 0))}s`,
        "--rig-scale": `${1 + (equipmentTier(equipment.drill) - 1) * 0.12}`,
        "--impact-kick": `${specializations.drill === "impact" ? 1.34 : 1}`,
      }) as CSSProperties,
    [
      equipment.drill,
      equipment.cart,
      equipment.lamp,
      mine.brokenLayers,
      progress,
      specializations.drill,
      specializations.cart,
      specializations.lamp,
    ],
  );

  const fractureAsset =
    progress > 0.67
      ? "/assets/effects/Fracture_heavy.png"
      : progress > 0.33
        ? "/assets/effects/Fracture_medium.png"
        : "/assets/effects/Fracture_light.png";

  return (
    <main className={styles.page}>
      <div className={styles.appFrame}>
        <header className={styles.header}>
          <div>
            <p className={styles.eyebrow}>DEEPMINE / WEB PROTOTYPE</p>
            <h1>오늘의 갱도</h1>
            <p className={styles.headerNote}>큰 지층 하나를, 가운데부터 아래로 뚫습니다.</p>
          </div>
          <div className={styles.oreCounter} aria-label={`광석 ${formatNumber(mine.ore)}`}>
            <span aria-hidden="true">◆</span>
            <strong>{formatNumber(mine.ore)}</strong>
            <small>광석</small>
          </div>
        </header>

        <section className={styles.statusStrip} aria-label="현재 채굴 상태">
          <div>
            <span>현재 심도</span>
            <strong>{headDepth.toFixed(1)}m</strong>
          </div>
          <div>
            <span>최고 심도</span>
            <strong>{mine.recordDepth}m</strong>
          </div>
          <div>
            <span>타격</span>
            <strong>{formatNumber(tap)}</strong>
          </div>
          <div>
            <span>자동</span>
            <strong>{automation > 0 ? `${formatNumber(automation)}/초` : "—"}</strong>
          </div>
        </section>

        <section className={styles.shaftSection} aria-labelledby="shaft-heading">
          <div className={styles.shaftHeading}>
            <div>
              <p className={styles.sectionLabel}>연속 지층</p>
              <h2 id="shaft-heading">막장을 눌러 굴착</h2>
            </div>
            <div className={styles.faceProgress}>
              <span>다음 4m</span>
              <strong>{Math.round(progress * 100)}%</strong>
            </div>
          </div>

          <div className={styles.progressTrack} aria-hidden="true">
            <span style={{ width: `${progress * 100}%` }} />
          </div>

          <button
            className={`${styles.shaft} ${isCritical ? styles.critical : ""} ${specializations.drill === "impact" ? styles.impactBuild : ""} ${specializations.lamp === "fortune" ? styles.fortuneBuild : ""}`}
            style={sceneStyle}
            type="button"
            onClick={strike}
            aria-label={`막장 타격. 굴착 헤드 ${headDepth.toFixed(1)}미터, 다음 지층 ${Math.round(progress * 100)}퍼센트 굴착`}
          >
            <div className={styles.geology} aria-hidden="true">
              <div className={`${styles.stratum} ${styles.entryRock}`} />
              <div className={`${styles.stratum} ${styles.crystalRock}`} />
              <div className={`${styles.stratum} ${styles.ruinsRock}`} />
              <div className={`${styles.stratum} ${styles.abyssRock}`} />
              <img
                className={styles.surfaceCanopy}
                src="/assets/shaft/ShaftSurface.png"
                width={320}
                height={90}
                alt=""
              />
              <img
                className={styles.futureSeam}
                src="/assets/shaft/SeamVein.png"
                width={320}
                height={128}
                alt=""
              />
            </div>

            <div className={styles.boreHistory} aria-hidden="true">
              {mine.boreHistory.map((drillLevel, index) => (
                <span
                  className={styles.boreSegment}
                  style={{
                    top: `${4 + index * 7.55}%`,
                    width: `${19 + Math.min(11, drillLevel * 1.7)}%`,
                  }}
                  key={`${index}-${drillLevel}`}
                />
              ))}
            </div>

            <div className={styles.pastTunnel} aria-hidden="true">
              {Array.from({ length: 6 }, (_, index) => (
                <span className={styles.support} style={{ top: `${12 + index * 15}%` }} key={index} />
              ))}
              {equipment.cart > 1 && <span className={styles.rail} />}
              {Array.from({ length: cartCount }, (_, index) => (
                <img
                  className={`${styles.movingCart} ${specializations.cart === "freight" ? styles.freightCart : ""}`}
                  style={{ animationDelay: `${index * -1.3}s` }}
                  src={`/assets/equipment/Equipment_cart_tier${equipmentTier(equipment.cart)}.png`}
                  width={32}
                  height={32}
                  alt=""
                  key={index}
                />
                ),
              )}
              {Array.from({ length: installedLampCount }, (_, index) => (
                <img
                  className={styles.installedLamp}
                  style={{
                    top: `${18 + index * 14}%`,
                    left: index % 2 === 0 ? "4%" : "calc(96% - 22px)",
                  }}
                  src={`/assets/equipment/Equipment_lamp_tier${equipmentTier(equipment.lamp)}.png`}
                  width={32}
                  height={32}
                  alt=""
                  key={index}
                />
              ))}
              <span className={styles.recordPlate}>최고 {mine.recordDepth}m</span>
            </div>

            <div className={styles.historyScars} aria-hidden="true">
              {[18, 28, 39, 49].map((top, index) => (
                <img
                  src={`/assets/effects/Fracture_${["light", "medium", "heavy", "medium"][index]}.png`}
                  className={styles.historyScar}
                  style={{
                    top: `${top}%`,
                    left: index % 2 === 0 ? "26%" : "62%",
                    transform: `rotate(${index % 2 === 0 ? -18 : 22}deg)`,
                  }}
                  width={64}
                  height={64}
                  alt=""
                  key={top}
                />
              ))}
            </div>

            <div className={styles.currentWork} aria-hidden="true">
              <img
                className={styles.gantry}
                src="/assets/shaft/ShaftGantry.png"
                width={320}
                height={128}
                alt=""
              />
              <div className={styles.faceHole} />
              <img
                className={styles.currentFracture}
                src={fractureAsset}
                width={64}
                height={64}
                alt=""
                key={`${fractureAsset}-${hitPulse}`}
              />
              <img
                className={styles.miner}
                src="/assets/miner.png"
                width={72}
                height={72}
                alt=""
                key={`miner-${hitPulse}`}
              />
              <img
                className={styles.drillRig}
                src={`/assets/equipment/Equipment_drill_tier${equipmentTier(equipment.drill)}.png`}
                width={64}
                height={64}
                alt=""
              />
              <div className={styles.debrisCloud} key={`debris-${hitPulse}`}>
                {Array.from({ length: debrisCount }, (_, index) => (
                  <span
                    style={{
                      "--chip-x": `${(index % 2 === 0 ? -1 : 1) * (22 + (index * 17) % 62)}px`,
                      "--chip-y": `${-18 - (index * 13) % 64}px`,
                      "--chip-delay": `${(index % 4) * 18}ms`,
                    } as CSSProperties}
                    key={index}
                  />
                ))}
              </div>
              <img
                className={styles.weakPoint}
                src={isCritical ? "/assets/effects/WeakPoint_hit.png" : "/assets/effects/WeakPoint_idle.png"}
                width={64}
                height={64}
                alt=""
              />
              <span className={styles.hitLabel} key={`hit-${hitPulse}`}>
                {isCritical ? `급소 −${tap * 3}` : `−${tap}`}
              </span>
              {lastGain !== null && <span className={styles.oreGain}>+{lastGain} 광석</span>}
            </div>

            <div className={styles.futureDarkness} aria-hidden="true" />

            <div className={styles.depthOverlay} aria-hidden="true">
              <span style={{ top: "13%" }}>{Math.max(0, mine.depth - 20)}m</span>
              <span style={{ top: "34%" }}>{Math.max(0, mine.depth - 12)}m</span>
              <span className={styles.currentDepthMark}>
                {headDepth.toFixed(1)}m ↓
              </span>
              <span style={{ top: "77%" }}>{mine.depth + 8}m</span>
              <span style={{ top: "92%" }}>{mine.depth + 16}m</span>
            </div>

            <div className={styles.sceneLegend} aria-hidden="true">
              <span>지나온 길</span>
              <span>현재 막장</span>
              <span>앞으로 팔 지층</span>
            </div>
          </button>
        </section>

        <section className={styles.equipmentSection} aria-labelledby="equipment-heading">
          <div className={styles.sectionIntro}>
            <div>
              <p className={styles.sectionLabel}>장비가 장면을 바꿉니다</p>
              <h2 id="equipment-heading">채굴 설비</h2>
            </div>
            <p>숫자만 오르지 않습니다. 균열·광차·조명이 즉시 달라집니다.</p>
          </div>

          <div className={styles.equipmentGrid}>
            {(Object.keys(equipment) as EquipmentKind[]).map((kind) => {
              const level = equipment[kind];
              const cost = upgradeCost(kind, level);
              const affordable = mine.ore >= cost;
              const visualValue =
                kind === "drill"
                  ? `${formatNumber(tapPower(level))} → ${formatNumber(tapPower(level + 1))}`
                  : kind === "cart"
                    ? `${formatNumber(automationPower(level))} → ${formatNumber(automationPower(level + 1))}/초`
                    : `${Math.round(criticalChance(level) * 100)} → ${Math.round(criticalChance(level + 1) * 100)}%`;

              return (
                <article className={styles.equipmentCard} key={kind}>
                  <div className={styles.equipmentTop}>
                    <div className={styles.equipmentArt}>
                      <img
                        src={`/assets/equipment/Equipment_${kind}_tier${equipmentTier(level)}.png`}
                        width={64}
                        height={64}
                        alt=""
                      />
                    </div>
                    <div>
                      <span>Lv. {level}</span>
                      <h3>{equipmentCopy[kind].name}</h3>
                    </div>
                  </div>
                  <p>{equipmentCopy[kind].note}</p>
                  <div className={styles.effectReadout}>
                    <span>{equipmentCopy[kind].action}</span>
                    <strong>{visualValue}</strong>
                  </div>
                  <button
                    type="button"
                    onClick={() => upgrade(kind)}
                    disabled={!affordable}
                    aria-label={`${equipmentCopy[kind].name} 레벨 ${level + 1} 강화, 광석 ${cost}`}
                  >
                    <span>Lv. {level + 1} 강화</span>
                    <strong>◆ {formatNumber(cost)}</strong>
                  </button>
                </article>
              );
            })}
          </div>

          <div className={styles.workshop}>
            <div className={styles.workshopHeading}>
              <div>
                <p className={styles.sectionLabel}>P6 / 선택형 개조</p>
                <h3>한 장비에 한 갈래만 설치</h3>
              </div>
              <p>싼 장비만 반복 구매하는 대신, 같은 장비도 광산의 모양과 운영을 다르게 만듭니다.</p>
            </div>
            <div className={styles.specializationList}>
              {(Object.keys(specializationOptions) as EquipmentKind[]).map((kind) => {
                const selected = specializations[kind];
                const cost = { drill: 460, cart: 560, lamp: 660 }[kind];
                return (
                  <div className={styles.specializationRow} key={kind}>
                    <strong>{equipmentCopy[kind].name}</strong>
                    <div className={styles.specializationChoices}>
                      {specializationOptions[kind].map((option) => {
                        const active = selected === option.id;
                        const locked = selected !== null && !active;
                        return (
                          <button
                            type="button"
                            className={active ? styles.selectedSpecialization : ""}
                            onClick={() => specialize(kind, option.id)}
                            disabled={locked || (selected === null && mine.ore < cost)}
                            aria-pressed={active}
                            key={option.id}
                          >
                            <span>
                              <strong>{option.title}</strong>
                              <small>{option.detail}</small>
                            </span>
                            <em>{active ? "설치됨" : locked ? "선택 잠김" : `◆ ${cost}`}</em>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </section>

        <footer className={styles.footer}>
          <p>웹 기준안 · 앱 포팅 전 검증용</p>
          <p>핵심 루프는 채굴 기준 언어와 설비 선택만 사용합니다.</p>
        </footer>
      </div>
    </main>
  );
}
