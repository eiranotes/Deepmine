import SwiftUI

struct ProbeTelemetryPanel: View {
    let entries: [ProbeLogEntry]
    @Binding var isExpanded: Bool
    let refresh: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ProbeModule(
            stage: "네 번째 준비 · 채굴 일지",
            title: "무슨 일이 있었는지 확인해요",
            subtitle: "앞선 준비를 시험할 때 남은 최근 기록 \(entries.count)개를 모아봅니다.",
            symbol: "book.closed.fill",
            state: ProbeDisplayState(entry: entries.first)
        ) {
            Toggle(isOn: $isExpanded) {
                Label(isExpanded ? "채굴 일지 펼쳐짐" : "채굴 일지 펼치기", systemImage: "text.book.closed")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(ProbeMineToggleStyle())

            Button("새 기록 읽기", systemImage: "arrow.clockwise", action: refresh)
                .buttonStyle(ProbePressButtonStyle(role: .secondary))

            if isExpanded {
                rows.transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder private var rows: some View {
        if entries.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "ellipsis.rectangle")
                    .foregroundStyle(ProbePalette.metal)
                Text("아직 기록이 없어요. 위 준비를 하나 실행해 보세요.")
                    .font(.caption)
                    .foregroundStyle(ProbePalette.highlight)
            }
            .padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(entries.prefix(12)) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(sourceName(entry.source))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(ProbeDisplayState(entry: entry).color)
                            Spacer()
                            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(ProbePalette.metal)
                        }
                        Text(entry.message)
                            .font(.caption)
                            .foregroundStyle(ProbePalette.highlight)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .combine)
                    Divider().overlay(ProbePalette.rockMid)
                }
            }
        }
    }

    private func sourceName(_ source: String) -> String {
        switch source {
        case "LiveActivity", "LiveActivityIntent": "잠금화면 표지"
        case "AlarmKit": "종료 종"
        case "ManagedSettings", "FamilyControls", "ShieldRecovery": "갱도 문"
        case "Clock": "모래시계"
        case "SwiftData", "WidgetIntent": "보급 상자"
        default: "시스템 기록"
        }
    }
}
