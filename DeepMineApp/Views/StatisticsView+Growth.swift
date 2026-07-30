import DeepMineCore
import SwiftUI

/// Ore per completed session over time, and the vein codex.
///
/// Weekly totals grow with both effort and power, which hides the curve. Per-session ore
/// isolates power, so this is the only place the compounding actually becomes visible.
@MainActor
extension StatisticsView {
    var growthPanel: some View {
        let growth = growthLedger
        return DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(DeepMineStrings.text(.statisticsGrowthTitle), systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .accessibilityIdentifier("statistics-growth")
                HStack(alignment: .firstTextBaseline) {
                    Text(DeepMineStrings.text(.statisticsOrePerSession))
                        .font(.subheadline)
                    Spacer(minLength: 8)
                    Text(DeepMineNumberFormatter.string(growth.currentOrePerSession))
                        .font(.title3.monospacedDigit().weight(.heavy))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier("statistics-ore-per-session")
                }
                if let multiplier = growth.multiplierSinceOldestWeek {
                    Text(String(
                        format: DeepMineStrings.text(.statisticsGrowthMultiplier),
                        multiplier.formatted(.number.precision(.fractionLength(0...1)))
                    ))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("statistics-growth-multiplier")
                } else {
                    // Saying "x1.0" from a single week of history would be a fabricated
                    // comparison, so the line is withheld instead.
                    Text(DeepMineStrings.text(.statisticsGrowthNotEnough))
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.68))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("statistics-growth-pending")
                }
                sparkline(growth)
            }
        }
    }

    private func sparkline(_ growth: GrowthLedger) -> some View {
        let peak = growth.weeks.map(\.orePerSession).max() ?? 0
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(growth.weeks, id: \.weeksAgo) { week in
                let fraction = peak > 0 ? week.orePerSession / peak : 0
                RoundedRectangle(cornerRadius: 1)
                    .fill(
                        week.completedSessions > 0
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.16)
                    )
                    .frame(height: max(2, 40 * fraction))
            }
        }
        .frame(height: 40, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(DeepMineStrings.text(.statisticsGrowthTitle))
        .accessibilityValue(DeepMineNumberFormatter.string(growth.currentOrePerSession))
        .accessibilityIdentifier("statistics-growth-sparkline")
    }

    var codexPanel: some View {
        let codex = VeinCodexEngine.summarize(player)
        return DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(DeepMineStrings.text(.statisticsCodexTitle), systemImage: "book.pages")
                        .font(.headline)
                        .accessibilityIdentifier("statistics-codex")
                    Spacer()
                    Text("\(codex.discoveredCount) / \(codex.totalCount)")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
                ForEach(codex.entries, id: \.kind) { codexRow($0) }
                Text(DeepMineStrings.text(.statisticsCodexNote))
                    .font(.caption2)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func codexRow(_ entry: VeinCodexEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: entry.isDiscovered ? "diamond.fill" : "diamond")
                .font(.caption)
                .foregroundStyle(
                    entry.isDiscovered
                        ? DeepMinePalette.brass.color
                        : DeepMinePalette.limestone.color.opacity(0.4)
                )
                .frame(width: 18)
            Text(
                entry.isDiscovered
                    ? DeepMineStrings.text(DeepMineProgressLabels.veinKey(entry.kind))
                    : DeepMineStrings.text(.statisticsCodexUndiscovered)
            )
            .font(.subheadline.weight(entry.isDiscovered ? .semibold : .regular))
            .foregroundStyle(
                entry.isDiscovered
                    ? DeepMinePalette.limestone.color
                    : DeepMinePalette.limestone.color.opacity(0.55)
            )
            Spacer(minLength: 8)
            if entry.isDiscovered {
                Text("\(entry.discoveries)")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(
            "statistics-codex-\(entry.kind.rawValue)-\(entry.isDiscovered ? "found" : "unknown")"
        )
    }
}
