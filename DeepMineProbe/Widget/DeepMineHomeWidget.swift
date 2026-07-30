import DeepMineCore
import SwiftUI
import WidgetKit

struct DeepMineHomeEntry: TimelineEntry {
    let date: Date
    let result: GameSurfaceSnapshotReadResult
}

struct DeepMineHomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeepMineHomeEntry {
        let date = Date()
        return DeepMineHomeEntry(date: date, result: GameWidgetSnapshotFixtures.result(named: "waiting", at: date))
    }

    func getSnapshot(in context: Context, completion: @escaping (DeepMineHomeEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DeepMineHomeEntry>) -> Void
    ) {
        let now = Date()
        let entry = entry(at: now)
        let refresh = refreshDate(for: entry.result, now: now)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func entry(at date: Date) -> DeepMineHomeEntry {
        let result = (try? GameSurfaceSnapshotStore.shared().read(at: date)) ?? .missing
        return DeepMineHomeEntry(date: date, result: result)
    }

    private func refreshDate(for result: GameSurfaceSnapshotReadResult, now: Date) -> Date {
        let fallback = now.addingTimeInterval(Balance.passiveSnapshotFreshnessSeconds)
        let snapshot: GameSurfaceSnapshot? = switch result {
        case let .fresh(snapshot), let .stale(snapshot): snapshot
        case .missing: nil
        }
        guard let snapshot else { return fallback }
        let staleDate = Date(timeIntervalSince1970: snapshot.staleAfter)
        return staleDate > now ? staleDate : fallback
    }
}

struct DeepMineHomeWidget: Widget {
    let kind = GamePassiveSurfaceKinds.homeWidget

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeepMineHomeProvider()) { entry in
            DeepMineHomeWidgetRoot(entry: entry)
                .containerBackground(ProbePalette.coal, for: .widget)
        }
        .configurationDisplayName("widget.home.name")
        .description("widget.home.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct DeepMineHomeWidgetRoot: View {
    let entry: DeepMineHomeEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        GameHomeWidgetContent(
            result: entry.result,
            family: widgetFamily == .systemMedium ? .medium : .small,
            date: entry.date
        )
    }
}
