import DeepMineCore
import XCTest
@testable import DeepMineProbe

final class GameWidgetFoundationTests: XCTestCase {
    func testOnlyFreshWaitingSnapshotCreatesSafeTwentyFiveMinuteStart() {
        let waiting = GameWidgetSnapshotFixtures.result(named: "waiting")

        XCTAssertEqual(
            GameSystemEntryPolicy.startAction(for: waiting),
            .startSession(length: .minutes25, plan: .safe)
        )

        for state in ["mining", "completed", "vein", "collapsed", "stale", "missing"] {
            XCTAssertNil(
                GameSystemEntryPolicy.startAction(
                    for: GameWidgetSnapshotFixtures.result(named: state)
                ),
                "\(state) must open the app without queueing a new session"
            )
        }
    }

    func testControlValueNeverAdvertisesStartForRecoveryOrActiveState() {
        XCTAssertTrue(
            GameControlValue.make(
                from: GameWidgetSnapshotFixtures.result(named: "waiting")
            ).canStart
        )

        for state in ["mining", "completed", "vein", "collapsed", "stale", "missing"] {
            XCTAssertFalse(
                GameControlValue.make(
                    from: GameWidgetSnapshotFixtures.result(named: state)
                ).canStart
            )
        }
    }

    func testWidgetFixturesKeepMiningAndTerminalDataSeparated() throws {
        let mining = try fresh("mining")
        let vein = try fresh("vein")

        XCTAssertEqual(mining.earnedOre, 0)
        XCTAssertNil(mining.veinID)
        XCTAssertGreaterThan(mining.expectedOre, 0)
        XCTAssertEqual(vein.expectedOre, 0)
        XCTAssertGreaterThan(vein.earnedOre, 0)
        XCTAssertEqual(vein.veinID, "crystal")
    }

    private func fresh(_ state: String) throws -> GameSurfaceSnapshot {
        guard case let .fresh(snapshot) = GameWidgetSnapshotFixtures.result(named: state) else {
            throw FixtureError.notFresh
        }
        return snapshot
    }

    private enum FixtureError: Error { case notFresh }
}
