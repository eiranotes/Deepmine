"use client";

import { useCallback, useEffect, useRef, useState } from "react";

export type ResonancePhase = "waiting" | "active" | "claimed" | "missed";
export type ResonancePosition = "left" | "right";

export const RESONANCE_MULTIPLIER = 2;

const FIRST_RESONANCE_DELAY_MS = 5_200;
const RESONANCE_MIN_DELAY_MS = 120_000;
const RESONANCE_MAX_DELAY_MS = 300_000;
const RESONANCE_ACTIVE_MS = 12_000;
const RESONANCE_BOOST_MS = 18_000;
const RESONANCE_SETTLE_MS = 1_500;

function nextResonanceDelay() {
  return RESONANCE_MIN_DELAY_MS
    + Math.floor(Math.random() * (RESONANCE_MAX_DELAY_MS - RESONANCE_MIN_DELAY_MS + 1));
}

export function useResonanceEvent() {
  const [phase, setPhase] = useState<ResonancePhase>("waiting");
  const [cycle, setCycle] = useState(0);
  const [secondsRemaining, setSecondsRemaining] = useState(0);
  const [boostActive, setBoostActive] = useState(false);
  const [boostSecondsRemaining, setBoostSecondsRemaining] = useState(0);
  const [pageVisible, setPageVisible] = useState(true);
  const [announcement, setAnnouncement] = useState("공명 탐지기가 신호를 추적하고 있습니다.");
  const activeUntilRef = useRef(0);
  const boostUntilRef = useRef(0);

  useEffect(() => {
    const handleVisibilityChange = () => {
      const visible = document.visibilityState === "visible";
      setPageVisible(visible);
      if (!visible && phase === "active") {
        setSecondsRemaining(0);
        setAnnouncement("화면을 벗어나 공명 신호 추적을 일시정지했습니다.");
        setPhase("waiting");
      }
    };
    handleVisibilityChange();
    document.addEventListener("visibilitychange", handleVisibilityChange);
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange);
  }, [phase]);

  useEffect(() => {
    if (phase !== "waiting" || !pageVisible) return;
    const delay = cycle === 0 ? FIRST_RESONANCE_DELAY_MS : nextResonanceDelay();
    const timer = window.setTimeout(() => {
      activeUntilRef.current = Date.now() + RESONANCE_ACTIVE_MS;
      setSecondsRemaining(Math.ceil(RESONANCE_ACTIVE_MS / 1000));
      setAnnouncement("공명 결절이 출현했습니다. 12초 안에 결절을 누르세요.");
      setPhase("active");
    }, delay);
    return () => window.clearTimeout(timer);
  }, [cycle, pageVisible, phase]);

  useEffect(() => {
    if (phase !== "active") return;
    const updateCountdown = () => {
      setSecondsRemaining(Math.max(0, Math.ceil((activeUntilRef.current - Date.now()) / 1000)));
    };
    updateCountdown();
    const countdown = window.setInterval(updateCountdown, 200);
    const expiry = window.setTimeout(() => {
      setSecondsRemaining(0);
      setAnnouncement("공명 결절을 놓쳤습니다. 보상 없이 신호가 사라졌습니다.");
      setPhase("missed");
    }, Math.max(0, activeUntilRef.current - Date.now()));
    return () => {
      window.clearInterval(countdown);
      window.clearTimeout(expiry);
    };
  }, [phase]);

  useEffect(() => {
    if (phase !== "claimed" && phase !== "missed") return;
    const timer = window.setTimeout(() => {
      setCycle((current) => current + 1);
      setPhase("waiting");
    }, RESONANCE_SETTLE_MS);
    return () => window.clearTimeout(timer);
  }, [phase]);

  useEffect(() => {
    if (!boostActive) return;
    const updateBoost = () => {
      const remaining = Math.max(0, Math.ceil((boostUntilRef.current - Date.now()) / 1000));
      setBoostSecondsRemaining(remaining);
      if (remaining === 0) {
        setBoostActive(false);
        setAnnouncement("공명 과충전이 끝났습니다. 기본 채굴 출력으로 돌아갑니다.");
      }
    };
    updateBoost();
    const countdown = window.setInterval(updateBoost, 250);
    return () => window.clearInterval(countdown);
  }, [boostActive]);

  const claim = useCallback(() => {
    if (phase !== "active") return;
    boostUntilRef.current = Date.now() + RESONANCE_BOOST_MS;
    setBoostSecondsRemaining(Math.ceil(RESONANCE_BOOST_MS / 1000));
    setBoostActive(true);
    setAnnouncement("공명 결절을 회수했습니다. 18초 동안 수동과 자동 채굴 출력이 2배입니다.");
    setPhase("claimed");
  }, [phase]);

  return {
    phase,
    position: (cycle % 2 === 0 ? "right" : "left") as ResonancePosition,
    secondsRemaining,
    boostActive,
    boostSecondsRemaining,
    announcement,
    claim,
  };
}
