import AppIntents
import SwiftUI

struct SurfaceRemainingTimer: View {
    let startedAt: Date
    let endsAt: Date
    let identifier: String
    @Environment(\.locale) private var locale

    var body: some View {
        Text(timerInterval: startedAt...endsAt, countsDown: true)
            .monospacedDigit()
            .accessibilityLabel(
                GameSurfaceText.localized("surface.remainingTime", locale: locale)
            )
            .accessibilityValue(Text(timerInterval: startedAt...endsAt, countsDown: true))
            .accessibilityIdentifier(identifier)
    }
}

struct SurfaceProgressRail: View {
    let startedAt: Date
    let endsAt: Date
    let phase: GameSurfacePhase
    let identifier: String
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if phase == .mining {
                ProgressView(timerInterval: startedAt...endsAt, countsDown: false)
                    .tint(ProbePalette.brass)
            } else {
                ProgressView(value: 1)
                    .tint(phase == .collapsed ? ProbePalette.metal : ProbePalette.limestone)
            }
        }
        .labelsHidden()
        .accessibilityLabel(GameSurfaceText.localized("surface.sessionProgress", locale: locale))
        .accessibilityIdentifier(identifier)
    }
}

struct SurfaceIntentButton<Intent: AppIntent>: View {
    let title: String
    let accessibilityLabel: String
    let identifier: String
    let intent: Intent
    let isPrimary: Bool

    var body: some View {
        Button(intent: intent) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(isPrimary ? ProbePalette.coal : ProbePalette.limestone)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    isPrimary ? ProbePalette.brass : ProbePalette.shale,
                    in: RoundedRectangle(cornerRadius: 7)
                )
                .overlay {
                    if !isPrimary {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(ProbePalette.rockLight, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
