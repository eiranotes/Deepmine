import Foundation
import OSLog

enum ProbeDiagnostics {
    private static let logger = Logger(
        subsystem: "com.eiraworks.deepmine.probe",
        category: "Phase0"
    )

    static func safeSummary(for error: Error) -> String {
        let nsError = error as NSError
        var description = nsError.localizedDescription
        let home = NSHomeDirectory()
        if !home.isEmpty {
            description = description.replacingOccurrences(of: home, with: "~")
        }
        if description.count > 600 {
            description = String(description.prefix(600)) + "…"
        }
        return "\(nsError.domain)(\(nsError.code)): \(description)"
    }

    static func record(error: Error, source: String) {
        logPrivate(error: error, source: source)
        do {
            try ProbeSharedStores.appendLog(
                source: source,
                level: .error,
                message: safeSummary(for: error)
            )
        } catch {
            logger.error(
                "Shared diagnostic write failed: \(String(reflecting: error), privacy: .private)"
            )
        }
    }

    static func logPrivate(error: Error, source: String) {
        logger.error(
            "\(source, privacy: .public) failure: \(String(reflecting: error), privacy: .private)"
        )
    }

    static func record(message: String, source: String, level: ProbeLogLevel) {
        do {
            try ProbeSharedStores.appendLog(
                source: source,
                level: level,
                message: message
            )
        } catch {
            logger.error(
                "Shared event write failed for \(source, privacy: .public): \(String(reflecting: error), privacy: .private)"
            )
        }
    }
}
