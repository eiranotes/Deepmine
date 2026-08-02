import DeepMineCore
import SwiftUI

struct ShaftHUDView: View {
    let player: PlayerState
    let power: StrikePower

    var body: some View {
        VStack(spacing: 9) {
            header
            integrityRail
            impactRail
            statusLine
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(DeepMineStrings.text(.gameDepth)) \(player.depthMeters)m")
                    .font(.headline.monospacedDigit())
                    .accessibilityIdentifier("mine-depth")
                if player.recordDepthMeters > player.depthMeters {
                    Text("\(DeepMineStrings.text(.shaftRecordDepth)) \(player.recordDepthMeters)m")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                        .accessibilityIdentifier("mine-record-depth")
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(String(
                    format: DeepMineStrings.text(.shaftTapDamage),
                    DeepMineNumberFormatter.string(big: power.tapDamage)
                ))
                Text(String(
                    format: DeepMineStrings.text(.shaftAutomationDamage),
                    power.isAutomated
                        ? DeepMineNumberFormatter.string(big: power.damagePerSecond)
                        : "—"
                ))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
            .accessibilityIdentifier("mine-power-rates")
        }
    }

    private var integrityRail: some View {
        DeepMineProgressRail(
            value: player.mineFace.brokenFraction,
            total: 1,
            accessibilityLabel: DeepMineStrings.text(.mineIntegrity)
        )
        .accessibilityIdentifier("mine-integrity")
    }

    private var impactRail: some View {
        HStack(spacing: 8) {
            Text(DeepMineStrings.text(.shaftImpact))
                .font(.caption2.weight(.bold))
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
            DeepMineProgressRail(
                value: player.mineFace.impact.fraction,
                total: 1,
                accessibilityLabel: DeepMineStrings.text(.shaftImpact)
            )
            Text("×\(player.mineFace.impact.damageMultiplier, specifier: "%.1f")")
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(DeepMinePalette.brass.color)
                .frame(width: 34, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("mine-impact")
    }

    private var statusLine: some View {
        HStack {
            if player.mineFace.segment.isSeam {
                Label(DeepMineStrings.text(.mineSeam), systemImage: "sparkles")
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("mine-seam")
            } else {
                Text(String(
                    format: DeepMineStrings.text(.shaftNextSeam),
                    layersUntilSeam
                ))
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.62))
                .accessibilityIdentifier("mine-next-seam")
            }
            Spacer()
            Text("\(Int((player.mineFace.brokenFraction * 100).rounded()))%")
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
        }
        .font(.caption2.monospacedDigit())
    }

    private var layersUntilSeam: Int {
        let remainder = player.mineFace.segmentIndex % Balance.seamSegmentInterval
        return Balance.seamSegmentInterval - remainder
    }
}
