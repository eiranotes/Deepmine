export type StrikeVariant = "quick" | "heavy" | "critical";

export const STRIKE_TIMINGS: Record<
  StrikeVariant,
  { durationMs: number; contactMs: number }
> = {
  quick: { durationMs: 560, contactMs: 202 },
  heavy: { durationMs: 690, contactMs: 249 },
  critical: { durationMs: 760, contactMs: 274 },
};

export const REDUCED_STRIKE_TIMING = {
  durationMs: 160,
  contactMs: 80,
};

export function strikeTiming(variant: StrikeVariant, reducedMotion: boolean) {
  return reducedMotion ? REDUCED_STRIKE_TIMING : STRIKE_TIMINGS[variant];
}
