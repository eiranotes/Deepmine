import SwiftUI

struct ReturnReportRecoveryView: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            DeepMinePalette.coal.color.ignoresSafeArea()
            VStack(spacing: 17) {
                ContentUnavailableView(
                    DeepMineStrings.text(.returnLoadFailedTitle),
                    systemImage: "exclamationmark.triangle",
                    description: Text(DeepMineStrings.text(.returnLoadFailedBody))
                )
                Button(action: onFinish) {
                    DeepMineActionLabel(
                        titleKey: .actionFinish,
                        detailKey: nil,
                        symbol: "arrow.left"
                    )
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
            }
            .padding(17)
        }
        .foregroundStyle(DeepMinePalette.limestone.color)
        .accessibilityIdentifier("return-report-recovery")
    }
}
