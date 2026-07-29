import SwiftUI

struct ProbeLockScreenContent: View {
    let startedAt: Date
    let endsAt: Date
    let isStale: Bool
    let expectedReward: Int
    let depth: Int
    let streakDays: Int

    var body: some View {
        HStack(spacing: 12) {
            PixelMinerIcon(
                size: 24,
                lampColor: isStale ? ProbePalette.limestone : ProbePalette.brass
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DEEPMINE · 출정 훈련")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ProbePalette.highlight)
                        Text(isStale ? "준비 완료" : "60초 시험 채굴")
                            .font(.subheadline.weight(.bold))
                    }
                    Spacer()
                    if isStale {
                        Text("귀환")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ProbePalette.limestone)
                    } else {
                        Text(timerInterval: startedAt...endsAt, countsDown: true)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                    }
                }

                ProgressView(timerInterval: startedAt...endsAt, countsDown: false)
                    .tint(isStale ? ProbePalette.limestone : ProbePalette.brass)
                    .labelsHidden()

                HStack {
                    Text("깊이 \(depth)m")
                    Spacer()
                    Text("예상 광석 \(expectedReward)")
                    Spacer()
                    Text("연속 \(streakDays)일")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(ProbePalette.highlight)
            }
        }
        .padding(14)
        .frame(maxHeight: 160)
        .accessibilityElement(children: .combine)
    }
}

struct ProbeLockScreenPreview: View {
    var body: some View {
        ProbeLockScreenContent(
            startedAt: Date().addingTimeInterval(-15),
            endsAt: Date().addingTimeInterval(45),
            isStale: false,
            expectedReward: 100,
            depth: 148,
            streakDays: 7
        )
        .frame(maxWidth: .infinity)
        .background(ProbePalette.coal, in: RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(ProbePalette.rockLight, lineWidth: 1)
        }
    }
}
