import AppIntents
import SwiftUI
import WidgetKit

struct ProbeTimelineEntry: TimelineEntry {
    let date: Date
}

struct ProbeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProbeTimelineEntry {
        ProbeTimelineEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ProbeTimelineEntry) -> Void) {
        completion(ProbeTimelineEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<ProbeTimelineEntry>) -> Void
    ) {
        completion(Timeline(entries: [ProbeTimelineEntry(date: Date())], policy: .never))
    }
}

struct ProbeCommandWidget: Widget {
    let kind = "DeepMineProbeCommandWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProbeTimelineProvider()) { _ in
            ProbeCommandWidgetView()
                .containerBackground(ProbePalette.rockDeep, for: .widget)
        }
        .configurationDisplayName("DeepMine 보급 상자")
        .description("홈 화면에서 준비 기록을 남기고 앱으로 가져옵니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct ProbeCommandWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("DEEPMINE")
                    .font(.caption.monospaced().weight(.black))
                Spacer()
                Text("준비소")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ProbePalette.brass)
            }

            HStack(spacing: 9) {
                PixelMinerIcon(size: 24, lampColor: ProbePalette.brass)
                VStack(alignment: .leading, spacing: 1) {
                    Text("보급 상자")
                        .font(.headline.weight(.bold))
                    Text("홈 화면에서 앱으로")
                        .font(.caption2)
                        .foregroundStyle(ProbePalette.highlight)
                }
            }

            if family == .systemMedium {
                Text("밖에서 남긴 기록이 광산 준비소까지 도착하는지 확인해요.")
                    .font(.caption)
                    .foregroundStyle(ProbePalette.highlight)
            }

            Spacer(minLength: 0)

            Button(intent: WriteProbeRecordIntent()) {
                Label("보급 기록 남기기", systemImage: "plus")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(ProbePalette.brass)
            .foregroundStyle(ProbePalette.coal)
        }
        .accessibilityElement(children: .contain)
    }
}
