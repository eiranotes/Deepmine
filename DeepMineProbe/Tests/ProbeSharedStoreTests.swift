import Foundation
import SwiftData
import XCTest
@testable import DeepMine

@MainActor
final class ProbeSharedStoreTests: XCTestCase {
    func testShieldExpiryJournalRoundTripsAndRemoves() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineProbeShieldTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let expiry = ProbeShieldExpiry(
            activityName: "DeepMineProbeSession.current",
            expiresAt: Date(timeIntervalSince1970: 2_000)
        )

        try ProbeShieldJournal.save(expiry, directoryURL: directory)
        XCTAssertEqual(try ProbeShieldJournal.load(directoryURL: directory), expiry)

        try ProbeShieldJournal.remove(directoryURL: directory)
        XCTAssertNil(try ProbeShieldJournal.load(directoryURL: directory))
    }

    func testStaleMonitorCannotRemoveNewShieldJournal() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineProbeShieldRaceTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let current = ProbeShieldExpiry(
            activityName: "DeepMineProbeSession.new",
            expiresAt: Date(timeIntervalSince1970: 3_000)
        )
        try ProbeShieldJournal.save(current, directoryURL: directory)

        XCTAssertFalse(
            try ProbeShieldJournal.removeIfMatching(
                activityName: "DeepMineProbeSession.old",
                directoryURL: directory
            )
        )
        XCTAssertEqual(try ProbeShieldJournal.load(directoryURL: directory), current)
    }

    func testInMemoryInsertAndFetchPreservesIdentity() throws {
        let container = try ProbeModelContainer.make(isStoredInMemoryOnly: true)

        let id = try ProbeModelContainer.insert(source: "unit-test", into: container)
        let records = try ProbeModelContainer.fetchAll(from: container)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, id)
        XCTAssertEqual(records.first?.source, "unit-test")
    }

    func testDiskStoreSurvivesContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "DeepMineProbeSwiftDataTests-\(UUID().uuidString)")
        let storeURL = directory.appending(path: "ProbeShared.store")
        defer { try? FileManager.default.removeItem(at: directory) }

        var firstContainer: ModelContainer? = try ProbeModelContainer.make(storeURL: storeURL)
        let id = try ProbeModelContainer.insert(source: "disk-test", into: firstContainer)
        firstContainer = nil

        let reopenedContainer = try ProbeModelContainer.make(storeURL: storeURL)
        let records = try ProbeModelContainer.fetchAll(from: reopenedContainer)

        XCTAssertEqual(records.first?.id, id)
        XCTAssertEqual(records.first?.source, "disk-test")
    }
}
