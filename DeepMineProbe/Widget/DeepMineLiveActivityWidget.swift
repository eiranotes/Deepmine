import ActivityKit
import AlarmKit
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
            return gameDynamicIsland(
                startedAt: context.attributes.startedAt,
                endsAt: context.attributes.endsAt,
                snapshot: snapshot,
                isStale: context.isStale
            )
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

struct DeepMineAlarmLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<DeepMineAlarmMetadata>.self) { context in
            let projection = DeepMineAlarmActivityProjection(
                metadata: context.attributes.metadata,
                state: context.state
            )
            GameActivityFamilyContent(
                startedAt: projection.startedAt,
                endsAt: projection.endsAt,
                snapshot: projection.snapshot,
                isStale: projection.isStale
            )
            .activityBackgroundTint(ProbePalette.abyss)
            .activitySystemActionForegroundColor(ProbePalette.chalk)
        } dynamicIsland: { context in
            let projection = DeepMineAlarmActivityProjection(
                metadata: context.attributes.metadata,
                state: context.state
            )
            return gameDynamicIsland(
                startedAt: projection.startedAt,
                endsAt: projection.endsAt,
                snapshot: projection.snapshot,
                isStale: projection.isStale
            )
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

private func gameDynamicIsland(
    startedAt: Date,
    endsAt: Date,
    snapshot: GameSurfaceSnapshot,
    isStale: Bool
) -> DynamicIsland {
    DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
            HStack(spacing: 6) {
                SurfaceExpandedPhaseMark(snapshot: snapshot, isStale: isStale)
                SurfacePhaseLabel(snapshot: snapshot, isStale: isStale)
            }
        }
        DynamicIslandExpandedRegion(.trailing) {
            SurfaceCompactValue(
                startedAt: startedAt,
                endsAt: endsAt,
                snapshot: snapshot,
                isStale: isStale
            )
        }
        DynamicIslandExpandedRegion(.bottom) {
            GameExpandedActivityContent(
                startedAt: startedAt,
                endsAt: endsAt,
                snapshot: snapshot,
                isStale: isStale
            )
        }
    } compactLeading: {
        GameSurfaceMark(
            phase: snapshot.activityPhase(isStale: isStale),
            size: 22,
            planID: snapshot.planID,
            veinID: snapshot.veinID
        )
    } compactTrailing: {
        SurfaceCompactValue(
            startedAt: startedAt,
            endsAt: endsAt,
            snapshot: snapshot,
            isStale: isStale
        )
    } minimal: {
        GameMinimalActivityContent(snapshot: snapshot, isStale: isStale)
    }
    .keylineTint(
        snapshot.activityPhase(isStale: isStale) == .mining
            ? ProbePalette.brass : ProbePalette.limestone
    )
}

private struct GameActivityFamilyContent: View {
    let startedAt: Date
    let endsAt: Date
    let snapshot: GameSurfaceSnapshot
    let isStale: Bool

    var body: some View {
        ProbeLockScreenContent(
            startedAt: startedAt,
            endsAt: endsAt,
            snapshot: snapshot,
            isStale: isStale
        )
    }
}
