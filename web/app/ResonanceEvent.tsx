"use client";

/* eslint-disable @next/next/no-img-element */
import type { ResonancePhase, ResonancePosition } from "./useResonanceEvent";
import styles from "./mine.module.css";

type ResonanceEventProps = {
  phase: ResonancePhase;
  position: ResonancePosition;
  secondsRemaining: number;
  boostActive: boolean;
  boostSecondsRemaining: number;
  announcement: string;
  onClaim: () => void;
};

export function ResonanceEvent({
  phase,
  position,
  secondsRemaining,
  boostActive,
  boostSecondsRemaining,
  announcement,
  onClaim,
}: ResonanceEventProps) {
  const resolvedClass = phase === "claimed" ? styles.resonanceClaimed : styles.resonanceMissed;

  return (
    <div className={styles.resonanceLayer}>
      {phase === "active" && (
        <button
          className={`${styles.resonanceNode} ${position === "left" ? styles.resonanceLeft : styles.resonanceRight}`}
          type="button"
          onClick={onClaim}
          data-no-mine
          data-testid="resonance-node"
          aria-label="공명 결절 회수, 18초 동안 채굴 출력 2배"
        >
          <span className={styles.resonanceUrgency}>한정 신호</span>
          <span className={styles.resonanceOrbit} aria-hidden="true" />
          <img
            src="/assets/events/ResonanceNode.png"
            width={96}
            height={96}
            alt=""
            aria-hidden="true"
          />
          <strong>공명 결절</strong>
          <small>{secondsRemaining}초 · 출력 ×2</small>
        </button>
      )}

      {(phase === "claimed" || phase === "missed") && (
        <div
          className={`${styles.resonanceOutcome} ${resolvedClass} ${position === "left" ? styles.resonanceLeft : styles.resonanceRight}`}
          data-no-mine
          role="status"
        >
          <strong>{phase === "claimed" ? "공명 회수" : "신호 소실"}</strong>
          <small>{phase === "claimed" ? "채굴 출력 ×2" : "보상 없음"}</small>
        </div>
      )}

      {boostActive && (
        <div
          className={styles.resonanceBoost}
          data-no-mine
          role="status"
          aria-label={`공명 과충전, 채굴 출력 2배, ${boostSecondsRemaining}초 남음`}
        >
          <span>공명 과충전</span>
          <strong>×2</strong>
          <small>{boostSecondsRemaining}초</small>
        </div>
      )}

      <p className={styles.visuallyHidden} aria-live="assertive" aria-atomic="true">
        {announcement}
      </p>
    </div>
  );
}
