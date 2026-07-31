import Foundation
import XCTest
@testable import DeepMineCore

final class PrestigeTests: XCTestCase {
    func testEligibilityTargetBoundariesAndLossFirstPreview() {
        let below = PlayerState(resources: Resources(ore: 999), runFocusCredits: 39.999)
        let belowPreview = PrestigeEngine.preview(for: below)
        XCTAssertEqual(belowPreview.targetRunFocusCredits, 40)
        XCTAssertFalse(belowPreview.isEligible)
        XCTAssertEqual(belowPreview.losses.ore, 999)
        XCTAssertEqual(belowPreview.losses.runFocusCredits, 39.999)
        XCTAssertEqual(belowPreview.gains.coreShards, 3)
        XCTAssertEqual(belowPreview.gains.rebuyDiscount, Balance.rememberedRebuyDiscount)

        let exact = PlayerState(runFocusCredits: 40)
        XCTAssertTrue(PrestigeEngine.preview(for: exact).isEligible)
        XCTAssertEqual(PrestigeEngine.target(prestigeIndex: 1), 64, accuracy: 1e-12)
    }

    func testPrestigeBeforeTargetDoesNotMutate() {
        var state = PlayerState(resources: Resources(ore: 500), runFocusCredits: 39.9)
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
            runFocusCredits: 40, lifetimeFocusCredits: 80,
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
        XCTAssertEqual(state.resources.coreShards, 6)
        XCTAssertEqual(state.equipment, EquipmentLevels())
        XCTAssertEqual(state.runFocusCredits, 0)
        // Depth is lifetime now, so its abyss bonus survives prestige too.
        XCTAssertEqual(state.bonusDepthMeters, 60)
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
        var state = PlayerState(runFocusCredits: 64, prestigeIndex: 1)
        let result = PrestigeEngine.prestige(PrestigeCommand(id: UUID()), in: &state)
        guard case .prestiged(_, let newIndex) = result else {
            return XCTFail("Expected prestige")
        }
        XCTAssertEqual(newIndex, 2)
        XCTAssertEqual(state.resources.coreShards, 6)
        XCTAssertEqual(PrestigeEngine.target(prestigeIndex: 2), 102.4, accuracy: 1e-12)
        // Overshooting the target is never wasted.
        XCTAssertEqual(PrestigeEngine.shardGrant(runFocusCredits: 40), 4)
        XCTAssertEqual(PrestigeEngine.shardGrant(runFocusCredits: 120), 12)
        XCTAssertEqual(PrestigeEngine.shardGrant(runFocusCredits: 0), 1)
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

    func testPrestigeCommandReplayDoesNotApplyTwice() {
        let command = PrestigeCommand(id: UUID())
        var state = PlayerState(runFocusCredits: 40)
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
