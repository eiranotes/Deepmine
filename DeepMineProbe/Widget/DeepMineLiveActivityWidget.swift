import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct DeepMineLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeepMineActivityAttributes.self) { context in
            ProbeLockScreenContent(
                startedAt: context.attributes.startedAt,
                endsAt: context.attributes.endsAt,
                isStale: context.isStale,
                expectedReward: context.state.expectedReward,
                depth: context.state.depth,
                streakDays: context.state.streakDays
            )
                .activityBackgroundTint(ProbePalette.abyss)
                .activitySystemActionForegroundColor(ProbePalette.chalk)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        PixelMinerIcon(
                            size: 18,
                            lampColor: context.isStale ? ProbePalette.limestone : ProbePalette.brass
                        )
                        Text(context.isStale ? "귀환 완료" : "시험 채굴")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(context.isStale ? ProbePalette.limestone : ProbePalette.brass)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.isStale {
                        Text("완료")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ProbePalette.limestone)
                    } else {
                        Text(
                            timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                            countsDown: true
                        )
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(width: 46, alignment: .trailing)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(
                            timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                            countsDown: false
                        )
                        .tint(context.isStale ? ProbePalette.limestone : ProbePalette.brass)
                        .labelsHidden()

                        HStack {
                            Text("깊이 \(context.state.depth)m")
                            Spacer()
                            Text("광석 \(context.state.expectedReward)")
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ProbePalette.highlight)

                        HStack(spacing: 8) {
                            Button(intent: RestartProbeIntent()) {
                                Label("다시 시험", systemImage: "arrow.clockwise")
                                    .foregroundStyle(ProbePalette.coal)
                                    .frame(maxWidth: .infinity, minHeight: 30)
                                    .background(ProbePalette.brass, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            Button(intent: WriteProbeRecordIntent()) {
                                Label("보급 기록", systemImage: "externaldrive.badge.plus")
                                    .foregroundStyle(ProbePalette.limestone)
                                    .frame(maxWidth: .infinity, minHeight: 30)
                                    .background(ProbePalette.shale, in: Capsule())
                                    .overlay {
                                        Capsule().stroke(ProbePalette.rockLight, lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.caption2.weight(.bold))
                    }
                }
            } compactLeading: {
                PixelMinerIcon(
                    lampColor: context.isStale ? ProbePalette.limestone : ProbePalette.brass
                )
            } compactTrailing: {
                if context.isStale {
                    Text("완료")
                        .font(.caption2.weight(.bold))
                } else {
                    Text(
                        timerInterval: context.attributes.startedAt...context.attributes.endsAt,
                        countsDown: true
                    )
                    .font(.caption2.monospacedDigit())
                    .frame(maxWidth: 52)
                }
            } minimal: {
                PixelMinerIcon(
                    lampColor: context.isStale ? ProbePalette.limestone : ProbePalette.brass
                )
            }
            .keylineTint(context.isStale ? ProbePalette.limestone : ProbePalette.brass)
        }
    }
}
