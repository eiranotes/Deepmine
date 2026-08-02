import DeepMineCore
import SwiftUI

@MainActor
struct StatisticsView: View {
    let gameStore: GameStore?
    let player: PlayerState
    let referenceDate: Date
    let calendar: Calendar
    let timeZone: TimeZone

    var growthLedger: GrowthLedger {
        GrowthLedgerEngine.summarize(
            player,
            referenceDate: referenceDate,
            calendar: calendar,
            timeZone: timeZone
        )
    }
    private var power: StrikePower { MiningLoop.power(for: player) }
    @State var ledger: MineLedger?
    @State var loadFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                if loadFailed { recoveryPanel }
                if let ledger, !loadFailed {
                    liveMineGauges
                    if ledger.recordedRuns == 0 { zeroPanel }
                    sessionGauges(ledger)
                    growthPanel
                    codexPanel
                    planMix(ledger)
                    veinHistory(ledger)
                }
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationStatistics))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("statistics-screen")
        .task { load() }
    }

    private var liveMineGauges: some View {
        DeepMineRivetedPanel {
            VStack(spacing: 0) {
                Label(DeepMineStrings.text(.homeMineScene), systemImage: "hammer.fill")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                statRow(
                    title: .gameDepth,
                    value: "\(player.depthMeters)m",
                    symbol: "arrow.down.to.line.compact",
                    identifier: "statistics-current-depth"
                )
                divider
                statRow(
                    title: .prestigeSegments,
                    value: "\(player.mineFace.lifetimeSegmentsBroken)",
                    symbol: "square.stack.3d.down.right.fill",
                    identifier: "statistics-rocks-broken"
                )
                divider
                statRow(
                    title: .gameOre,
                    value: DeepMineNumberFormatter.string(big: player.resources.ore),
                    symbol: "shippingbox.fill",
                    identifier: "statistics-wallet"
                )
                divider
                statRow(
                    title: .gameCart,
                    value: power.isAutomated
                        ? "\(DeepMineNumberFormatter.string(big: power.damagePerSecond))/s"
                        : "0/s",
                    symbol: "gearshape.2.fill",
                    identifier: "statistics-automation-output"
                )
            }
        }
        .accessibilityIdentifier("statistics-live-mine")
    }

    private var zeroPanel: some View {
        DeepMineRivetedPanel {
            Label(DeepMineStrings.text(.statisticsEmpty), systemImage: "timer")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityIdentifier("statistics-zero")
    }

    private func sessionGauges(_ ledger: MineLedger) -> some View {
        DeepMineRivetedPanel {
            VStack(spacing: 0) {
                Text(DeepMineStrings.text(.homeFocusAmplifierTitle))
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                statRow(
                    title: .gameCompletions,
                    value: "\(ledger.completedRuns) / \(ledger.recordedRuns)",
                    symbol: "checkmark.seal.fill",
                    identifier: "statistics-total-sessions"
                )
                divider
                statRow(
                    title: .gameDeepestReturn,
                    value: "\(DeepMineNumberFormatter.string(Double(ledger.deepestReturnMeters)))m",
                    symbol: "arrow.down.to.line",
                    identifier: "statistics-depth"
                )
                divider
                statRow(
                    title: .statisticsOreEarned,
                    value: DeepMineNumberFormatter.string(ledger.oreEarned),
                    symbol: "shippingbox.fill",
                    identifier: "statistics-ore"
                )
            }
        }
    }

    private func statRow(
        title: DeepMineStringKey,
        value: String,
        symbol: String,
        identifier: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(DeepMinePalette.brass.color)
                .frame(width: 28)
            Text(DeepMineStrings.text(title))
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 8)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.heavy))
                .foregroundStyle(DeepMinePalette.brass.color)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(DeepMineStrings.text(title)) \(value)")
        .accessibilityIdentifier(identifier)
    }

    private var divider: some View {
        Divider().overlay(DeepMinePalette.limestone.color.opacity(0.22))
    }

    private func planMix(_ ledger: MineLedger) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(DeepMineStrings.text(.gamePlanMix), systemImage: "signpost.right.and.left")
                    .font(.headline)
                    .accessibilityIdentifier("statistics-plan-mix")
                ForEach(ledger.planMix, id: \.plan) { item in
                    HStack {
                        Text(DeepMineStrings.text(DeepMineProgressLabels.planKey(item.plan)))
                            .font(.subheadline)
                        Spacer()
                        Text("\(item.count)")
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .foregroundStyle(DeepMinePalette.brass.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("statistics-plan-\(item.plan.rawValue)")
                    DeepMineProgressRail(
                        value: Double(item.count),
                        total: Double(max(1, ledger.recordedRuns)),
                        accessibilityLabel: DeepMineStrings.text(
                            DeepMineProgressLabels.planKey(item.plan)
                        )
                    )
                }
            }
        }
    }

    private func veinHistory(_ ledger: MineLedger) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                Label(DeepMineStrings.text(.gameVeinHistory), systemImage: "sparkles")
                    .font(.headline)
                    .accessibilityIdentifier("statistics-vein-history")
                if ledger.veinHistory.isEmpty {
                    Text(DeepMineStrings.text(.gameNoVein))
                        .font(.subheadline)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                } else {
                    ForEach(ledger.veinHistory, id: \.completionID) { entry in
                        HStack(alignment: .firstTextBaseline) {
                            Text(DeepMineProgressLabels.date(
                                entry.endedAt,
                                calendar: calendar,
                                timeZone: timeZone
                            ))
                                .font(.caption.monospacedDigit())
                            Spacer()
                            if let vein = entry.vein {
                                Text(DeepMineStrings.text(DeepMineProgressLabels.veinKey(vein)))
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DeepMinePalette.brass.color)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("statistics-vein-entry")
                    }
                }
            }
        }
    }

    private var recoveryPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label(DeepMineStrings.text(.progressStorageTitle), systemImage: "exclamationmark.triangle")
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(.progressStorageBody))
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                Button { load() } label: {
                    DeepMineActionLabel(titleKey: .actionRetry, detailKey: nil, symbol: "arrow.clockwise")
                }
                .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
                .accessibilityIdentifier("statistics-retry")
            }
        }
        .accessibilityIdentifier("statistics-error")
    }

    private func load() {
        do {
            ledger = if let gameStore {
                try gameStore.mineLedger()
            } else {
                MineLedgerEngine.summarize(player)
            }
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}
