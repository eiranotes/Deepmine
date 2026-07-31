import Foundation
import XCTest
@testable import DeepMine

final class ProbeLogStoreTests: XCTestCase {
    private var directoryURL: URL!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineProbeLogTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        if let directoryURL {
            try? FileManager.default.removeItem(at: directoryURL)
        }
    }

    func testEntriesRoundTripInInsertionOrder() throws {
        let store = try ProbeSharedStores.logStore(directoryURL: directoryURL)
        let first = ProbeLogEntry(
            timestamp: Date(timeIntervalSince1970: 1_000),
            source: "first",
            level: .info,
            message: "one"
        )
        let second = ProbeLogEntry(
            timestamp: Date(timeIntervalSince1970: 2_000),
            source: "second",
            level: .success,
            message: "two"
        )

        try store.append(first)
        try store.append(second)

        XCTAssertEqual(try store.read(), [first, second])
    }

    func testMalformedSecondLineReportsExactLine() throws {
        let store = try ProbeSharedStores.logStore(directoryURL: directoryURL)
        try store.append(ProbeLogEntry(source: "valid", level: .info, message: "one"))
        let handle = try FileHandle(forWritingTo: store.fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data("not-json\n".utf8))

        XCTAssertThrowsError(try store.read()) { error in
            guard case ProbeStoreError.invalidJSONLine(let line) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(line, 2)
        }
    }

    func testConcurrentAppendsDoNotLoseOrCorruptRecords() async throws {
        let store = try ProbeSharedStores.logStore(directoryURL: directoryURL)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<100 {
                group.addTask {
                    try store.append(
                        ProbeLogEntry(
                            timestamp: Date(timeIntervalSince1970: TimeInterval(index)),
                            source: "writer-\(index)",
                            level: .info,
                            message: "entry-\(index)"
                        )
                    )
                }
            }
            try await group.waitForAll()
        }

        let entries = try store.read()
        XCTAssertEqual(entries.count, 100)
        XCTAssertEqual(Set(entries.map(\.source)).count, 100)
    }
}
