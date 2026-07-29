import Foundation

enum ProbeLogLevel: String, Codable, Sendable {
    case info
    case success
    case warning
    case error
}

struct ProbeLogEntry: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let source: String
    let level: ProbeLogLevel
    let message: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: String,
        level: ProbeLogLevel,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.level = level
        self.message = message
    }
}

enum ProbeStoreError: LocalizedError {
    case missingAppGroup(String)
    case invalidJSONLine(Int)

    var errorDescription: String? {
        switch self {
        case .missingAppGroup(let identifier):
            "App Group container is unavailable: \(identifier)"
        case .invalidJSONLine(let line):
            "The shared JSONL store contains invalid data at line \(line)."
        }
    }
}
