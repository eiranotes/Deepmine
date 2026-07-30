import DeepMineCore
import SwiftUI

@MainActor
struct JournalView: View {
    let gameStore: GameStore?
    let player: PlayerState
    let referenceDate: Date
    let calendar: Calendar
    let timeZone: TimeZone
    @State private var ledger: WeeklyLedger?
    @State private var loadFailed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                if loadFailed {
                    recoveryPanel
                } else if let ledger {
                    weekHeader(ledger)
                    if ledger.entries.isEmpty { emptyPanel } else { entries(ledger) }
                }
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationJournal))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("journal-screen")
        .task { load() }
    }

    private func weekHeader(_ ledger: WeeklyLedger) -> some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 6) {
                Label(DeepMineStrings.text(.journalWeek), systemImage: "book.closed.fill")
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("journal-screen")
                Text(
                    "\(formatted(ledger.startsAt)) – " + formatted(ledger.endsAt)
                )
                .font(.caption.monospacedDigit())
                .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyPanel: some View {
        DeepMineRivetedPanel {
            VStack(spacing: 10) {
                Image(systemName: "text.book.closed")
                    .font(.title2)
                    .foregroundStyle(DeepMinePalette.brass.color)
                Text(DeepMineStrings.text(.journalEmptyTitle))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("journal-empty")
                Text(DeepMineStrings.text(.journalEmptyBody))
                    .font(.subheadline)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("journal-empty")
    }

    private func entries(_ ledger: WeeklyLedger) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(ledger.entries, id: \.completionID) { entry in
                entryRow(entry)
            }
        }
    }

    private func entryRow(_ entry: SessionHistoryEntry) -> some View {
        DeepMineRivetedPanel {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 3) {
                    Circle()
                        .fill(entry.completed
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.52))
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(DeepMinePalette.limestone.color.opacity(0.24))
                        .frame(width: 2, height: 52)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(formatted(entry.endedAt))
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .accessibilityIdentifier("journal-entry")
                        Spacer()
                        Text(DeepMineStrings.text(
                            entry.completed ? .journalCompleted : .journalAbandoned
                        ))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier(
                            entry.completed ? "journal-entry-completed" : "journal-entry-abandoned"
                        )
                    }
                    Text(DeepMineStrings.text(DeepMineProgressLabels.planKey(entry.plan)))
                        .font(.caption)
                    HStack(spacing: 12) {
                        Label(
                            "\(entry.focusedMinutes) \(DeepMineStrings.text(.gameMinutes))",
                            systemImage: "hourglass"
                        )
                        Label(
                            DeepMineNumberFormatter.string(entry.oreEarned),
                            systemImage: "shippingbox.fill"
                        )
                        Label(
                            "\(DeepMineStrings.text(.gameDepth)) \(entry.depthAfter)m",
                            systemImage: "arrow.down.to.line"
                        )
                    }
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                    if let vein = entry.vein {
                        Label(
                            DeepMineStrings.text(DeepMineProgressLabels.veinKey(vein)),
                            systemImage: "sparkles"
                        )
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
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
                .accessibilityIdentifier("journal-retry")
            }
        }
        .accessibilityIdentifier("journal-error")
    }

    private func load() {
        do {
            ledger = if let gameStore {
                try gameStore.weeklyLedger()
            } else {
                WeeklyLedgerEngine.summarize(
                    player,
                    referenceDate: referenceDate,
                    calendar: calendar,
                    timeZone: timeZone
                )
            }
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func formatted(_ date: Date) -> String {
        DeepMineProgressLabels.date(date, calendar: calendar, timeZone: timeZone)
    }
}
