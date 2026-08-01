import Foundation
import XCTest
@testable import DeepMineCore

final class VeinWorldTests: XCTestCase {
    func testChanceCombinesPlanLampPermanentAndDrySpellExactly() {
        XCTAssertEqual(VeinEngine.chance(plan: .safe, lampLevel: 1, permanentResonanceLevel: 0, consecutiveMisses: 0), 0.12)
        XCTAssertEqual(VeinEngine.chance(plan: .survey, lampLevel: 1, permanentResonanceLevel: 0, consecutiveMisses: 0), 0.36)
        XCTAssertEqual(
            VeinEngine.chance(plan: .safe, lampLevel: 2, permanentResonanceLevel: 2, consecutiveMisses: 0),
            0.152,
            accuracy: 1e-12
        )
        XCTAssertEqual(VeinEngine.chance(plan: .safe, lampLevel: 1, permanentResonanceLevel: 0, consecutiveMisses: 3), 0.12)
        XCTAssertEqual(VeinEngine.chance(plan: .safe, lampLevel: 1, permanentResonanceLevel: 0, consecutiveMisses: 4), 0.20)
        XCTAssertEqual(VeinEngine.chance(plan: .safe, lampLevel: 1, permanentResonanceLevel: 0, consecutiveMisses: 5), 0.28)
    }

    func testSeventhMissGuaranteesExactlyTheEighthEligibleCompletion() {
        var generator = MaximumGenerator()
        var misses = 0
        for attempt in 1...7 {
            let result = VeinEngine.rollAfterCompletion(
                outcome: .completed, plan: .safe, lampLevel: 1,
                permanentResonanceLevel: 0, consecutiveMisses: &misses,
                using: &generator
            )
            XCTAssertNil(result.vein, "attempt \(attempt)")
            XCTAssertFalse(result.wasGuaranteed)
            XCTAssertEqual(misses, attempt)
        }
        let guaranteed = VeinEngine.rollAfterCompletion(
            outcome: .completed, plan: .safe, lampLevel: 1,
            permanentResonanceLevel: 0, consecutiveMisses: &misses,
            using: &generator
        )
        XCTAssertNotNil(guaranteed.vein)
        XCTAssertTrue(guaranteed.wasGuaranteed)
        XCTAssertEqual(guaranteed.chance, 1)
        XCTAssertEqual(misses, 0)
    }

    func testStateBasedRollerPersistsAndResetsMissCounter() {
        var generator = MaximumGenerator()
        var state = PlayerState(consecutiveVeinMisses: 7)
        let result = VeinEngine.rollAfterCompletion(
            outcome: .completed, plan: .safe, state: &state, using: &generator
        )
        XCTAssertTrue(result.wasGuaranteed)
        XCTAssertEqual(state.consecutiveVeinMisses, 0)
    }

    func testAbandonmentIsIneligibleAndDoesNotAdvanceMisses() {
        var generator = SeededGenerator(seed: 1)
        var misses = 4
        let result = VeinEngine.rollAfterCompletion(
            outcome: .abandoned(elapsedMinutes: 20), plan: .survey, lampLevel: 20,
            permanentResonanceLevel: 10, consecutiveMisses: &misses,
            using: &generator
        )
        XCTAssertFalse(result.wasEligible)
        XCTAssertNil(result.vein)
        XCTAssertEqual(misses, 4)
    }

    func testSeededRollsAreReproducible() {
        var first = SeededGenerator(seed: 260_729)
        var second = SeededGenerator(seed: 260_729)
        let firstSequence = (0..<100).map { _ in VeinEngine.rollKind(using: &first) }
        let secondSequence = (0..<100).map { _ in VeinEngine.rollKind(using: &second) }
        XCTAssertEqual(firstSequence, secondSequence)
    }

