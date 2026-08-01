import Foundation
import XCTest
@testable import DeepMineCore

final class PrestigeTests: XCTestCase {
    func testEligibilityTargetBoundariesAndLossFirstPreview() {
        let target = PrestigeEngine.target(prestigeIndex: 0)
        let below = PlayerState(resources: Resources(ore: 999), runSegmentsBroken: target - 1)
        let belowPreview = PrestigeEngine.preview(for: below)
        XCTAssertEqual(belowPreview.targetRunSegments, 120)
        XCTAssertFalse(belowPreview.isEligible)
        XCTAssertEqual(belowPreview.losses.ore, 999)
        XCTAssertEqual(belowPreview.losses.runSegmentsBroken, target - 1)
        XCTAssertEqual(belowPreview.gains.coreShards, 2)
        XCTAssertEqual(belowPreview.gains.rebuyDiscount, Balance.rememberedRebuyDiscount)

        let exact = PlayerState(runSegmentsBroken: target)
        XCTAssertTrue(PrestigeEngine.preview(for: exact).isEligible)
        XCTAssertEqual(PrestigeEngine.target(prestigeIndex: 1), 180)
    }

    func testPrestigeBeforeTargetDoesNotMutate() {
        var state = PlayerState(
            resources: Resources(ore: 500),
            runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0) - 1
        )
        let snapshot = state
        let result = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        guard case .ineligible(let preview) = result else {
            return XCTFail("Expected ineligible result")
        }
        XCTAssertFalse(preview.isEligible)
        XCTAssertEqual(state, snapshot)
    }

    func testFirstPrestigeResetsExactFieldsAndPreservesDurableProgress() {
        let history = [historyEntry()]
        let daily = [DailyRecord(
            dayKey: DayKey(year: 2026, month: 7, day: 29),
            focusedMinutes: 100, goalMinutes: 100, sessionCount: 2,
            goalEarned: true, streakApplied: true, wasRestDay: false, isFinalized: false
        )]
        var state = PlayerState(
            resources: Resources(ore: 1_000, crystals: 7, coreShards: 2),
            equipment: EquipmentLevels(drill: 5, cart: 4, lamp: 3),
            runFocusCredits: 40, lifetimeFocusCredits: 80, runSegmentsBroken: 240,
            completedSessionCount: 60, bonusDepthMeters: 60,
            history: history, dailyGoalMinutes: 100, streakDays: 7,
            dailyRecords: daily, consecutiveVeinMisses: 4,
            permanentResonanceLevel: 2,
            unlockedThemes: [.entry, .crystal], selectedTheme: .crystal,
            unlockedDecorations: [.marker], resonanceBoostPending: true,
            excavationMemoryLevel: 1, compressedTimeLevel: 3
        )
        let result = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        guard case .prestiged(let preview, let newIndex) = result else {
            return XCTFail("Expected prestige")
        }

        XCTAssertTrue(preview.isEligible)
        XCTAssertEqual(newIndex, 1)
        XCTAssertEqual(state.prestigeIndex, 1)
        XCTAssertEqual(state.resources.ore, 0)
        XCTAssertEqual(state.resources.crystals, 7)
        XCTAssertEqual(state.resources.coreShards, 8)
        XCTAssertEqual(state.equipment, EquipmentLevels())
        XCTAssertEqual(state.runFocusCredits, 0)
        XCTAssertEqual(state.runSegmentsBroken, 0)
        // The legacy abyss offset was migrated into the durable depth record. The reset
        // position itself is genuinely the surface.
        XCTAssertEqual(state.bonusDepthMeters, 0)
        XCTAssertEqual(state.depthMeters, 0)
        XCTAssertGreaterThanOrEqual(state.recordDepthMeters, 60)
        XCTAssertEqual(state.rememberedEquipment, EquipmentLevels(drill: 5, cart: 4, lamp: 3))
        XCTAssertEqual(state.lifetimeFocusCredits, 80)
        XCTAssertEqual(state.completedSessionCount, 60)
        XCTAssertEqual(state.history, history)
        XCTAssertEqual(state.dailyRecords, daily)
        XCTAssertEqual(state.streakDays, 7)
        XCTAssertEqual(state.unlockedThemes, [.entry, .crystal])
        XCTAssertEqual(state.selectedTheme, .crystal)
        XCTAssertEqual(state.unlockedDecorations, [.marker])
        XCTAssertEqual(state.consecutiveVeinMisses, 4)
        XCTAssertTrue(state.resonanceBoostPending)
        XCTAssertEqual(state.permanentUpgrades, PermanentUpgradeLevels(
            excavationMemory: 1, resonanceDetection: 2, compressedTime: 3
        ))
    }

    func testShardGrantScalesWithTheRunThatWasActuallyDug() {
        var state = PlayerState(runSegmentsBroken: 240, prestigeIndex: 1)
        let result = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        guard case .prestiged(_, let newIndex) = result else {
            return XCTFail("Expected prestige")
        }
        XCTAssertEqual(newIndex, 2)
        XCTAssertEqual(state.resources.coreShards, 6)
        XCTAssertEqual(PrestigeEngine.target(prestigeIndex: 2), 270)
        // Overshooting the target is never wasted.
        XCTAssertEqual(PrestigeEngine.shardGrant(runSegmentsBroken: 120), 3)
        XCTAssertEqual(PrestigeEngine.shardGrant(runSegmentsBroken: 400), 10)
        XCTAssertEqual(PrestigeEngine.shardGrant(runSegmentsBroken: 0), 1)
        // Focus alone never opens a reset — the run is measured in rock (D-045).
        let focusOnly = PlayerState(runFocusCredits: 10_000, lifetimeFocusCredits: 10_000)
        XCTAssertFalse(PrestigeEngine.preview(for: focusOnly).isEligible)
    }

    func testPrestigeDoesNotReduceCappedGrowthMultiplier() throws {
        var state = PlayerState(runFocusCredits: 40, lifetimeFocusCredits: 40)
        let before = try RewardCalculator.calculate(input(
            length: .minutes25, growthFocusCredits: state.lifetimeFocusCredits,
            upgrades: PermanentUpgradeLevels()
        ))
        PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        let after = try RewardCalculator.calculate(input(
            length: .minutes25, growthFocusCredits: state.lifetimeFocusCredits,
            upgrades: PermanentUpgradeLevels()
        ))
        XCTAssertEqual(after.ore, before.ore, accuracy: 1e-12)
    }

    /// A reset that keeps the position leaves level-one equipment facing rock it cannot
    /// break. Going back to the surface is what makes the second descent possible, and
    /// the record is what keeps it from being a demotion (D-046).
    func testPrestigeReturnsToTheSurfaceButKeepsWhatWasOpened() {
        let deep = ProgressionEngine.segmentIndex(forDepth: Balance.ruinsRegionDepth)
        var state = PlayerState(
            equipment: EquipmentLevels(drill: 40, cart: 38, lamp: 36),
            runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0),
            mineFace: MineFaceState(segmentIndex: deep, lifetimeSegmentsBroken: deep)
        )
        let ceilingBefore = state.unlockedEquipmentLevel
        WorldProgression.unlockThemesForCurrentDepth(in: &state)
        let themesBefore = state.unlockedThemes

        guard case .prestiged = PrestigeEngine.prestige(
            PrestigeCommand(id: UUID()), in: &state
        ) else {
            return XCTFail("Expected prestige")
        }

        XCTAssertEqual(state.mineFace.segmentIndex, 0)
        XCTAssertEqual(state.depthMeters, 0)
        XCTAssertEqual(state.recordDepthMeters, Balance.ruinsRegionDepth)
        XCTAssertEqual(state.unlockedEquipmentLevel, ceilingBefore)
        XCTAssertEqual(state.unlockedThemes, themesBefore)
        XCTAssertEqual(state.mineFace.lifetimeSegmentsBroken, deep)
        // The surface is breakable with the equipment a reset leaves behind.
        XCTAssertLessThan(
            state.mineFace.segment.maximumIntegrity.doubleValue,
            RockGenerator.segment(at: deep).maximumIntegrity.doubleValue
        )
    }

    func testPrestigeCommandReplayDoesNotApplyTwice() {
        let command = PrestigeCommand(id: UUID())
        var state = PlayerState(runSegmentsBroken: PrestigeEngine.target(prestigeIndex: 0))
        PrestigeEngine.prestige(command, in: &state)
        let snapshot = state
        XCTAssertEqual(PrestigeEngine.prestige(command, in: &state), .duplicate)
        XCTAssertEqual(state, snapshot)
    }

    func testPermanentUpgradeCostsAndExactEffects() throws {
        var state = PlayerState(resources: Resources(coreShards: 6))
        XCTAssertEqual(purchase(.excavationMemory, in: &state), .purchased(
            upgrade: .excavationMemory, newLevel: 1, cost: 1
        ))
        XCTAssertEqual(purchase(.resonanceDetection, in: &state), .purchased(
            upgrade: .resonanceDetection, newLevel: 1, cost: 1
        ))
        XCTAssertEqual(purchase(.compressedTime, in: &state), .purchased(
            upgrade: .compressedTime, newLevel: 1, cost: 1
        ))
        XCTAssertEqual(purchase(.excavationMemory, in: &state), .purchased(
            upgrade: .excavationMemory, newLevel: 2, cost: 2
        ))
        XCTAssertEqual(state.resources.coreShards, 1)
        XCTAssertEqual(PrestigeEngine.memoryMultiplier(level: 1), 1.08)
        XCTAssertEqual(PrestigeEngine.compressedTimeBonus(level: 1), 0.05)
        XCTAssertEqual(
            VeinEngine.chance(plan: .safe, lampLevel: 1, permanentResonanceLevel: 1, consecutiveMisses: 0),
            0.13,
            accuracy: 1e-12
        )

        let memoryReward = try RewardCalculator.calculate(input(
            length: .minutes25,
            upgrades: PermanentUpgradeLevels(excavationMemory: 1)
        ))
        XCTAssertEqual(memoryReward.ore, 118.8, accuracy: 1e-9)
        let compressedReward = try RewardCalculator.calculate(input(
            length: .minutes50,
            upgrades: PermanentUpgradeLevels(compressedTime: 1)
        ))
        XCTAssertEqual(compressedReward.ore, 270, accuracy: 1e-9)
        let cartAndCompressed = RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: .minutes50,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: 0,
            streakDays: 1, dailySessionNumber: 1,
            equipment: EquipmentLevels(drill: 1, cart: 2, lamp: 1),
            vein: nil, resonanceBoostActive: false,
            permanentUpgrades: PermanentUpgradeLevels(compressedTime: 1)
        )
        // 200 base x (1.30 + 0.05 compressed) length x 1.07 cart, now a clean product
        // instead of the old ratio correction.
        XCTAssertEqual(
            try RewardCalculator.calculate(cartAndCompressed).ore,
            288.9,
            accuracy: 1e-9
        )
        let shippingInput = PrestigeEngine.applyingPermanentUpgrades(from: state, to: input(
            length: .minutes25, upgrades: PermanentUpgradeLevels()
        ))
        XCTAssertEqual(shippingInput.permanentUpgrades, state.permanentUpgrades)
    }

    func testPermanentPurchaseInsufficientMaximumAndReplay() {
        var poor = PlayerState()
        XCTAssertEqual(purchase(.excavationMemory, in: &poor), .insufficientShards(required: 1, available: 0))

        var capped = PlayerState(
            resources: Resources(coreShards: 100), excavationMemoryLevel: 10
        )
        XCTAssertEqual(purchase(.excavationMemory, in: &capped), .maximumLevel)

        let command = PermanentUpgradeCommand(id: UUID(), upgrade: .compressedTime)
        var state = PlayerState(resources: Resources(coreShards: 1))
        XCTAssertEqual(
            PrestigeEngine.purchase(command, in: &state),
            .purchased(upgrade: .compressedTime, newLevel: 1, cost: 1)
        )
        let snapshot = state
        XCTAssertEqual(PrestigeEngine.purchase(command, in: &state), .duplicate)
        XCTAssertEqual(state, snapshot)
    }

    func testPermanentStateAndCommandsAreCodable() throws {
        var state = PlayerState(
            resources: Resources(coreShards: 3), runFocusCredits: 40,
            permanentResonanceLevel: 2, excavationMemoryLevel: 1,
            compressedTimeLevel: 3, prestigeIndex: 2
        )
        PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(PlayerState.self, from: data), state)
    }

    private func purchase(
        _ upgrade: PermanentUpgradeKind,
        in state: inout PlayerState
    ) -> PermanentUpgradePurchaseResult {
        PrestigeEngine.purchase(
            PermanentUpgradeCommand(id: UUID(), upgrade: upgrade), in: &state
        )
    }

    private func input(
        length: SessionLength,
        growthFocusCredits: Double = 0,
        upgrades: PermanentUpgradeLevels
    ) -> RewardInput {
        RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: length,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: growthFocusCredits,
            streakDays: 1, dailySessionNumber: 1, equipment: EquipmentLevels(),
            vein: nil, resonanceBoostActive: false,
            permanentUpgrades: upgrades
        )
    }

    private func historyEntry() -> SessionHistoryEntry {
        SessionHistoryEntry(
            completionID: UUID(), endedAt: Date(timeIntervalSince1970: 1),
            focusedMinutes: 25, focusCredits: 1, plan: .safe,
            verificationGrade: .sealed, oreEarned: 100,
            vein: .crystal, depthAfter: 12, completed: true
        )
    }
}
