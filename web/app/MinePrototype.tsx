"use client";

/* eslint-disable @next/next/no-img-element */
import {
  CSSProperties,
  type PointerEvent as ReactPointerEvent,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
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
const PIXELS_PER_METER = 28;
const AUTO_DAMAGE_STEP_MS = 120;

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

const initialEquipment: EquipmentState = { drill: 4, cart: 5, lamp: 2 };
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

function isSecondaryControl(target: EventTarget | null) {
  return (
    target instanceof Element
    && target.closest("button, a, input, select, textarea, [data-no-mine]") !== null
  );
}

function rockAssetAt(depth: number) {
  if (depth >= 1600) return "/assets/shaft/ShaftRock_abyss.png";
  if (depth >= 800) return "/assets/shaft/ShaftRock_ruins.png";
  if (depth >= 240) return "/assets/shaft/ShaftRock_crystal.png";
  return "/assets/shaft/ShaftRock_entry.png";
}

export function MinePrototype() {
  const [mine, setMine] = useState<MineState>({
    depth: 8,
    recordDepth: 8,
    ore: 1840,
    damage: 0,
    brokenLayers: 2,
    boreHistory: [3, 4],
  });
  const [equipment, setEquipment] = useState<EquipmentState>(initialEquipment);
  const [specializations, setSpecializations] =
    useState<Specializations>(initialSpecializations);
  const [hitPulse, setHitPulse] = useState(0);
  const [collapsePulse, setCollapsePulse] = useState(0);
  const [lastGain, setLastGain] = useState<number | null>(null);
  const [isCritical, setIsCritical] = useState(false);
  const [isBreaking, setIsBreaking] = useState(false);
  const [isPressing, setIsPressing] = useState(false);
  const [lastStrikeSource, setLastStrikeSource] = useState<"manual" | "auto">("auto");
  const pointerRef = useRef<{
    id: number;
    x: number;
    y: number;
    cancelled: boolean;
  } | null>(null);
  const breakTimerRef = useRef<number | null>(null);
  const previousBrokenLayersRef = useRef(mine.brokenLayers);

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
    (
      rawDamage: number,
      critical = false,
      drillLevel = 1,
      payoutMultiplier = 1,
      showsImpact = true,
    ) => {
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
      if (showsImpact) {
        setIsCritical(critical);
        setHitPulse((value) => value + 1);
      }
    },
    [],
  );

  useEffect(() => {
    if (automation <= 0) return;
    const damageTimer = window.setInterval(
      () =>
        applyDamage(
          automation * (AUTO_DAMAGE_STEP_MS / 1000),
          false,
          equipment.drill,
          oreMultiplier,
          false,
        ),
      AUTO_DAMAGE_STEP_MS,
    );
    const swingTimer = window.setInterval(() => {
      setLastStrikeSource("auto");
      setIsCritical(false);
      setHitPulse((value) => value + 1);
    }, 820);
    return () => {
      window.clearInterval(damageTimer);
      window.clearInterval(swingTimer);
    };
  }, [applyDamage, automation, equipment.drill, oreMultiplier]);

  useEffect(() => {
    if (mine.brokenLayers <= previousBrokenLayersRef.current) return;
    previousBrokenLayersRef.current = mine.brokenLayers;
    setCollapsePulse((value) => value + 1);
    setIsBreaking(true);
    if (breakTimerRef.current !== null) window.clearTimeout(breakTimerRef.current);
    breakTimerRef.current = window.setTimeout(() => setIsBreaking(false), 560);
  }, [mine.brokenLayers]);

  useEffect(
    () => () => {
      if (breakTimerRef.current !== null) window.clearTimeout(breakTimerRef.current);
    },
    [],
  );

  const strike = () => {
    const criticalEvery = Math.max(2, Math.round(1 / chance));
    const critical = (hitPulse + 1) % criticalEvery === 0;
    setLastStrikeSource("manual");
    applyDamage(critical ? tap * 3 : tap, critical, equipment.drill, oreMultiplier);
  };

  const handleMinePointerDown = (event: ReactPointerEvent<HTMLElement>) => {
    if (!event.isPrimary || event.button !== 0 || isSecondaryControl(event.target)) return;
    pointerRef.current = {
      id: event.pointerId,
      x: event.clientX,
      y: event.clientY,
      cancelled: false,
    };
    event.currentTarget.setPointerCapture(event.pointerId);
    setIsPressing(true);
  };

  const handleMinePointerMove = (event: ReactPointerEvent<HTMLElement>) => {
    const pointer = pointerRef.current;
    if (pointer === null || pointer.id !== event.pointerId || pointer.cancelled) return;
    if (Math.hypot(event.clientX - pointer.x, event.clientY - pointer.y) <= 18) return;
    pointer.cancelled = true;
    setIsPressing(false);
  };

  const handleMinePointerUp = (event: ReactPointerEvent<HTMLElement>) => {
    const pointer = pointerRef.current;
    if (pointer === null || pointer.id !== event.pointerId) return;
    pointerRef.current = null;
    setIsPressing(false);
    if (event.currentTarget.hasPointerCapture(event.pointerId)) {
      event.currentTarget.releasePointerCapture(event.pointerId);
    }
    if (!pointer.cancelled) strike();
  };

  const handleMinePointerCancel = (event: ReactPointerEvent<HTMLElement>) => {
    if (pointerRef.current?.id !== event.pointerId) return;
    pointerRef.current = null;
    setIsPressing(false);
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
        "--rock-image": `url("${rockAssetAt(headDepth)}")`,
        "--rock-phase": `${-((headDepth * PIXELS_PER_METER) % 320)}px`,
        "--surface-y": `${16 - headDepth * PIXELS_PER_METER}px`,
        "--fracture-reveal": `${progress <= 0 ? 0 : 18 + progress * 142}px`,
        "--fracture-opacity": `${progress <= 0 ? 0 : 0.58 + progress * 0.42}`,
        "--cart-duration": `${Math.max(1.9, 4.8 - equipment.cart * 0.18 - (specializations.cart === "fleet" ? 0.65 : 0))}s`,
        "--rig-scale": `${1 + (equipmentTier(equipment.drill) - 1) * 0.12}`,
        "--impact-kick": `${specializations.drill === "impact" ? 1.34 : 1}`,
      }) as CSSProperties,
    [
      equipment.drill,
      equipment.cart,
      equipment.lamp,
      headDepth,
      progress,
      specializations.drill,
      specializations.cart,
      specializations.lamp,
    ],
  );

  const fractureAsset =
    progress > 0.67
      ? "/assets/shaft/ShaftFractureVertical_heavy.png"
      : progress > 0.33
        ? "/assets/shaft/ShaftFractureVertical_medium.png"
        : "/assets/shaft/ShaftFractureVertical_light.png";

  const depthMarks = useMemo(() => {
    const first = Math.max(0, Math.floor(headDepth / METERS_PER_LAYER) * METERS_PER_LAYER - 16);
    return Array.from({ length: 10 }, (_, index) => first + index * METERS_PER_LAYER);
  }, [headDepth]);

  const passageHistory = useMemo(
    () =>
      mine.boreHistory.map((drillLevel, index) => ({
        depth: mine.depth - (mine.boreHistory.length - index) * METERS_PER_LAYER,
        drillLevel,
      })),
    [mine.boreHistory, mine.depth],
  );

  return (
    <main
      className={`${styles.page} ${isPressing ? styles.pagePressed : ""}`}
      onPointerDown={handleMinePointerDown}
      onPointerMove={handleMinePointerMove}
      onPointerUp={handleMinePointerUp}
      onPointerCancel={handleMinePointerCancel}
    >
      <div className={styles.appFrame}>
        <header className={styles.header}>
          <div>
            <p className={styles.eyebrow}>DEEPMINE / WEB PROTOTYPE</p>
            <h1>오늘의 갱도</h1>
          </div>
          <div className={styles.headerActions}>
            <div className={styles.oreCounter} aria-label={`광석 ${formatNumber(mine.ore)}`}>
              <span aria-hidden="true">◆</span>
              <strong>{formatNumber(mine.ore)}</strong>
              <small>광석</small>
            </div>
            <button className={styles.strikeAssist} type="button" onClick={strike}>
              탭 가속
              <small>자동 굴착 중</small>
            </button>
          </div>
        </header>

        <section className={styles.shaftSection} aria-labelledby="shaft-heading">
          <div className={styles.shaftHeading}>
            <div>
              <p className={styles.sectionLabel}>하나로 이어진 암반</p>
              <h2 id="shaft-heading">통로 끝을 계속 굴착</h2>
            </div>
            <div className={styles.faceProgress}>
              <span>다음 4m</span>
              <strong>{Math.round(progress * 100)}%</strong>
            </div>
          </div>

          <div className={styles.progressTrack} aria-hidden="true">
            <span style={{ width: `${progress * 100}%` }} />
          </div>

          <div
            className={`${styles.shaft} ${isCritical ? styles.critical : ""} ${isBreaking ? styles.breaking : ""} ${isPressing ? styles.shaftPressed : ""} ${specializations.drill === "impact" ? styles.impactBuild : ""} ${specializations.lamp === "fortune" ? styles.fortuneBuild : ""}`}
            style={sceneStyle}
            role="img"
            aria-label={`자동 굴착 중인 연속 갱도. 굴착 헤드 ${headDepth.toFixed(1)}미터, 다음 지층 ${Math.round(progress * 100)}퍼센트 굴착`}
          >
            <div className={styles.rockWorld} aria-hidden="true" />

            <img
              className={styles.continuousSurface}
              src="/assets/shaft/ShaftSurface.png"
              width={320}
              height={90}
              alt=""
              aria-hidden="true"
            />

            <div className={styles.openShaft} aria-hidden="true">
              <span className={styles.tunnelVoid} />
              <span className={styles.tunnelLeftEdge} />
              <span className={styles.tunnelRightEdge} />
              {equipment.cart > 1 && <span className={styles.continuousRail} />}
              {Array.from({ length: cartCount }, (_, index) => (
                <img
                  className={`${styles.continuousCart} ${specializations.cart === "freight" ? styles.freightCart : ""}`}
                  style={{ animationDelay: `${index * -1.3}s` }}
                  src={`/assets/equipment/Equipment_cart_tier${equipmentTier(equipment.cart)}.png`}
                  width={32}
                  height={32}
                  alt=""
                  key={index}
                />
              ))}
            </div>

            <div className={styles.passageHistory} aria-hidden="true">
              {passageHistory.map(({ depth, drillLevel }, index) => (
                <div
                  className={styles.supportFrame}
                  style={{
                    "--history-offset": `${(depth - headDepth) * PIXELS_PER_METER}px`,
                    "--history-width": `${24 + Math.min(9, drillLevel * 0.9)}%`,
                  } as CSSProperties}
                  key={`${depth}-${drillLevel}`}
                >
                  <span />
                  {index < installedLampCount && (
                    <img
                      className={styles.continuousLamp}
                      src={`/assets/equipment/Equipment_lamp_tier${equipmentTier(equipment.lamp)}.png`}
                      width={32}
                      height={32}
                      alt=""
                    />
                  )}
                  {index % 2 === 0 && (
                    <img
                      className={styles.continuousScar}
                      src="/assets/shaft/ShaftFractureVertical_light.png"
                      width={72}
                      height={160}
                      alt=""
                    />
                  )}
                </div>
              ))}
            </div>

            <div className={styles.shaftStatus} aria-label="현재 채굴 상태">
              <div><span>현재 심도</span><strong>{headDepth.toFixed(1)}m</strong></div>
              <div><span>최고 심도</span><strong>{Math.max(mine.recordDepth, headDepth).toFixed(1)}m</strong></div>
              <div><span>탭 위력</span><strong>{formatNumber(tap)}</strong></div>
              <div><span>자동 굴착</span><strong>{formatNumber(automation)}/초</strong></div>
            </div>

            <div className={styles.workLine} aria-hidden="true">
              <img
                className={styles.continuousGantry}
                src="/assets/shaft/ShaftGantry.png"
                width={320}
                height={128}
                alt=""
              />
              <div className={styles.fractureClip}>
                <img
                  className={styles.verticalFracture}
                  src={fractureAsset}
                  width={72}
                  height={160}
                  alt=""
                  key={`${fractureAsset}-${hitPulse}`}
                />
              </div>
              <img className={styles.continuousMiner} src="/assets/miner.png" width={72} height={72} alt="" />
              <img
                className={styles.miningPickaxe}
                src="/assets/shaft/MiningPickaxe.png"
                width={64}
                height={64}
                alt=""
                key={`pickaxe-${hitPulse}`}
              />
              <img
                className={styles.continuousDrill}
                src={`/assets/equipment/Equipment_drill_tier${equipmentTier(equipment.drill)}.png`}
                width={64}
                height={64}
                alt=""
              />
              <div className={styles.continuousDebris} key={`continuous-debris-${hitPulse}`}>
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
                className={styles.continuousWeakPoint}
                src={isCritical ? "/assets/effects/WeakPoint_hit.png" : "/assets/effects/WeakPoint_idle.png"}
                width={64}
                height={64}
                alt=""
              />
              <span className={styles.continuousHitLabel} key={`continuous-hit-${hitPulse}`}>
                {lastStrikeSource === "auto"
                  ? "자동 굴착"
                  : isCritical
                    ? `급소 −${tap * 3}`
                    : `−${tap}`}
              </span>
              {lastGain !== null && <span className={styles.continuousOreGain}>+{lastGain} 광석</span>}
            </div>

            {isBreaking && (
              <div className={styles.collapseBand} aria-hidden="true" key={`collapse-${collapsePulse}`}>
                <span className={styles.collapseLeft} />
                <span className={styles.collapseRight} />
                <span className={styles.collapseGap} />
              </div>
            )}

            <div className={styles.continuousDarkness} aria-hidden="true" />

            <div className={styles.continuousDepthOverlay} aria-hidden="true">
              {depthMarks.map((depth) => (
                <span
                  className={Math.abs(depth - headDepth) < 2 ? styles.currentDepthMark : ""}
                  style={{ top: `calc(var(--workline) + ${(depth - headDepth) * PIXELS_PER_METER}px)` }}
                  key={depth}
                >
                  {depth}m
                </span>
              ))}
            </div>

            <div className={styles.descentIndicator} aria-hidden="true">
              <span>자동 하강</span>
              <strong>{headDepth.toFixed(1)}m</strong>
              <i>↓</i>
            </div>

          </div>
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
