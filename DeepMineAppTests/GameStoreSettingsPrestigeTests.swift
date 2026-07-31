import DeepMineCore
import Foundation
import XCTest
@testable import DeepMineProbe

@MainActor
final class GameStoreSettingsPrestigeTests: XCTestCase {


    func testThemeSelectionOnlyPersistsAChangedUnlockedTheme() throws {
        let fixture = makeFixture(player: PlayerState(
            unlockedThemes: [.entry, .crystal],
            selectedTheme: .entry
        ))

        XCTAssertEqual(try fixture.store.selectTheme(.ruins), .locked)
        XCTAssertEqual(try fixture.store.selectTheme(.crystal), .selected)
        XCTAssertEqual(try fixture.store.selectTheme(.crystal), .unchanged)
        XCTAssertEqual(fixture.repository.player.selectedTheme, .crystal)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testIneligiblePrestigeReturnsLossFirstPreviewWithoutSave() throws {
        let player = PlayerState(resources: Resources(ore: 700), runFocusCredits: 39)
        let fixture = makeFixture(player: player)

        let preview = try fixture.store.prestigePreview()
        let result = try fixture.store.confirmPrestige(commandID: UUID())

        XCTAssertFalse(preview.isEligible)
        XCTAssertEqual(result, .ineligible(preview: preview))
        XCTAssertEqual(fixture.repository.player, player)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 0)
    }

