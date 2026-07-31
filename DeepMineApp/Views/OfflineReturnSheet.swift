import DeepMineCore
import SwiftUI

/// Shown when the player comes back to a mine that kept working. This is the strongest
/// retention beat an idle game has, so it states what was earned plainly rather than
/// making the player infer it from a changed number.
struct OfflineReturnSheet: View {
    let settlement: OfflineSettlement
    let onCollect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(DeepMineStrings.text(.offlineTitle))
                .font(.title2.weight(.heavy))
                .foregroundStyle(DeepMinePalette.limestone.color)
                .accessibilityIdentifier("offline-title")

            Text(awayText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                .accessibilityIdentifier("offline-away")

            DeepMineRivetedPanel {
                VStack(spacing: 12) {
                    row(
                        label: DeepMineStrings.text(.offlineOre),
                        value: DeepMineNumberFormatter.string(settlement.oreGained.doubleValue),
                        identifier: "offline-ore"
                    )
                    row(
                        label: DeepMineStrings.text(.offlineSegments),
                        value: "\(settlement.segmentsBroken)",
                        identifier: "offline-segments"
                    )
                    if settlement.seamsBroken > 0 {
                        row(
                            label: DeepMineStrings.text(.mineSeam),
                            value: "\(settlement.seamsBroken)",
                            identifier: "offline-seams"
                        )
                    }
                }
            }

            if settlement.wasCapped {
                // A silent cap reads as a bug the first time someone returns after a
                // weekend and the number looks smaller than they expected.
                Text(cappedText)
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("offline-capped")
            }

            Button(action: onCollect) {
                DeepMineActionLabel(titleKey: .offlineCollect, detailKey: nil, symbol: "tray.full")
            }
            .buttonStyle(DeepMineMetalButtonStyle(role: .primary))
            .accessibilityIdentifier("offline-collect")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeepMinePalette.coal.color)
    }

    private func row(label: String, value: String, identifier: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.8))
            Spacer()
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(DeepMinePalette.brass.color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }

    private var awayText: String {
        let minutes = Int(settlement.elapsedSeconds / 60)
        guard minutes >= 60 else {
            return String(format: DeepMineStrings.text(.offlineAwayMinutes), minutes)
        }
        return String(format: DeepMineStrings.text(.offlineAwayHours), minutes / 60, minutes % 60)
    }

    private var cappedText: String {
        String(format: DeepMineStrings.text(.offlineCapped), Int(Balance.maximumOfflineHours))
    }
}
