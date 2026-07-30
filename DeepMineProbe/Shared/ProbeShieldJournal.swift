import Foundation

struct ProbeShieldExpiry: Codable, Equatable, Sendable {
    let sessionID: UUID?
    let activityName: String
    let expiresAt: Date

    init(sessionID: UUID? = nil, activityName: String, expiresAt: Date) {
        self.sessionID = sessionID
        self.activityName = activityName
        self.expiresAt = expiresAt
    }
}

enum ProbeShieldJournal {
    static func save(_ expiry: ProbeShieldExpiry, directoryURL: URL? = nil) throws {
        let url = try fileURL(directoryURL: directoryURL)
        let data = try JSONEncoder().encode(expiry)
        try data.write(to: url, options: .atomic)
    }

    static func load(directoryURL: URL? = nil) throws -> ProbeShieldExpiry? {
        let url = try fileURL(directoryURL: directoryURL)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(
            ProbeShieldExpiry.self,
            from: Data(contentsOf: url)
        )
    }

    static func remove(directoryURL: URL? = nil) throws {
        let url = try fileURL(directoryURL: directoryURL)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    @discardableResult
    static func removeIfMatching(
        activityName: String,
        directoryURL: URL? = nil
    ) throws -> Bool {
        guard let expiry = try load(directoryURL: directoryURL),
              expiry.activityName == activityName else {
            return false
        }
        try remove(directoryURL: directoryURL)
        return true
    }

    private static func fileURL(directoryURL: URL?) throws -> URL {
        let directory = try directoryURL ?? ProbeSharedStores.directoryURL()
        return directory
            .appending(path: ProbeConstants.shieldExpiryFilename)
    }
}
