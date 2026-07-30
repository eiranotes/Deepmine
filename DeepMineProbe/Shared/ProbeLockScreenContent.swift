import SwiftUI

enum GameActivityLayout {
    static let expandedMaximumHeight: CGFloat = 144
    static let lockScreenMaximumHeight: CGFloat = 160
}

struct ProbeLockScreenContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    private var phase: GameSurfacePhase { snapshot.activityPhase(isStale: isStale) }

    var body: some View {
        HStack(spacing: 12) {
            GameSurfaceMark(phase: phase, size: 28)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale))
                            .font(.subheadline.weight(.bold))
                        Text(
                            "\(GameSurfaceText.plan(snapshot.planID, locale: locale)) · "
                                + GameSurfaceText.region(snapshot.regionID, locale: locale)
                        )
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ProbePalette.highlight)
                    }
                    Spacer()
                    if phase == .mining {
                        SurfaceRemainingTimer(
                            startedAt: startedAt,
                            endsAt: endsAt,
                            identifier: "activity-lock-timer"
                        )
                            .font(.subheadline.monospacedDigit().weight(.bold))
                    } else {
                        Text(GameSurfaceText.grade(snapshot.verificationGradeID, locale: locale))
                            .font(.caption.weight(.bold))
                    }
                }
                SurfaceProgressRail(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    phase: phase,
                    identifier: "activity-lock-progress"
                )
                metricRow
            }
        }
        .padding(14)
        .frame(maxHeight: GameActivityLayout.lockScreenMaximumHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            GameSurfaceText.accessibilityLabel(snapshot, isStale: isStale, locale: locale)
        )
        .accessibilityIdentifier("activity-lock-\(phase.rawValue)")
    }

    private var metricRow: some View {
        HStack(spacing: 8) {
            Text("\(snapshot.depthMeters)m")
            Spacer()
            if phase == .mining {
                Text(
                    "\(GameSurfaceText.localized("game.expectedReward", locale: locale)) "
                        + GameSurfaceText.number(snapshot.expectedOre, locale: locale)
                )
            } else if phase == .completed || phase == .vein || phase == .collapsed {
                Text(
                    "\(GameSurfaceText.localized("surface.earnedOre", locale: locale)) "
                        + GameSurfaceText.number(snapshot.earnedOre, locale: locale)
                )
                if let vein = GameSurfaceText.vein(snapshot.veinID, locale: locale) {
                    Text(vein).lineLimit(1)
                }
            } else {
                Text(GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale))
            }
            Spacer()
            Text("×\(snapshot.streakDays)")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(ProbePalette.highlight)
    }
}

struct GameStandByContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    private var phase: GameSurfacePhase { snapshot.activityPhase(isStale: isStale) }

    var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(maxWidth: .infinity)
            GameSurfaceMark(phase: phase, size: 72)
                .frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 10) {
                standbyTitle
                if phase == .mining {
                    SurfaceRemainingTimer(
                        startedAt: startedAt,
                        endsAt: endsAt,
                        identifier: "activity-standby-timer"
                    )
                        .font(.largeTitle.monospacedDigit().weight(.black))
                    SurfaceProgressRail(
                        startedAt: startedAt,
                        endsAt: endsAt,
                        phase: phase,
                        identifier: "activity-standby-progress"
                    )
                } else if phase == .completed || phase == .vein || phase == .collapsed {
                    Text(GameSurfaceText.number(snapshot.earnedOre, locale: locale))
                        .font(.largeTitle.monospacedDigit().weight(.black))
                    Text(GameSurfaceText.grade(snapshot.verificationGradeID, locale: locale))
                        .font(.headline.weight(.bold))
                }
                Text(
                    "\(GameSurfaceText.plan(snapshot.planID, locale: locale)) · "
                        + GameSurfaceText.region(snapshot.regionID, locale: locale)
                )
                .font(.headline)
                .foregroundStyle(ProbePalette.highlight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            GameSurfaceText.accessibilityLabel(snapshot, isStale: isStale, locale: locale)
        )
        .accessibilityIdentifier("activity-standby-\(phase.rawValue)")
    }

    @ViewBuilder
    private var standbyTitle: some View {
        if phase == .vein,
           let veinName = GameSurfaceText.vein(snapshot.veinID, locale: locale) {
            VStack(alignment: .leading, spacing: 0) {
                Text(veinName)
                Text(GameSurfaceText.localized("surface.found", locale: locale))
            }
            .font(.title2.weight(.black))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("activity-standby-vein-name")
        } else {
            Text(GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale))
                .font(.title2.weight(.black))
        }
    }
}