    func testWeightedTypeDistributionAcrossOneThousandRolls() {
        var generator = SeededGenerator(seed: 260_729)
        var counts: [VeinKind: Int] = [:]
        for _ in 0..<1_000 {
            counts[VeinEngine.rollKind(using: &generator), default: 0] += 1
        }
        let expected: [VeinKind: Double] = [
            .blue: 0.35, .crystal: 0.25, .vault: 0.15,
            .resonance: 0.15, .abyss: 0.10
        ]
        for (kind, probability) in expected {
            let observed = Double(counts[kind, default: 0]) / 1_000
            XCTAssertEqual(observed, probability, accuracy: 0.03, "\(kind)")
        }
    }

    func testRegionThresholdsAndIndices() {
        let crystal = Balance.crystalRegionDepth
        let ruins = Balance.ruinsRegionDepth
        let abyss = Balance.abyssRegionDepth
        let examples: [(Int, MineRegion, Int)] = [
            (0, .entry, 0), (crystal - 1, .entry, 0),
            (crystal, .crystal, 1), (ruins - 1, .crystal, 1),
            (ruins, .ruins, 2), (abyss - 1, .ruins, 2),
            (abyss, .abyss, 3)
        ]
        for (depth, region, index) in examples {
            XCTAssertEqual(WorldProgression.region(forDepth: depth), region)
            XCTAssertEqual(region.index, index)
        }
    }

    func testDepthReconciliationUnlocksEveryReachedRegionAndIsIdempotent() {
        let crystal = Balance.crystalRegionDepth
        let ruins = Balance.ruinsRegionDepth
        let abyss = Balance.abyssRegionDepth
        let examples: [(Int, Set<MineTheme>)] = [
            (crystal - 1, [.entry]),
            (crystal, [.entry, .crystal]),
            (ruins - 1, [.entry, .crystal]),
            (ruins, [.entry, .crystal, .ruins]),
            (abyss - 1, [.entry, .crystal, .ruins]),
            (abyss, Set(MineTheme.allCases))
        ]
        for (depth, expected) in examples {
            var state = PlayerState(bonusDepthMeters: depth)
            _ = WorldProgression.unlockThemesForCurrentDepth(in: &state)
            XCTAssertEqual(state.unlockedThemes, expected, "depth \(depth)")
            XCTAssertTrue(WorldProgression.unlockThemesForCurrentDepth(in: &state).isEmpty)
        }

        var earlyVault = PlayerState(bonusDepthMeters: crystal - 1)
        XCTAssertEqual(
            WorldProgression.apply(vein: .vault, effectID: UUID(), regionIndex: 0, to: &earlyVault),
            .themeUnlocked(.crystal)
        )
        XCTAssertTrue(WorldProgression.unlockThemesForCurrentDepth(in: &earlyVault).isEmpty)
        XCTAssertTrue(earlyVault.unlockedThemes.contains(.crystal))

        var abyssCrossing = PlayerState(bonusDepthMeters: crystal - 1)
        _ = WorldProgression.unlockThemesForCurrentDepth(in: &abyssCrossing)
        _ = WorldProgression.apply(
            vein: .abyss, effectID: UUID(), regionIndex: 0, to: &abyssCrossing
        )
        XCTAssertTrue(abyssCrossing.unlockedThemes.contains(.crystal))
        XCTAssertTrue(WorldProgression.unlockThemesForCurrentDepth(in: &abyssCrossing).isEmpty)
    }

    func testBlueCrystalAndAbyssEffects() {
        var state = PlayerState()
        XCTAssertEqual(
            WorldProgression.apply(vein: .blue, effectID: UUID(), regionIndex: 0, to: &state),
            .oreMultiplier(1.5)
        )
        XCTAssertEqual(
            WorldProgression.apply(vein: .crystal, effectID: UUID(), regionIndex: 2, to: &state),
            .crystals(3)
        )
        XCTAssertEqual(state.resources.crystals, 3)
        XCTAssertEqual(
            WorldProgression.apply(vein: .abyss, effectID: UUID(), regionIndex: 0, to: &state),
            .bonusDepth(60)
        )
        XCTAssertEqual(state.bonusDepthMeters, 0)
        XCTAssertEqual(state.mineFace.segmentIndex, 15)
        XCTAssertEqual(state.depthMeters, 60)
        XCTAssertEqual(state.mineFace.region, WorldProgression.region(forDepth: state.depthMeters))
    }

