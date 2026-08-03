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
import { ResonanceEvent } from "./ResonanceEvent";
import {
  METERS_PER_SEGMENT,
  criticalChance,
  automationDamagePerSecond,
  type EquipmentKind,
  equipmentTier,
  freightOreMultiplier,
  segmentIndexForDepth,
  segmentIntegrity,
  segmentOre,
  serviceLampCount,
  supportCrewSize,
  cartCargoSlots,
  cartFleetSize,
  recommendMiningUpgrade,
  tapDamage,
  upgradeCost as coreUpgradeCost,
} from "./coreBalance";
import { assetPath } from "./assetPath";
import { miningCameraPose, MINING_PIXELS_PER_METER } from "./miningCamera";
import styles from "./mine.module.css";
import { strikeTiming, type StrikeVariant } from "./strikeFeedback";
import { useMiningAudio } from "./useMiningAudio";
import { useReducedMotionPreference } from "./useReducedMotionPreference";
import { RESONANCE_MULTIPLIER, useResonanceEvent } from "./useResonanceEvent";

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
type UpgradeEvent = {
  id: string;
  kind: EquipmentKind;
  level: number;
  detail: string;
};

const METERS_PER_LAYER = METERS_PER_SEGMENT;
const PIXELS_PER_METER = MINING_PIXELS_PER_METER;
const AUTO_STRIKE_MS = 820;

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

/// Match a fresh Core save: the player performs the real first strikes and saves for cart Lv.2
/// before automation begins.
const initialEquipment: EquipmentState = { drill: 1, cart: 1, lamp: 1 };
const initialSpecializations: Specializations = { drill: null, cart: null, lamp: null };
const equipmentKinds: EquipmentKind[] = ["drill", "cart", "lamp"];

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

/// Core rock is addressed by segment index; the prototype tracks metres because the scene
/// scrolls in metres. Both agree because the conversion is Core's own.
function integrityAt(depth: number) {
  return segmentIntegrity(segmentIndexForDepth(depth));
}

function layerOreAt(depth: number, payoutMultiplier: number) {
  return segmentOre(segmentIndexForDepth(depth)) * payoutMultiplier;
}

/// Core damage starts at 1.0 and a first cart hauls 0.56/s. Rounding those to integers —
/// which the demo numbers were large enough to survive — would erase the early game
/// entirely, so damage stays fractional and only the readout is rounded.
function upgradeCost(kind: EquipmentKind, level: number) {
  // Core returns nil at the level ceiling. Unreachable in a reference build, but an
  // unaffordable price keeps the buy path closed without a second branch everywhere.
  return coreUpgradeCost(kind, level) ?? Number.POSITIVE_INFINITY;
}





function installationDetail(
  kind: EquipmentKind,
  equipment: EquipmentState,
  specializations: Specializations,
) {
  if (kind === "drill") {
    return `작업조 ${supportCrewSize(equipment.drill, equipment.cart, equipment.lamp)}명 · 비트 티어 ${equipmentTier(equipment.drill)}`;
  }
  if (kind === "cart") {
    return `운행 ${cartFleetSize(equipment.cart, specializations.cart === "fleet")}대 · 적재 ${cartCargoSlots(equipment.cart, specializations.cart === "freight")}칸`;
  }
  return `작업등 ${serviceLampCount(equipment.lamp, specializations.lamp === "reach")}기 · 급소 ${Math.round(criticalChance(equipment.lamp) * 100)}%`;
}

function specializationInstallationDetail(
  kind: EquipmentKind,
  option: string,
  equipment: EquipmentState,
) {
  if (kind === "drill") {
    return option === "wide" ? "확폭 비트 · 통로 폭 증설" : "충격 비트 · 타격 출력 증폭";
  }
  if (kind === "cart") {
    return option === "fleet"
      ? `쌍선 레일 · 운행 ${cartFleetSize(equipment.cart, true)}대`
      : `대형 호퍼 · 적재 ${cartCargoSlots(equipment.cart, true)}칸`;
  }
  return option === "reach"
    ? `장거리 반사경 · 작업등 ${serviceLampCount(equipment.lamp, true)}기`
    : `광맥 렌즈 · 급소 ${Math.round(criticalChance(equipment.lamp, true) * 100)}%`;
}

