import AppIntents
import DeepMineCore
import SwiftUI

struct GameMinimalActivityContent: View {
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    var body: some View {
        GameSurfaceMark(
            phase: snapshot.activityPhase(isStale: isStale),
            size: 20,
            planID: snapshot.planID,
            veinID: snapshot.veinID
        )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                GameSurfaceText.accessibilityLabel(snapshot, isStale: isStale, locale: locale)
            )
            .accessibilityIdentifier(
                "activity-minimal-\(snapshot.activityPhase(isStale: isStale).rawValue)"
            )
    }
}

struct GameCompactActivityContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    var isStale = false

    var body: some View {
        let phase = snapshot.activityPhase(isStale: isStale)
        HStack(spacing: 6) {
            GameSurfaceMark(
                phase: phase,
                size: 22,
                planID: snapshot.planID,
                veinID: snapshot.veinID
            )
            SurfaceCompactValue(
                startedAt: startedAt,
                endsAt: endsAt,
                snapshot: snapshot,
                isStale: isStale
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity-compact-\(phase.rawValue)")
    }
}

struct SurfacePhaseLabel: View {
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    var body: some View {
        Text(GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale))
            .font(.caption2.weight(.bold))
            .foregroundStyle(
                snapshot.activityPhase(isStale: isStale) == .mining
                    ? ProbePalette.brass : ProbePalette.limestone
            )
            .lineLimit(1)
            .accessibilityHidden(true)
    }
}

struct SurfaceExpandedPhaseMark: View {
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    var body: some View {
        let phase = snapshot.activityPhase(isStale: isStale)
        GameSurfaceMark(
            phase: phase,
            size: 24,
            planID: snapshot.planID,
            veinID: snapshot.veinID
        )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale)
            )
            .accessibilityIdentifier("activity-expanded-mark-\(phase.rawValue)")
    }
}

struct SurfaceCompactValue: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    var body: some View {
        let phase = snapshot.activityPhase(isStale: isStale)
        Group {
            if phase == .mining {
                SurfaceRemainingTimer(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    identifier: "activity-compact-timer"
                )
            } else {
                Text(GameSurfaceText.compactStatus(snapshot, isStale: isStale, locale: locale))
                    .accessibilityLabel(
                        GameSurfaceText.accessibilityLabel(
                            snapshot,
                            isStale: isStale,
                            locale: locale
                        )
                    )
                    .accessibilityValue(
                        GameSurfaceText.compactStatus(
                            snapshot,
                            isStale: isStale,
                            locale: locale
                        )
                    )
                    .accessibilityIdentifier("activity-compact-status-\(phase.rawValue)")
            }
        }
        .font(.caption2.weight(.bold))
        .lineLimit(1)
        .minimumScaleFactor(0.68)
        .frame(maxWidth: 62)
    }
}