    func testEligiblePrestigeResetsOnlyCanonicalFieldsAndReplayIsIdempotent() throws {
        let player = PlayerState(
            resources: Resources(ore: 700, crystals: 4, coreShards: 2),
            equipment: EquipmentLevels(drill: 5, cart: 4, lamp: 3),
            runFocusCredits: Balance.initialPrestigeTarget,
            lifetimeFocusCredits: 64,
            bonusDepthMeters: 60,
            dailyGoalMinutes: 100,
            streakDays: 7
        )
        let fixture = makeFixture(player: player)
        let commandID = UUID()

        let result = try fixture.store.confirmPrestige(commandID: commandID)
        let replay = try fixture.store.confirmPrestige(commandID: commandID)

        guard case let .prestiged(preview, newIndex) = result else {
            return XCTFail("Expected prestige success")
        }
        XCTAssertEqual(preview.losses.ore, 700)
        XCTAssertEqual(newIndex, 1)
        XCTAssertEqual(replay, .duplicate)
        XCTAssertEqual(fixture.repository.player.resources.ore, 0)
        // 2 existing + floor(40 run credits / 10)
        XCTAssertEqual(fixture.repository.player.resources.coreShards, 6)
        // Prestige now evaluates achievements, and this fixture already satisfies
        // several of them, so the first evaluation pays them out retroactively.
        XCTAssertEqual(fixture.repository.player.resources.crystals, 16)
        XCTAssertTrue(
            fixture.repository.player.earnedAchievementIDs.contains("first.prestige")
        )
        XCTAssertEqual(fixture.repository.player.equipment, EquipmentLevels())
        XCTAssertEqual(fixture.repository.player.runFocusCredits, 0)
        // Depth is lifetime now, so the abyss bonus survives prestige.
        XCTAssertEqual(fixture.repository.player.bonusDepthMeters, 60)
        XCTAssertEqual(fixture.repository.player.lifetimeFocusCredits, 64)
        XCTAssertEqual(fixture.repository.player.streakDays, 7)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testPermanentUpgradeInsufficientMaximumAndReplayDoNotOverSpend() throws {
        let insufficient = makeFixture()
        XCTAssertEqual(
            try insufficient.store.purchasePermanentUpgrade(.excavationMemory, commandID: UUID()),
            .insufficientShards(required: 1, available: 0)
        )
        XCTAssertEqual(insufficient.repository.playerSaveAttempts, 0)

        let maximum = makeFixture(player: PlayerState(
            resources: Resources(coreShards: 20),
            permanentResonanceLevel: Balance.maximumPermanentUpgradeLevel
        ))
        XCTAssertEqual(
            try maximum.store.purchasePermanentUpgrade(.resonanceDetection, commandID: UUID()),
            .maximumLevel
        )
        XCTAssertEqual(maximum.repository.playerSaveAttempts, 0)

        let replay = makeFixture(player: PlayerState(resources: Resources(coreShards: 3)))
        let commandID = UUID()
        XCTAssertEqual(
            try replay.store.purchasePermanentUpgrade(.excavationMemory, commandID: commandID),
            .purchased(upgrade: .excavationMemory, newLevel: 1, cost: 1)
        )
        XCTAssertEqual(
            try replay.store.purchasePermanentUpgrade(.excavationMemory, commandID: commandID),
            .duplicate
        )
        XCTAssertEqual(replay.repository.player.resources.coreShards, 2)
        XCTAssertEqual(replay.repository.player.excavationMemoryLevel, 1)
        XCTAssertEqual(replay.repository.playerSaveAttempts, 1)
    }

    func testStorageFailureLeavesPrestigeUnpersisted() throws {
        let player = PlayerState(
            resources: Resources(ore: 700),
            runFocusCredits: Balance.initialPrestigeTarget
        )
        let fixture = makeFixture(player: player)
        fixture.repository.failPlayerSave = true

        XCTAssertThrowsError(try fixture.store.confirmPrestige(commandID: UUID()))
        XCTAssertEqual(fixture.repository.player, player)
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testThemePresentationUsesCanonicalDepthThresholdsAndPersistedUnlocks() throws {
        let fixture = makeFixture(player: PlayerState(
            unlockedThemes: [.entry, .crystal],
            selectedTheme: .crystal
        ))

        let options = try fixture.store.themePresentations()

        XCTAssertEqual(options.map(\.theme), MineTheme.allCases)
        XCTAssertEqual(options.map(\.unlockDepthMeters), [0, 120, 480, 1_200])
        XCTAssertEqual(options.map(\.isUnlocked), [true, true, false, false])
        XCTAssertEqual(options.map(\.isSelected), [false, true, false, false])
    }

    func testThemePresentationReconcilesReachedDepthOnceForExistingPlayers() throws {
        let fixture = makeFixture(player: PlayerState(
            bonusDepthMeters: Balance.ruinsRegionDepth,
            unlockedThemes: [.entry]
        ))

        let first = try fixture.store.themePresentations()
        let second = try fixture.store.themePresentations()

        XCTAssertEqual(first.map(\.isUnlocked), [true, true, true, false])
        XCTAssertEqual(second, first)
        XCTAssertEqual(fixture.repository.player.unlockedThemes, [.entry, .crystal, .ruins])
        XCTAssertEqual(fixture.repository.playerSaveAttempts, 1)
    }

    func testPermanentUpgradePresentationExposesCostLevelsAndAffordability() throws {
        let fixture = makeFixture(player: PlayerState(
            resources: Resources(coreShards: 2),
            permanentResonanceLevel: 2,
            excavationMemoryLevel: 1,
            compressedTimeLevel: Balance.maximumPermanentUpgradeLevel
        ))

        let options = try fixture.store.permanentUpgradePresentations()

        XCTAssertEqual(options.map(\.upgrade), PermanentUpgradeKind.allCases)
        XCTAssertEqual(options.map(\.currentLevel), [1, 2, 10])
        XCTAssertEqual(options.map(\.nextCost), [2, 3, nil])
        XCTAssertEqual(options.map(\.canAfford), [true, false, false])
        XCTAssertEqual(options.map(\.isMaximum), [false, false, true])
    }

    private func makeFixture(player: PlayerState = PlayerState()) -> GameStoreFixture {
        let repository = FakeSessionRepository()
        repository.player = player
        let system = FakeSystemCoordinator()
        let clock = FakeClock()
        return GameStoreFixture(
            repository: repository,
            system: system,
            clock: clock,
            store: GameStore(repository: repository, coordinator: system, clock: clock)
        )
    }
}
