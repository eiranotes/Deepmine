import Foundation

public struct VeinCodexEntry: Codable, Equatable, Sendable {
    public let kind: VeinKind
    public let discoveries: Int
    public let firstFoundAt: Date?

    public var isDiscovered: Bool { discoveries > 0 }

    public init(kind: VeinKind, discoveries: Int, firstFoundAt: Date?) {
        self.kind = kind
        self.discoveries = discoveries
        self.firstFoundAt = firstFoundAt
    }
}

public struct VeinCodex: Codable, Equatable, Sendable {
    public let entries: [VeinCodexEntry]

    public var discoveredCount: Int { entries.count(where: \.isDiscovered) }
    public var totalCount: Int { entries.count }

    public init(entries: [VeinCodexEntry]) {
        self.entries = entries
    }
}

public enum VeinCodexEngine {
    /// Aggregates the retained history. Counts are bounded by `sessionHistoryLimit`, so
    /// a long-lived player sees "at least this many" rather than a lifetime total —
    /// the UI must not claim otherwise.
    public static func summarize(_ state: PlayerState) -> VeinCodex {
        var counts: [VeinKind: Int] = [:]
        var firstFound: [VeinKind: Date] = [:]
        for entry in state.history {
            guard let vein = entry.vein else { continue }
            counts[vein, default: 0] += 1
            if let existing = firstFound[vein] {
                firstFound[vein] = min(existing, entry.endedAt)
            } else {
                firstFound[vein] = entry.endedAt
            }
        }
        return VeinCodex(entries: VeinKind.allCases.map { kind in
            VeinCodexEntry(
                kind: kind,
                discoveries: counts[kind] ?? 0,
                firstFoundAt: firstFound[kind]
            )
        })
    }
}
