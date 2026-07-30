import Foundation

struct GameSurfaceSnapshotWriter: Sendable {
    let store: GameSurfaceSnapshotStore
    let refresher: GamePassiveSurfaceRefresher

    init(
        store: GameSurfaceSnapshotStore,
        refresher: GamePassiveSurfaceRefresher = .none
    ) {
        self.store = store
        self.refresher = refresher
    }

    static func shared() throws -> Self {
        Self(
            store: try GameSurfaceSnapshotStore.shared(),
            refresher: .product
        )
    }

    func write(_ snapshot: GameSurfaceSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        guard data.count < GameSurfaceSnapshotStore.maximumPayloadBytes else {
            throw GameSurfaceSnapshotStoreError.payloadTooLarge(
                actual: data.count,
                limit: GameSurfaceSnapshotStore.maximumPayloadBytes
            )
        }
        let lock = try ProbeProcessLock.acquire(
            filename: GameSurfaceSnapshotStore.lockFilename,
            directoryURL: store.directoryURL
        )
        defer { lock.release() }
        try FileManager.default.createDirectory(
            at: store.directoryURL,
            withIntermediateDirectories: true
        )
        let url = store.directoryURL.appending(
            path: GameSurfaceSnapshotStore.snapshotFilename
        )
        try data.write(to: url, options: .atomic)
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        try handle.synchronize()
        refresher.refresh()
    }
}