    func testVaultUnlockOrderConversionAndReplay() {
        var state = PlayerState()
        let themes: [MineTheme] = [.crystal, .ruins, .abyss]
        for theme in themes {
            XCTAssertEqual(
                WorldProgression.apply(vein: .vault, effectID: UUID(), regionIndex: 0, to: &state),
                .themeUnlocked(theme)
            )
        }
        let decorations: [MineDecoration] = [.marker, .rail, .lamp, .cart]
        for decoration in decorations {
            XCTAssertEqual(
                WorldProgression.apply(vein: .vault, effectID: UUID(), regionIndex: 0, to: &state),
                .decorationUnlocked(decoration)
            )
        }
        let conversionID = UUID()
        XCTAssertEqual(
            WorldProgression.apply(vein: .vault, effectID: conversionID, regionIndex: 0, to: &state),
            .vaultConvertedToCrystals(2)
        )
        let snapshot = state
        XCTAssertEqual(
            WorldProgression.apply(vein: .vault, effectID: conversionID, regionIndex: 0, to: &state),
            .duplicate
        )
        XCTAssertEqual(state, snapshot)
    }

    func testThemeSelectionRequiresUnlockAndIsIdempotent() {
        var state = PlayerState()
        XCTAssertEqual(WorldProgression.selectTheme(.crystal, in: &state), .locked)
        WorldProgression.apply(vein: .vault, effectID: UUID(), regionIndex: 0, to: &state)
        XCTAssertEqual(WorldProgression.selectTheme(.crystal, in: &state), .selected)
        XCTAssertEqual(WorldProgression.selectTheme(.crystal, in: &state), .unchanged)
        XCTAssertEqual(state.selectedTheme, .crystal)
    }

    func testResonanceArmsAndConsumesOneBoostExactlyOnce() {
        var state = PlayerState()
        let id = UUID()
        XCTAssertEqual(
            WorldProgression.apply(vein: .resonance, effectID: id, regionIndex: 0, to: &state),
            .resonanceArmed
        )
        XCTAssertTrue(WorldProgression.consumeResonanceBoost(in: &state))
        XCTAssertFalse(WorldProgression.consumeResonanceBoost(in: &state))
        XCTAssertEqual(
            WorldProgression.apply(vein: .resonance, effectID: id, regionIndex: 0, to: &state),
            .duplicate
        )
        XCTAssertFalse(WorldProgression.consumeResonanceBoost(in: &state))
    }

    func testBlueVeinIntegratesWithExistingRewardInput() throws {
        let input = RewardInput(
            completionID: UUID(), outcome: .completed, sessionLength: .minutes25,
            plan: .safe, verificationGrade: .sealed, growthFocusCredits: 0,
            streakDays: 1, dailySessionNumber: 1, equipment: EquipmentLevels(),
            vein: nil, resonanceBoostActive: false
        )
        let base = try RewardCalculator.calculate(input)
        let blue = try RewardCalculator.calculate(VeinEngine.applying(vein: .blue, to: input))
        XCTAssertEqual(blue.ore, base.ore * 1.5, accuracy: 1e-12)
    }

    func testWorldStateCodableRoundTrip() throws {
        var state = PlayerState()
        WorldProgression.apply(vein: .vault, effectID: UUID(), regionIndex: 0, to: &state)
        WorldProgression.apply(vein: .resonance, effectID: UUID(), regionIndex: 0, to: &state)
        let data = try JSONEncoder().encode(state)
        XCTAssertEqual(try JSONDecoder().decode(PlayerState.self, from: data), state)
    }
}

private struct MaximumGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 { UInt64.max }
}
