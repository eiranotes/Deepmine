import Foundation
import XCTest
@testable import DeepMineCore

final class SessionRewardTests: XCTestCase {
    func testCompletedLengthExamples() throws {
        XCTAssertEqual(try reward(length: .minutes15).ore, 60, accuracy: 1e-12)
        XCTAssertEqual(try reward(length: .minutes25).ore, 110, accuracy: 1e-12)
        XCTAssertEqual(try reward(length: .minutes50).ore, 260, accuracy: 1e-12)
    }

    func testFocusCreditsUseElapsedMinutesForAbandonment() throws {
        let result = try reward(
            length: .minutes25,
            plan: .safe,
            outcome: .abandoned(elapsedMinutes: 10)
        )
        XCTAssertEqual(result.focusCredits, 0.4, accuracy: 1e-12)
        XCTAssertEqual(result.ore, 20, accuracy: 1e-12)
        XCTAssertEqual(result.breakdown.abandonment, 0.5)
        XCTAssertEqual(result.breakdown.length, 1)
        XCTAssertEqual(
            try reward(length: .minutes25, plan: .survey, outcome: .abandoned(elapsedMinutes: 10)).ore,
            16,
            accuracy: 1e-12
        )
    }

    func testDeepAbandonmentAndCollapsedDeepAwardZero() throws {
        XCTAssertEqual(
            try reward(plan: .deep, outcome: .abandoned(elapsedMinutes: 20)).ore,
            0
        )
        XCTAssertEqual(try reward(plan: .deep, grade: .collapsed).ore, 0)
        XCTAssertEqual(try reward(plan: .safe, grade: .collapsed).ore, 55, accuracy: 1e-12)
    }



    func testClockForwardBackwardThresholdAndReboot() {
        let start = ClockAnchor(wallClock: Date(timeIntervalSince1970: 1_000), monotonicNanoseconds: 100_000_000_000)

        XCTAssertEqual(observation(start: start, wallElapsed: 130, monotonicEnd: 200_000_000_000).assessment, .valid)
        XCTAssertEqual(observation(start: start, wallElapsed: 131, monotonicEnd: 200_000_000_000).assessment, .tampered)
        XCTAssertEqual(observation(start: start, wallElapsed: 69, monotonicEnd: 200_000_000_000).assessment, .tampered)

        let rebooted = observation(start: start, wallElapsed: 100, monotonicEnd: 50)
        XCTAssertEqual(rebooted.assessment, .rebooted)
        XCTAssertNil(rebooted.monotonicElapsed)
        XCTAssertEqual(rebooted.acceptedElapsed, 100)
    }

    func testVerificationGradeResolution() {
        XCTAssertEqual(VerificationGrade.resolve(blockingEnabled: true, shieldMaintained: true, forcedShieldRemoval: false), .sealed)
        XCTAssertEqual(VerificationGrade.resolve(blockingEnabled: false, shieldMaintained: false, forcedShieldRemoval: false), .open)
        XCTAssertEqual(VerificationGrade.resolve(blockingEnabled: true, shieldMaintained: false, forcedShieldRemoval: true), .collapsed)
    }

    func testStateMachineLegalTransitionsRecordTimestampsAndID() throws {
        let prepared = Date(timeIntervalSince1970: 100)
        let started = Date(timeIntervalSince1970: 101)
        let ended = Date(timeIntervalSince1970: 201)
        let id = UUID()
        var machine = SessionStateMachine(preparedAt: prepared)

        try machine.start(at: started)
        try machine.complete(at: ended, completionID: id)

        XCTAssertEqual(machine.phase, .completed)
        XCTAssertEqual(machine.startedAt, started)
        XCTAssertEqual(machine.endedAt, ended)
        XCTAssertEqual(machine.completionID, id)
    }

    func testAllIllegalStateTransitionsThrow() throws {
        let actions: [SessionAction] = [.start, .complete, .abandon]
        let legal: Set<PhaseAction> = [
            PhaseAction(.preparing, .start),
            PhaseAction(.mining, .complete),
            PhaseAction(.mining, .abandon)
        ]

        for phase in SessionPhase.allCases {
            for action in actions where !legal.contains(PhaseAction(phase, action)) {
                var machine = try machine(in: phase)
                XCTAssertThrowsError(try perform(action, on: &machine), "\(phase) -> \(action)") { error in
                    XCTAssertEqual(error as? SessionTransitionError, .illegalTransition(from: phase, action: action))
                }
            }
        }
    }

    func testEveryMultiplierIsReportedAndComposed() throws {
        let input = RewardInput(
            completionID: UUID(),
            outcome: .completed,
            sessionLength: .minutes25,
            plan: .deep,
            verificationGrade: .open,
            growthFocusCredits: 10,
            streakDays: 7,
            dailySessionNumber: 2,
            equipment: EquipmentLevels(drill: 2, cart: 2, lamp: 1),
            vein: .blue,
            resonanceBoostActive: true
        )
        let result = try RewardCalculator.calculate(input)
        let b = result.breakdown
        XCTAssertEqual(b.growth, pow(1.04, 10), accuracy: 1e-12)
        XCTAssertEqual(b.length, 1.1)
        XCTAssertEqual(b.plan, 1.6)
        XCTAssertEqual(b.verification, 0.75)
        XCTAssertEqual(b.streak, 1.25)
        XCTAssertEqual(b.dailyOrder, 1.05)
        XCTAssertEqual(b.equipment, 1.12 * 1.05)
        XCTAssertEqual(b.vein, 3)
        XCTAssertEqual(b.abandonment, 1)
        XCTAssertEqual(result.ore, b.baseOre * b.combinedMultiplier, accuracy: 1e-9)
    }

