import Foundation
import SwiftData

@Model
final class ProbeSharedWrite {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var source: String
    var acknowledgedAt: Date?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: String,
        acknowledgedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.acknowledgedAt = acknowledgedAt
    }
}

@MainActor
enum ProbeModelContainer {
    static func make(
        storeURL: URL? = nil,
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema([ProbeSharedWrite.self])
        let configuration: ModelConfiguration

        if isStoredInMemoryOnly {
            configuration = ModelConfiguration(
                "DeepMineProbeShared",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
        } else {
            let url = try storeURL ?? sharedStoreURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            configuration = ModelConfiguration(
                "DeepMineProbeShared",
                schema: schema,
                url: url,
                cloudKitDatabase: .none
            )
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func sharedStoreURL() throws -> URL {
        try ProbeSharedStores.directoryURL().appending(path: ProbeConstants.swiftDataFilename)
    }

    @discardableResult
    static func insert(source: String, into container: ModelContainer? = nil) throws -> UUID {
        let modelContainer = try container ?? make()
        let context = ModelContext(modelContainer)
        let record = ProbeSharedWrite(source: source)
        context.insert(record)
        try context.save()
        return record.id
    }

    static func fetchAll(from container: ModelContainer? = nil) throws -> [ProbeSharedWrite] {
        let modelContainer = try container ?? make()
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<ProbeSharedWrite>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        return try context.fetch(descriptor)
    }

    static func acknowledgeAll(from container: ModelContainer? = nil) throws -> [ProbeSharedWrite] {
        let modelContainer = try container ?? make()
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ProbeSharedWrite>(
            predicate: #Predicate { $0.acknowledgedAt == nil },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let records = try context.fetch(descriptor)
        let acknowledgedAt = Date()
        records.forEach { $0.acknowledgedAt = acknowledgedAt }
        if !records.isEmpty {
            try context.save()
        }
        return records
    }
}