struct GameExpandedActivityContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    var isStale = false
    @Environment(\.locale) private var locale

    private var phase: GameSurfacePhase { snapshot.activityPhase(isStale: isStale) }

    var body: some View {
        ZStack {
            Image(GameArtName.region(snapshot.regionID, prefix: "DIBanner"))
                .resizable()
                .interpolation(.none)
                .antialiased(false)
                .scaledToFill()
                .opacity(0.42)
                .accessibilityHidden(true)
            ProbePalette.coal.opacity(0.42)
            VStack(spacing: 7) {
                HStack {
                    Text(GameSurfaceText.plan(snapshot.planID, locale: locale))
                    Spacer()
                    Text("\(snapshot.depthMeters)m")
                    if phase == .mining {
                        SurfaceRemainingTimer(
                            startedAt: startedAt,
                            endsAt: endsAt,
                            identifier: "activity-expanded-timer"
                        )
                    }
                }
                .font(.caption.weight(.bold))
                SurfaceProgressRail(
                    startedAt: startedAt,
                    endsAt: endsAt,
                    phase: phase,
                    identifier: "activity-expanded-progress"
                )
                valueRow
                actionRow
            }
        }
        .clipped()
        .frame(maxHeight: GameActivityLayout.expandedMaximumHeight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("activity-expanded-\(phase.rawValue)")
    }

    private var valueRow: some View {
        HStack {
            switch phase {
            case .mining:
                Text(
                    "\(GameSurfaceText.localized("game.expectedReward", locale: locale)) "
                        + GameSurfaceText.number(snapshot.expectedOre, locale: locale)
                )
                Spacer()
                Text("×\(snapshot.streakDays)")
            case .waiting:
                Text(GameSurfaceText.phase(snapshot, isStale: isStale, locale: locale))
                Spacer()
                Text(GameSurfaceText.region(snapshot.regionID, locale: locale))
            case .completed, .vein, .collapsed:
                Text(
                    "\(GameSurfaceText.localized("surface.earnedOre", locale: locale)) "
                        + GameSurfaceText.number(snapshot.earnedOre, locale: locale)
                )
                Spacer()
                Text(
                    GameSurfaceText.vein(snapshot.veinID, locale: locale)
                        ?? GameSurfaceText.grade(snapshot.verificationGradeID, locale: locale)
                )
            }
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(ProbePalette.highlight)
    }

    @ViewBuilder
    private var actionRow: some View {
        switch phase {
        case .mining:
            HStack(spacing: 8) {
                actionButton(
                    GameSurfaceText.localized("action.abandon", locale: locale),
                    accessibilityLabel: GameSurfaceText.localized(
                        "surface.action.abandonAccessibility", locale: locale
                    ),
                    identifier: "activity-abandon",
                    intent: AbandonSessionIntent(),
                    isPrimary: false
                )
                actionButton(
                    GameSurfaceText.localized("action.openApp", locale: locale),
                    identifier: "activity-open",
                    intent: OpenGameIntent(),
                    isPrimary: true
                )
            }
        case .completed, .vein:
            terminalActions
        case .waiting, .collapsed:
            actionButton(
                GameSurfaceText.localized("action.openApp", locale: locale),
                identifier: "activity-open",
                intent: OpenGameIntent(),
                isPrimary: true
            )
        }
    }

    private var terminalActions: some View {
        HStack(spacing: 5) {
            if let recommendation = snapshot.upgradeRecommendation {
                actionButton(
                    "\(GameSurfaceText.equipment(recommendation.equipmentID, locale: locale)) "
                        + "\(recommendation.nextLevel)",
                    accessibilityLabel: GameSurfaceText.recommendationAccessibilityLabel(
                        recommendation,
                        locale: locale
                    ),
                    identifier: "activity-upgrade-recommendation",
                    intent: AcceptUpgradeIntent(equipmentID: recommendation.equipmentID),
                    isPrimary: true
                )
            } else {
                actionButton(
                    GameSurfaceText.localized("action.openApp", locale: locale),
                    identifier: "activity-open",
                    intent: OpenGameIntent(),
                    isPrimary: true
                )
            }
            startButton(length: .minutes25)
            startButton(length: .minutes50)
        }
    }

    private func startButton(length: SessionLength) -> some View {
        actionButton(
            GameSurfaceText.durationShort(length.minutes, locale: locale),
            accessibilityLabel: GameSurfaceText.startAccessibilityLabel(
                minutes: length.minutes,
                planID: snapshot.planID,
                locale: locale
            ),
            identifier: "activity-start-\(length.minutes)",
            intent: StartSessionIntent(length: length, planID: snapshot.planID),
            isPrimary: false
        )
    }

    private func actionButton<Intent: AppIntent>(
        _ title: String,
        accessibilityLabel: String? = nil,
        identifier: String,
        intent: Intent,
        isPrimary: Bool
    ) -> some View {
        SurfaceIntentButton(
            title: title,
            accessibilityLabel: accessibilityLabel ?? title,
            identifier: identifier,
            intent: intent,
            isPrimary: isPrimary
        )
    }
}
