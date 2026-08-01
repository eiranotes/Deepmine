"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import type { StrikeVariant } from "./strikeFeedback";

type BrowserWindow = Window & {
  webkitAudioContext?: typeof AudioContext;
};

function pulse(
  context: AudioContext,
  start: number,
  frequency: number,
  endFrequency: number,
  duration: number,
  volume: number,
) {
  const oscillator = context.createOscillator();
  const gain = context.createGain();

  oscillator.type = "square";
  oscillator.frequency.setValueAtTime(frequency, start);
  oscillator.frequency.exponentialRampToValueAtTime(endFrequency, start + duration);
  gain.gain.setValueAtTime(0.0001, start);
  gain.gain.exponentialRampToValueAtTime(volume, start + 0.006);
  gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);

  oscillator.connect(gain);
  gain.connect(context.destination);
  oscillator.start(start);
  oscillator.stop(start + duration + 0.01);
}

export function useMiningAudio() {
  const contextRef = useRef<AudioContext | null>(null);
  const enabledRef = useRef(true);
  const [soundEnabled, setSoundEnabled] = useState(true);

  const ensureContext = useCallback(() => {
    if (!enabledRef.current) return null;
    if (contextRef.current !== null) return contextRef.current;

    const AudioContextConstructor =
      window.AudioContext ?? (window as BrowserWindow).webkitAudioContext;
    if (AudioContextConstructor === undefined) return null;

    try {
      const context = new AudioContextConstructor();
      contextRef.current = context;
      return context;
    } catch {
      return null;
    }
  }, []);

  const prime = useCallback(() => {
    const context = ensureContext();
    if (context?.state === "suspended") void context.resume();
  }, [ensureContext]);

  const playStrike = useCallback((variant: StrikeVariant) => {
    const context = contextRef.current;
    if (!enabledRef.current || context === null || context.state === "closed") return;
    const start = context.currentTime + 0.004;

    if (variant === "quick") {
      pulse(context, start, 214, 132, 0.055, 0.018);
      return;
    }

    if (variant === "heavy") {
      pulse(context, start, 142, 68, 0.09, 0.024);
      pulse(context, start + 0.018, 82, 58, 0.1, 0.012);
      return;
    }

    pulse(context, start, 286, 154, 0.075, 0.024);
    pulse(context, start + 0.045, 428, 214, 0.105, 0.018);
  }, []);

  const playCollapse = useCallback(() => {
    const context = contextRef.current;
    if (!enabledRef.current || context === null || context.state === "closed") return;
    const start = context.currentTime + 0.004;
    pulse(context, start, 92, 46, 0.14, 0.026);
    pulse(context, start + 0.075, 68, 38, 0.17, 0.018);
  }, []);

  const toggle = useCallback(() => {
    const next = !enabledRef.current;
    enabledRef.current = next;
    setSoundEnabled(next);
    if (!next) {
      if (contextRef.current?.state === "running") void contextRef.current.suspend();
      return;
    }

    const context = ensureContext();
    if (context?.state === "suspended") void context.resume();
    if (context !== null) {
      pulse(context, context.currentTime + 0.008, 260, 180, 0.06, 0.014);
    }
  }, [ensureContext]);

  useEffect(
    () => () => {
      const context = contextRef.current;
      contextRef.current = null;
      if (context !== null && context.state !== "closed") void context.close();
    },
    [],
  );

  return { soundEnabled, prime, playStrike, playCollapse, toggle };
}