    func testGrowthSnapshotsCapAtTwentyFocusCredits() throws {
        let snapshots: [(Double, Double)] = [
            (1, 114.4),
            (10, 162.8268713410179),
            (20, 241.02354573367616),
            (40, 241.02354573367616),
            (80, 241.02354573367616)
        ]
        for (credits, expected) in snapshots {
            XCTAssertEqual(try reward(growthCredits: credits).ore, expected, accuracy: 1e-9)
        }
    }

    func testGrowthCapIsMonotonicAndIndependentOfRunReset() {
        let atCap = RewardCalculator.growthMultiplier(focusCredits: 20)
        XCTAssertEqual(atCap, pow(1.04, 20), accuracy: 1e-12)
        XCTAssertEqual(RewardCalculator.growthMultiplier(focusCredits: 40), atCap, accuracy: 1e-12)
        XCTAssertEqual(RewardCalculator.growthMultiplier(focusCredits: 80), atCap, accuracy: 1e-12)
    }

    func testFiveHundredGrowthCreditValueIsFinite() throws {
        for credits in 0..<500 {
            let result = try reward(growthCredits: Double(credits))
            XCTAssertTrue(result.ore.isFinite)
            XCTAssertGreaterThan(result.ore, 0)
        }
    }

    func testCompletionRegistryAwardsAnIDOnlyOnce() throws {
        let input = makeInput()
        var registry = CompletionRegistry()
        let first = try RewardCalculator.award(input, using: &registry)
        let replay = try RewardCalculator.award(input, using: &registry)

        XCTAssertFalse(first.wasDuplicate)
        XCTAssertGreaterThan(first.ore, 0)
        XCTAssertTrue(replay.wasDuplicate)
        XCTAssertEqual(replay.ore, 0)
        XCTAssertEqual(registry.awardedCompletionIDs, [input.completionID])
    }

    func testRewardRejectsInvalidBoundaryInputs() {
        XCTAssertThrowsError(try reward(outcome: .abandoned(elapsedMinutes: 26)))

        let invalidEquipment = RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: .minutes25,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: 0,
            streakDays: 0, dailySessionNumber: 1,
            equipment: EquipmentLevels(drill: 0, cart: 1, lamp: 1), vein: nil,
            resonanceBoostActive: false
        )
        XCTAssertThrowsError(try RewardCalculator.calculate(invalidEquipment))
    }

    func testCodableRoundTripsSessionAndRewardInput() throws {
        var session = SessionStateMachine(preparedAt: Date(timeIntervalSince1970: 1))
        try session.start(at: Date(timeIntervalSince1970: 2))
        try session.complete(at: Date(timeIntervalSince1970: 3), completionID: UUID())
        let encodedSession = try JSONEncoder().encode(session)
        XCTAssertEqual(try JSONDecoder().decode(SessionStateMachine.self, from: encodedSession), session)

        let input = makeInput()
        let encodedInput = try JSONEncoder().encode(input)
        XCTAssertEqual(try JSONDecoder().decode(RewardInput.self, from: encodedInput), input)
    }

    func testDecodingRejectsAnImpossibleSessionState() {
        let invalid = Data(#"{"phase":"completed","preparedAt":0}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SessionStateMachine.self, from: invalid))
    }

    private func reward(
        length: SessionLength = .minutes25,
        plan: MinePlan = .safe,
        grade: VerificationGrade = .sealed,
        outcome: SessionOutcome = .completed,
        growthCredits: Double = 0
    ) throws -> RewardResult {
        try RewardCalculator.calculate(makeInput(
            length: length,
            plan: plan,
            grade: grade,
            outcome: outcome,
            growthCredits: growthCredits
        ))
    }

    private func makeInput(
        length: SessionLength = .minutes25,
        plan: MinePlan = .safe,
        grade: VerificationGrade = .sealed,
        outcome: SessionOutcome = .completed,
        growthCredits: Double = 0
    ) -> RewardInput {
        RewardInput(
            completionID: UUID(), outcome: outcome, sessionLength: length,
            plan: plan, verificationGrade: grade,
            growthFocusCredits: growthCredits, streakDays: 1,
            dailySessionNumber: 1, equipment: EquipmentLevels(), vein: nil,
            resonanceBoostActive: false
        )
    }

    private func observation(start: ClockAnchor, wallElapsed: TimeInterval, monotonicEnd: UInt64) -> ClockObservation {
        ClockIntegrityChecker.finish(
            anchor: start,
            endWallClock: start.wallClock.addingTimeInterval(wallElapsed),
            endMonotonicNanoseconds: monotonicEnd
        )
    }

    private func machine(in phase: SessionPhase) throws -> SessionStateMachine {
        var machine = SessionStateMachine(preparedAt: Date(timeIntervalSince1970: 1))
        if phase != .preparing { try machine.start(at: Date(timeIntervalSince1970: 2)) }
        if phase == .completed { try machine.complete(at: Date(timeIntervalSince1970: 3), completionID: UUID()) }
        if phase == .abandoned { try machine.abandon(at: Date(timeIntervalSince1970: 3), completionID: UUID()) }
        return machine
    }

    private func perform(_ action: SessionAction, on machine: inout SessionStateMachine) throws {
        switch action {
        case .start: try machine.start(at: Date())
        case .complete: try machine.complete(at: Date(), completionID: UUID())
        case .abandon: try machine.abandon(at: Date(), completionID: UUID())
        }
    }
}

private struct PhaseAction: Hashable {
    let phase: SessionPhase
    let action: SessionAction

    init(_ phase: SessionPhase, _ action: SessionAction) {
        self.phase = phase
        self.action = action
    }
}
