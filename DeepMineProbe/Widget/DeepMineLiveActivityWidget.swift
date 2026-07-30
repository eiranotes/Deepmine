import ActivityKit
import SwiftUI
import WidgetKit

struct DeepMineLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeepMineActivityAttributes.self) { context in
            GameActivityFamilyContent(
                startedAt: context.attributes.startedAt,
                endsAt: context.attributes.endsAt,
                snapshot: context.state.snapshot,
                isStale: context.isStale
            )
            .activityBackgroundTint(ProbePalette.abyss)
            .activitySystemActionForegroundColor(ProbePalette.chalk)
        } dynamicIsland: { context in
            let snapshot = context.state.snapshot
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        SurfaceExpandedPhaseMark(
                            snapshot: snapshot,
                            isStale: context.isStale
                        )
                        SurfacePhaseLabel(snapshot: snapshot, isStale: context.isStale)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    SurfaceCompactValue(
                        startedAt: context.attributes.startedAt,
                        endsAt: context.attributes.endsAt,
                        snapshot: snapshot,
                        isStale: context.isStale
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    GameExpandedActivityContent(
                        startedAt: context.attributes.startedAt,
                        endsAt: context.attributes.endsAt,
                        snapshot: snapshot,
                        isStale: context.isStale
                    )
                }
            } compactLeading: {
                GameSurfaceMark(
                    phase: snapshot.activityPhase(isStale: context.isStale),
                    size: 22
                )
            } compactTrailing: {
                SurfaceCompactValue(
                    startedAt: context.attributes.startedAt,
                    endsAt: context.attributes.endsAt,
                    snapshot: snapshot,
                    isStale: context.isStale
                )
            } minimal: {
                GameMinimalActivityContent(snapshot: snapshot, isStale: context.isStale)
            }
            .keylineTint(
                snapshot.activityPhase(isStale: context.isStale) == .mining
                    ? ProbePalette.brass : ProbePalette.limestone
            )
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

private struct GameActivityFamilyContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    let isStale: Bool
    @Environment(\.activityFamily) private var family

    var body: some View {
        if family == .medium {
            GameStandByContent(
                startedAt: startedAt,
                endsAt: endsAt,
                snapshot: snapshot,
                isStale: isStale
            )
        } else {
            ProbeLockScreenContent(
                startedAt: startedAt,
                endsAt: endsAt,
                snapshot: snapshot,
                isStale: isStale
            )
        }
    }
}