/// Core's early numbers live below 10, where rounding to whole ore would print a tap of
/// 1.0 and a first cart of 0.56 as the same "1". Small values keep one decimal; once the
/// curve compounds past 100 the decimal stops carrying information and is dropped.
function formatNumber(value: number) {
  if (!Number.isFinite(value)) return "—";
  const digits = Math.abs(value) < 100 && !Number.isInteger(value) ? 1 : 0;
  return new Intl.NumberFormat("ko-KR", { maximumFractionDigits: digits }).format(value);
}

function formatSeconds(value: number) {
  if (value < 1) return "1초 이내";
  if (value < 10) return `${value.toFixed(1)}초`;
  return `${Math.ceil(value)}초`;
}

function upgradeEffect(kind: EquipmentKind, level: number) {
  if (kind === "drill") {
    return `탭 ${formatNumber(tapDamage(level))} → ${formatNumber(tapDamage(level + 1))}`;
  }
  if (kind === "cart") {
    return `자동 ${formatNumber(automationDamagePerSecond(level))} → ${formatNumber(automationDamagePerSecond(level + 1))}/초`;
  }
  return `급소 ${Math.round(criticalChance(level) * 100)} → ${Math.round(criticalChance(level + 1) * 100)}%`;
}

function isSecondaryControl(target: EventTarget | null) {
  return (
    target instanceof Element
    && target.closest("button, a, input, select, textarea, [data-no-mine]") !== null
  );
}

function rockAssetAt(depth: number) {
  if (depth >= 1600) return assetPath("assets/shaft/ShaftRock_abyss.png");
  if (depth >= 800) return assetPath("assets/shaft/ShaftRock_ruins.png");
  if (depth >= 240) return assetPath("assets/shaft/ShaftRock_crystal.png");
  return assetPath("assets/shaft/ShaftRock_entry.png");
}

