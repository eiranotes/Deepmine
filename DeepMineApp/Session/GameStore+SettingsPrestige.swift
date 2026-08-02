import DeepMineCore
import Foundation

struct ThemePresentation: Equatable, Sendable {
    let theme: MineTheme
    let unlockDepthMeters: Int
    let crystalCost: Int
    let canAfford: Bool
    let isUnlocked: Bool
    let isSelected: Bool
}

struct PermanentUpgradePresentation: Equatable, Sendable {
    let upgrade: PermanentUpgradeKind
    let currentLevel: Int
    let nextCost: Int?
    let canAfford: Bool
    let isMaximum: Bool
}

@MainActor
extension GameStore {
    func themePresentations() throws -> [ThemePresentation] {
        var player = try repository.loadPlayer()
        if !WorldProgression.unlockThemesForCurrentDepth(in: &player).isEmpty {
            try repository.savePlayer(player)
        }
        return Self.themePresentations(for: player)
    }

    func permanentUpgradePresentations() throws -> [PermanentUpgradePresentation] {
        Self.permanentUpgradePresentations(for: try repository.loadPlayer())
    }

    static func themePresentations(for player: PlayerState) -> [ThemePresentation] {
        MineTheme.allCases.map { theme in
            let cost = WorldProgression.crystalCost(for: theme)
            return ThemePresentation(
                theme: theme,
                unlockDepthMeters: unlockDepth(for: theme),
                crystalCost: cost,
                canAfford: player.resources.crystals >= cost,
                isUnlocked: player.unlockedThemes.contains(theme),
                isSelected: player.selectedTheme == theme
            )
        }
    }

    static func permanentUpgradePresentations(
        for player: PlayerState
    ) -> [PermanentUpgradePresentation] {
        PermanentUpgradeKind.allCases.map { upgrade in
            let level = permanentLevel(for: upgrade, in: player)
            let maximum = level >= Balance.maximumPermanentUpgradeLevel
            let cost = maximum ? nil : level + 1
            return PermanentUpgradePresentation(
                upgrade: upgrade,
                currentLevel: level,
                nextCost: cost,
                canAfford: cost.map { player.resources.coreShards >= $0 } ?? false,
                isMaximum: maximum
            )
        }
    }

    @discardableResult
    func selectTheme(_ theme: MineTheme) throws -> ThemeSelectionResult {
        var player = try repository.loadPlayer()
        let result = WorldProgression.selectTheme(theme, in: &player)
        if result == .selected { try repository.savePlayer(player) }
        return result
    }

    @discardableResult
    func purchaseTheme(
        _ theme: MineTheme,
        commandID: UUID = UUID()
    ) throws -> ThemePurchaseResult {
        var player = try repository.loadPlayer()
        let result = WorldProgression.purchaseTheme(
            ThemePurchaseCommand(id: commandID, theme: theme),
            in: &player
        )
        if case .purchased = result { try repository.savePlayer(player) }
        return result
    }

    func prestigePreview() throws -> PrestigePreview {
        PrestigeEngine.preview(for: try repository.loadPlayer())
    }

    @discardableResult
    func confirmPrestige(commandID: UUID) throws -> PrestigeResult {
        var player = try repository.loadPlayer()
        let result = PrestigeEngine.prestige(PrestigeCommand(id: commandID), in: &player)
        if case .prestiged = result {
            AchievementEngine.evaluate(in: &player)
            try repository.savePlayer(player)
        }
        return result
    }

    @discardableResult
    func purchasePermanentUpgrade(
        _ upgrade: PermanentUpgradeKind,
        commandID: UUID
    ) throws -> PermanentUpgradePurchaseResult {
        var player = try repository.loadPlayer()
        let result = PrestigeEngine.purchase(
            PermanentUpgradeCommand(id: commandID, upgrade: upgrade),
            in: &player
        )
        if case .purchased = result { try repository.savePlayer(player) }
        return result
    }

    private static func unlockDepth(for theme: MineTheme) -> Int {
        switch theme {
        case .entry: 0
        case .crystal: Balance.crystalRegionDepth
        case .ruins: Balance.ruinsRegionDepth
        case .abyss: Balance.abyssRegionDepth
        }
    }

    private static func permanentLevel(
        for upgrade: PermanentUpgradeKind,
        in player: PlayerState
    ) -> Int {
        switch upgrade {
        case .excavationMemory: player.excavationMemoryLevel
        case .resonanceDetection: player.permanentResonanceLevel
        case .compressedTime: player.compressedTimeLevel
        }
    }
}