export function MinePrototype() {
  /// Two segments in with `Balance.demoOreGrant` in the wallet: the state a Core save is
  /// actually in when onboarding hands over the first rock's ore and the drill becomes
  /// affordable. The old 1,840 opened on a wallet no real player has at 8m.
  const [mine, setMine] = useState<MineState>({
    depth: 8,
    recordDepth: 8,
    ore: 100,
    damage: 0,
    brokenLayers: 2,
    boreHistory: [1, 1],
  });
  const [equipment, setEquipment] = useState<EquipmentState>(initialEquipment);
  const [specializations, setSpecializations] =
    useState<Specializations>(initialSpecializations);
  const [hitPulse, setHitPulse] = useState(0);
  const [collapsePulse, setCollapsePulse] = useState(0);
  const [lastGain, setLastGain] = useState<number | null>(null);
  const [strikeVariant, setStrikeVariant] = useState<StrikeVariant>("quick");
  const [isBreaking, setIsBreaking] = useState(false);
  const [isPressing, setIsPressing] = useState(false);
  const [lastStrikeSource, setLastStrikeSource] = useState<"manual" | "auto">("auto");
  const [upgradeEvent, setUpgradeEvent] = useState<UpgradeEvent | null>(null);
  const resonance = useResonanceEvent();
  const reducedMotion = useReducedMotionPreference();
  const {
    soundEnabled,
    prime: primeMiningAudio,
    playStrike: playStrikeSound,
    playCollapse: playCollapseSound,
    toggle: toggleMiningAudio,
  } = useMiningAudio();
  const pointerRef = useRef<{
    id: number;
    x: number;
    y: number;
    cancelled: boolean;
  } | null>(null);
  const breakTimerRef = useRef<number | null>(null);
  const upgradeTimerRef = useRef<number | null>(null);
  const strikeTimersRef = useRef<Set<number>>(new Set());
  const manualStrikeCountRef = useRef(0);
  const autoStrikeCountRef = useRef(0);
  const manualStrikeGuardUntilRef = useRef(0);
  const pendingAutomaticDamageRef = useRef(0);
  const previousBrokenLayersRef = useRef(mine.brokenLayers);

  const integrity = integrityAt(mine.depth);
  const progress = Math.min(1, mine.damage / integrity);
  const resonanceMultiplier = resonance.boostActive ? RESONANCE_MULTIPLIER : 1;
  const tap = tapDamage(equipment.drill, specializations.drill === "impact")
    * resonanceMultiplier;
  const automation = automationDamagePerSecond(
    equipment.cart,
    specializations.cart === "fleet",
  ) * resonanceMultiplier;
  const chance = criticalChance(equipment.lamp, specializations.lamp === "fortune");
  const oreMultiplier = freightOreMultiplier(specializations.cart === "freight");
  const {
    cameraDepth,
    headDepth,
    headScreenOffsetPx,
  } = miningCameraPose(mine.depth, progress, METERS_PER_LAYER);
  const expectedLayerOre = layerOreAt(mine.depth, oreMultiplier);
  const remainingIntegrity = Math.max(0, integrity - mine.damage);
  const automaticBreakEta = automation > 0 ? remainingIntegrity / automation : null;
  const remainingPercent = Math.max(0, Math.round((1 - progress) * 100));
  const recommendedKind = recommendMiningUpgrade(equipment, mine.ore, mine.depth) ?? "drill";
  const recommendedUpgrade = {
    kind: recommendedKind,
    level: equipment[recommendedKind],
    cost: upgradeCost(recommendedKind, equipment[recommendedKind]),
  };
  const cartCount = cartFleetSize(equipment.cart, specializations.cart === "fleet");
  const cartLoad = cartCargoSlots(equipment.cart, specializations.cart === "freight");
  const serviceLights = serviceLampCount(
    equipment.lamp,
    specializations.lamp === "reach",
  );
  const crewCount = supportCrewSize(equipment.drill, equipment.cart, equipment.lamp);
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
      drillLevel = 1,
      payoutMultiplier = 1,
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
          const layerOre = layerOreAt(depth, payoutMultiplier);
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
    },
    [],
  );

  const queueStrike = useCallback(
    (
      rawDamage: number,
      variant: StrikeVariant,
      source: "manual" | "auto",
      drillLevel: number,
      payoutMultiplier: number,
    ) => {
      const timing = strikeTiming(variant, reducedMotion);
      setLastStrikeSource(source);
      setStrikeVariant(variant);
      setHitPulse((value) => value + 1);
      const timer = window.setTimeout(() => {
        strikeTimersRef.current.delete(timer);
        const pendingAutomaticDamage = pendingAutomaticDamageRef.current;
        pendingAutomaticDamageRef.current = 0;
        playStrikeSound(variant);
        applyDamage(rawDamage + pendingAutomaticDamage, drillLevel, payoutMultiplier);
      }, timing.contactMs);
      strikeTimersRef.current.add(timer);
    },
    [applyDamage, playStrikeSound, reducedMotion],
  );

  useEffect(() => {
    if (automation <= 0) return;
    const swing = () => {
      const automaticDamage = automation * (AUTO_STRIKE_MS / 1000);
      if (performance.now() < manualStrikeGuardUntilRef.current) {
        pendingAutomaticDamageRef.current += automaticDamage;
        return;
      }
      autoStrikeCountRef.current += 1;
      const variant: StrikeVariant = autoStrikeCountRef.current % 3 === 0 ? "heavy" : "quick";
      queueStrike(
        automaticDamage,
        variant,
        "auto",
        equipment.drill,
        oreMultiplier,
      );
    };
    swing();
    const swingTimer = window.setInterval(swing, AUTO_STRIKE_MS);
    return () => window.clearInterval(swingTimer);
  }, [applyDamage, automation, equipment.drill, oreMultiplier, queueStrike]);

  useEffect(() => {
    if (mine.brokenLayers <= previousBrokenLayersRef.current) return;
    previousBrokenLayersRef.current = mine.brokenLayers;
    setCollapsePulse((value) => value + 1);
    setIsBreaking(true);
    playCollapseSound();
    if (breakTimerRef.current !== null) window.clearTimeout(breakTimerRef.current);
    breakTimerRef.current = window.setTimeout(() => setIsBreaking(false), 560);
  }, [mine.brokenLayers, playCollapseSound]);

  useEffect(
    () => () => {
      if (breakTimerRef.current !== null) window.clearTimeout(breakTimerRef.current);
      if (upgradeTimerRef.current !== null) window.clearTimeout(upgradeTimerRef.current);
      for (const timer of strikeTimersRef.current) window.clearTimeout(timer);
      strikeTimersRef.current.clear();
    },
    [],
  );

  const strike = () => {
    const criticalEvery = Math.max(2, Math.round(1 / chance));
    manualStrikeCountRef.current += 1;
    const critical = manualStrikeCountRef.current % criticalEvery === 0;
    const variant: StrikeVariant = critical
      ? "critical"
      : manualStrikeCountRef.current % 3 === 0
        ? "heavy"
        : "quick";
    const timing = strikeTiming(variant, reducedMotion);
    manualStrikeGuardUntilRef.current = performance.now() + timing.durationMs + 80;
    primeMiningAudio();
    queueStrike(
      critical ? tap * 3 : tap,
      variant,
      "manual",
      equipment.drill,
      oreMultiplier,
    );
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

  const presentInstallation = (event: UpgradeEvent) => {
    setUpgradeEvent(event);
    if (upgradeTimerRef.current !== null) window.clearTimeout(upgradeTimerRef.current);
    upgradeTimerRef.current = window.setTimeout(() => setUpgradeEvent(null), 1800);
  };

  const upgrade = (kind: EquipmentKind) => {
    const currentLevel = equipment[kind];
    const cost = upgradeCost(kind, currentLevel);
    if (mine.ore < cost) return;
    const nextEquipment = { ...equipment, [kind]: currentLevel + 1 };
    setMine((current) => ({ ...current, ore: current.ore - cost }));
    setEquipment(nextEquipment);
    presentInstallation({
      id: `${kind}-${currentLevel + 1}`,
      kind,
      level: currentLevel + 1,
      detail: installationDetail(kind, nextEquipment, specializations),
    });
  };

  const specialize = (kind: EquipmentKind, option: string) => {
    if (specializations[kind] !== null) return;
    const cost = { drill: 460, cart: 560, lamp: 660 }[kind];
    if (mine.ore < cost) return;
    const nextSpecializations = { ...specializations, [kind]: option } as Specializations;
    setMine((current) => ({ ...current, ore: current.ore - cost }));
    setSpecializations(nextSpecializations);
    presentInstallation({
      id: `${kind}-${option}`,
      kind,
      level: equipment[kind],
      detail: specializationInstallationDetail(
        kind,
        option,
        equipment,
      ),
    });
  };

  const sceneStyle = useMemo(
    () =>
      ({
        "--break-progress": progress.toFixed(3),
        "--head-screen-offset": `${headScreenOffsetPx.toFixed(2)}px`,
        "--cut-width": `${24 + Math.min(9, equipment.drill * 0.9) + (specializations.drill === "wide" ? 8 : 0)}%`,
        "--frontier-width": `${Math.min(88, (24 + Math.min(9, equipment.drill * 0.9) + (specializations.drill === "wide" ? 8 : 0)) * 2.35)}%`,
        "--lamp-radius": `${18 + Math.min(20, equipment.lamp * 2.4) + (specializations.lamp === "reach" ? 8 : 0)}%`,
        "--rock-image": `url("${rockAssetAt(cameraDepth)}")`,
        "--rock-phase": `${-(cameraDepth * PIXELS_PER_METER)}px`,
        "--surface-y": `${16 - cameraDepth * PIXELS_PER_METER}px`,
        "--fracture-reveal": `${progress <= 0 ? 0 : 18 + progress * 142}px`,
        "--fracture-opacity": `${progress <= 0 ? 0 : 0.58 + progress * 0.42}`,
        "--kerf-depth": `${progress <= 0 ? 0 : 10 + progress * 116}px`,
        "--kerf-width": `${progress <= 0 ? 0 : 7 + progress * 29}px`,
        "--cart-duration": `${Math.max(1.9, 4.8 - equipment.cart * 0.18 - (specializations.cart === "fleet" ? 0.65 : 0))}s`,
        "--rig-scale": `${1 + (equipmentTier(equipment.drill) - 1) * 0.12}`,
        "--impact-kick": `${specializations.drill === "impact" ? 1.34 : 1}`,
      }) as CSSProperties,
    [
      equipment.drill,
      equipment.cart,
      equipment.lamp,
      cameraDepth,
      headScreenOffsetPx,
      progress,
      specializations.drill,
      specializations.cart,
      specializations.lamp,
    ],
  );

  const fractureAsset =
    progress > 0.67
      ? assetPath("assets/shaft/ShaftFractureVertical_heavy.png")
      : progress > 0.33
        ? assetPath("assets/shaft/ShaftFractureVertical_medium.png")
        : assetPath("assets/shaft/ShaftFractureVertical_light.png");

  const strikeClass = {
    quick: styles.quickStrike,
    heavy: styles.heavyStrike,
    critical: styles.criticalStrike,
  }[strikeVariant];
  const commissioningClass = upgradeEvent === null
    ? ""
    : {
        drill: styles.commissioningDrill,
        cart: styles.commissioningCart,
        lamp: styles.commissioningLamp,
      }[upgradeEvent.kind];
  const installationClass = upgradeEvent === null
    ? ""
    : {
        drill: styles.installationDrill,
        cart: styles.installationCart,
        lamp: styles.installationLamp,
      }[upgradeEvent.kind];
  const hitLabel = lastStrikeSource === "auto"
    ? strikeVariant === "heavy" ? "자동 강타" : "자동 굴착"
    : strikeVariant === "critical"
      ? `급소 −${tap * 3}`
      : strikeVariant === "heavy" ? `강타 −${tap}` : `−${tap}`;

  const depthMarks = useMemo(() => {
    const first = Math.max(0, Math.floor(cameraDepth / METERS_PER_LAYER) * METERS_PER_LAYER - 16);
    return Array.from({ length: 10 }, (_, index) => first + index * METERS_PER_LAYER);
  }, [cameraDepth]);

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
            <p className={styles.eyebrow}>DEEPMINE / PLAYABLE WEB</p>
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
              <small>{automation > 0 ? "자동 굴착 중" : "직접 타격"}</small>
            </button>
            <button
              className={styles.soundToggle}
              type="button"
              data-no-mine
              aria-label={`타격 효과음 ${soundEnabled ? "켜짐" : "꺼짐"}`}
              aria-pressed={soundEnabled}
              onClick={toggleMiningAudio}
            >
              SFX
              <small>{soundEnabled ? "켜짐" : "꺼짐"}</small>
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

          <div className={styles.shaftStage}>
            <div
              className={`${styles.shaft} ${strikeClass} ${commissioningClass} ${strikeVariant === "critical" ? styles.critical : ""} ${isBreaking ? styles.breaking : ""} ${isPressing ? styles.shaftPressed : ""} ${specializations.drill === "impact" ? styles.impactBuild : ""} ${specializations.lamp === "fortune" ? styles.fortuneBuild : ""}`}
              style={sceneStyle}
              data-strike-variant={strikeVariant}
              data-strike-source={lastStrikeSource}
              data-hit-pulse={hitPulse}
              data-sound-enabled={soundEnabled}
              data-cart-count={cartCount}
              data-cart-load={cartLoad}
              data-crew-count={crewCount}
              data-service-light-count={serviceLights}
              data-infrastructure-tier={crewCount}
              data-impact-coverage="wide"
              data-camera-depth={cameraDepth.toFixed(2)}
              data-head-screen-offset={headScreenOffsetPx.toFixed(1)}
              role="img"
              aria-label={`자동 굴착 중인 연속 갱도. 굴착 헤드 ${headDepth.toFixed(1)}미터, 다음 지층 ${Math.round(progress * 100)}퍼센트 굴착, 파쇄 보상 광석 ${formatNumber(expectedLayerOre)}, 내실 ${crewCount}단계, 작업조 ${crewCount}명, 광차 ${cartCount}대, 작업등 ${serviceLights}기`}
            >
            <div className={styles.rockWorld} aria-hidden="true" />

            <img
              className={styles.continuousSurface}
              src={assetPath("assets/shaft/ShaftSurface.png")}
              width={320}
              height={90}
              alt=""
              aria-hidden="true"
            />

            <div className={styles.openShaft} aria-hidden="true">
              <span className={styles.tunnelVoid} />
              <span className={styles.tunnelLeftEdge} />
              <span className={styles.tunnelRightEdge} />
              {equipment.cart > 1 && (
                <span className={`${styles.continuousRail} ${cartCount >= 3 ? styles.expandedRail : ""}`} />
              )}
              {Array.from({ length: cartCount }, (_, index) => (
                <span
                  className={styles.cartRun}
                  style={{
                    animationDelay: `${index * -1.3}s`,
                    "--cart-rest": `${-24 - index * 49}px`,
                    "--cart-lane": `${cartCount >= 3 ? (index % 2 === 0 ? -18 : 18) : 0}px`,
                  } as CSSProperties}
                  key={index}
                >
                  <img
                    className={`${styles.continuousCart} ${specializations.cart === "freight" ? styles.freightCart : ""} ${upgradeEvent?.kind === "cart" && index === cartCount - 1 ? styles.newestCart : ""}`}
                    src={assetPath(`assets/equipment/Equipment_cart_tier${equipmentTier(equipment.cart)}.png`)}
                    width={32}
                    height={32}
                    alt=""
                  />
                  <span className={styles.cartCargo}>
                    {Array.from({ length: cartLoad }, (_, cargoIndex) => (
                      <i key={cargoIndex} />
                    ))}
                  </span>
                </span>
              ))}
              <span className={styles.serviceCrew}>
                {Array.from({ length: crewCount }, (_, index) => (
                  <span
                    className={`${styles.crewStation} ${index % 2 === 0 ? styles.crewLeft : styles.crewRight} ${upgradeEvent !== null && index === crewCount - 1 ? styles.newestCrew : ""}`}
                    style={{ "--crew-y": `${26 + index * 48}px` } as CSSProperties}
                    key={index}
                  >
                    <i className={styles.crewDeck} />
                    <img
                      src={assetPath("assets/miner.png")}
                      width={72}
                      height={72}
                      alt=""
                    />
                    <b className={styles.supplyCrate} />
                  </span>
                ))}
              </span>
              <span className={styles.serviceLights}>
                {Array.from({ length: serviceLights }, (_, index) => (
                  <span
                    className={`${styles.serviceLamp} ${index % 2 === 0 ? styles.serviceLampLeft : styles.serviceLampRight} ${upgradeEvent?.kind === "lamp" && index === serviceLights - 1 ? styles.newestLamp : ""}`}
                    style={{ top: `${14 + index * 39}px` }}
                    key={index}
                  >
                    <i />
                    <img
                      src={assetPath(`assets/equipment/Equipment_lamp_tier${equipmentTier(equipment.lamp)}.png`)}
                      width={32}
                      height={32}
                      alt=""
                    />
                  </span>
                ))}
              </span>
            </div>

            <div className={styles.passageHistory} aria-hidden="true">
              {passageHistory.map(({ depth, drillLevel }, index) => (
                <div
                  className={styles.supportFrame}
                  style={{
                    "--history-offset": `${(depth - cameraDepth) * PIXELS_PER_METER}px`,
                    "--history-width": `${24 + Math.min(9, drillLevel * 0.9)}%`,
                  } as CSSProperties}
                  key={`${depth}-${drillLevel}`}
                >
                  <span />
                  {index < installedLampCount && (
                    <img
                      className={styles.continuousLamp}
                      src={assetPath(`assets/equipment/Equipment_lamp_tier${equipmentTier(equipment.lamp)}.png`)}
                      width={32}
                      height={32}
                      alt=""
                    />
                  )}
                  {index % 2 === 0 && (
                    <img
                      className={styles.continuousScar}
                      src={assetPath("assets/shaft/ShaftFractureVertical_light.png")}
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

            <div className={styles.operationsReadout} aria-hidden="true">
              <span>갱도 내실</span>
              <strong>{crewCount}단계</strong>
              <small>작업조 {crewCount} · 광차 {cartCount} · 조명 {serviceLights}</small>
            </div>

            <div className={styles.workLine} aria-hidden="true">
              <span className={styles.strikeArc} key={`strike-arc-${hitPulse}`} />
              <div className={styles.impactField} key={`impact-field-${hitPulse}`}>
                <span className={styles.impactWave} />
                <span className={styles.impactCrackLeft} />
                <span className={styles.impactCrackRight} />
                <i className={styles.impactDustLeft} />
                <i className={styles.impactDustRight} />
              </div>
              <img
                className={styles.frontierLip}
                src={assetPath("assets/shaft/ShaftFrontierLip.png")}
                width={320}
                height={128}
                alt=""
                key={`frontier-${hitPulse}`}
              />
              <span className={styles.excavationKerf} />
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
              <span className={styles.miningActor} key={`mining-actor-${hitPulse}`} />
              <img
                className={styles.continuousDrill}
                src={assetPath(`assets/equipment/Equipment_drill_tier${equipmentTier(equipment.drill)}.png`)}
                width={64}
                height={64}
                alt=""
              />
              <span className={styles.contactFlash} key={`contact-${hitPulse}`} />
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
                src={assetPath(strikeVariant === "critical" ? "assets/effects/WeakPoint_hit.png" : "assets/effects/WeakPoint_idle.png")}
                width={64}
                height={64}
                alt=""
              />
              <span className={styles.continuousHitLabel} key={`continuous-hit-${hitPulse}`}>
                {hitLabel}
              </span>
              <div className={styles.workRewardPromise}>
                <span>{remainingPercent}% 남음</span>
                <strong>파쇄 시 ◆{formatNumber(expectedLayerOre)}</strong>
              </div>
              {lastGain !== null && <span className={styles.continuousOreGain}>+{lastGain} 광석</span>}
            </div>

            {isBreaking && (
              <div
                className={`${styles.collapseBand} ${mine.brokenLayers % 2 === 0 ? styles.collapseAlternate : ""}`}
                aria-hidden="true"
                key={`collapse-${collapsePulse}`}
              >
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
                  style={{ top: `calc(var(--workline) + ${(depth - cameraDepth) * PIXELS_PER_METER}px)` }}
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

            {upgradeEvent !== null && (
              <span
                className={styles.constructionPulse}
                aria-hidden="true"
                key={`construction-${upgradeEvent.id}`}
              >
                <i />
                <b />
              </span>
            )}

            </div>

            {upgradeEvent !== null && (
              <div
                className={`${styles.installationToast} ${installationClass}`}
                role="status"
                aria-live="polite"
                data-no-mine
                key={upgradeEvent.id}
              >
                <img
                  src={assetPath(`assets/equipment/Equipment_${upgradeEvent.kind}_tier${equipmentTier(upgradeEvent.level)}.png`)}
                  width={32}
                  height={32}
                  alt=""
                />
                <span>설비 증설 완료</span>
                <strong>{equipmentCopy[upgradeEvent.kind].name} Lv.{upgradeEvent.level}</strong>
                <small>{upgradeEvent.detail}</small>
              </div>
            )}

            <ResonanceEvent
              phase={resonance.phase}
              position={resonance.position}
              secondsRemaining={resonance.secondsRemaining}
              boostActive={resonance.boostActive}
              boostSecondsRemaining={resonance.boostSecondsRemaining}
              announcement={resonance.announcement}
              onClaim={resonance.claim}
            />

            <aside
              className={styles.quickLoop}
              aria-label="현재 암반 보상과 추천 강화"
              data-no-mine
            >
              <div className={styles.quickReward}>
                <span>현재 암반</span>
                <strong>◆ {formatNumber(expectedLayerOre)}</strong>
                <small>
                  {automaticBreakEta === null
                    ? `${remainingPercent}% 남음`
                    : `자동 ${formatSeconds(automaticBreakEta)}`}
                </small>
              </div>
              <span className={styles.quickArrow} aria-hidden="true">→</span>
              <button
                className={styles.quickUpgrade}
                type="button"
                onClick={() => upgrade(recommendedUpgrade.kind)}
                disabled={mine.ore < recommendedUpgrade.cost}
                aria-label={`${equipmentCopy[recommendedUpgrade.kind].name} 레벨 ${recommendedUpgrade.level + 1} 바로 강화, 광석 ${recommendedUpgrade.cost}`}
              >
                <span>
                  {mine.ore >= recommendedUpgrade.cost
                    ? "지금 강화"
                    : `◆ ${formatNumber(recommendedUpgrade.cost - mine.ore)} 더 필요`}
                </span>
                <strong>
                  {equipmentCopy[recommendedUpgrade.kind].name} Lv.{recommendedUpgrade.level + 1}
                </strong>
                <small>
                  {upgradeEffect(recommendedUpgrade.kind, recommendedUpgrade.level)} · ◆{formatNumber(recommendedUpgrade.cost)}
                </small>
              </button>
            </aside>
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
            {equipmentKinds.map((kind) => {
              const level = equipment[kind];
              const cost = upgradeCost(kind, level);
              const affordable = mine.ore >= cost;
              const visualValue = upgradeEffect(kind, level);

              return (
                <article className={styles.equipmentCard} key={kind}>
                  <div className={styles.equipmentTop}>
                    <div className={styles.equipmentArt}>
                      <img
                        src={assetPath(`assets/equipment/Equipment_${kind}_tier${equipmentTier(level)}.png`)}
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
          <p>플레이어블 웹 데모 · iOS Core 경제 공식</p>
          <p>직접 타격부터 자동화·설비 분기까지 한 화면에서 플레이합니다.</p>
        </footer>
      </div>
    </main>
  );
}
