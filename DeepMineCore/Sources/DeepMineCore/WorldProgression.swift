import Foundation

public enum MineRegion: String, Codable, CaseIterable, Sendable {
    case entry
    case crystal
    case ruins
    case abyss

    public var index: Int {
        switch self {
        case .entry: 0
        case .crystal: 1
        case .ruins: 2
        case .abyss: 3
        }
    }
}

public enum MineTheme: String, Codable, CaseIterable, Hashable, Sendable {
    case entry
    case crystal
    case ruins
    case abyss
}

public enum MineDecoration: String, Codable, CaseIterable, Hashable, Sendable {
    case marker
    case rail
    case lamp
    case cart
}

public enum VeinEffectResult: Codable, Equatable, Sendable {
    case oreMultiplier(Double)
    case crystals(Int)
    case themeUnlocked(MineTheme)
    case decorationUnlocked(MineDecoration)
    case vaultConvertedToCrystals(Int)
    case resonanceArmed
    case bonusDepth(Int)
    case duplicate
}

public enum ThemeSelectionResult: String, Codable, Equatable, Sendable {
    case selected
    case unchanged
    case locked
}

public enum WorldProgression {
    public static func region(forDepth depth: Int) -> MineRegion {
        switch max(0, depth) {
        case Balance.abyssRegionDepth...: return .abyss
        case Balance.ruinsRegionDepth...: return .ruins
        case Balance.crystalRegionDepth...: return .crystal
        default: return .entry
        }
    }

    /// The next region gate below the player, for the "how far to go" promise. Nil once
    /// the deepest region is already open.
    public static func nextRegionThreshold(
        afterDepth depth: Int
    ) -> (region: MineRegion, depth: Int)? {
        let gates: [(MineRegion, Int)] = [
            (.crystal, Balance.crystalRegionDepth),
            (.ruins, Balance.ruinsRegionDepth),
            (.abyss, Balance.abyssRegionDepth)
        ]
        return gates.first { depth < $0.1 }.map { (region: $0.0, depth: $0.1) }
    }

    @discardableResult
    public static func unlockThemesForCurrentDepth(in state: inout PlayerState) -> Set<MineTheme> {
        let before = state.unlockedThemes
        if state.depthMeters >= Balance.crystalRegionDepth { state.unlockedThemes.insert(.crystal) }
        if state.depthMeters >= Balance.ruinsRegionDepth { state.unlockedThemes.insert(.ruins) }
        if state.depthMeters >= Balance.abyssRegionDepth { state.unlockedThemes.insert(.abyss) }
        return state.unlockedThemes.subtracting(before)
    }

    @discardableResult
    public static func apply(
        vein: VeinKind,
        effectID: UUID,
        regionIndex: Int,
        to state: inout PlayerState
    ) -> VeinEffectResult {
        guard state.appliedVeinEffectIDs.insert(effectID).inserted else { return .duplicate }
        switch vein {
        case .blue:
            return .oreMultiplier(Balance.blueVeinRewardMultiplier)
        case .crystal:
            let quantity = Balance.crystalRegionBaseQuantity + max(0, regionIndex)
            state.resources.crystals = saturatingAdd(state.resources.crystals, quantity)
            return .crystals(quantity)
        case .vault:
            return applyVault(to: &state)
        case .resonance:
            state.resonanceBoostPending = true
            return .resonanceArmed
        case .abyss:
            state.bonusDepthMeters = saturatingAdd(
                state.bonusDepthMeters,
                Balance.abyssBonusDepthMeters
            )
            return .bonusDepth(Balance.abyssBonusDepthMeters)
        }
    }

    public static func selectTheme(
        _ theme: MineTheme,
        in state: inout PlayerState
    ) -> ThemeSelectionResult {
        guard state.unlockedThemes.contains(theme) else { return .locked }
        guard state.selectedTheme != theme else { return .unchanged }
        state.selectedTheme = theme
        return .selected
    }

    public static func consumeResonanceBoost(in state: inout PlayerState) -> Bool {
        guard state.resonanceBoostPending else { return false }
        state.resonanceBoostPending = false
        return true
    }

    private static func applyVault(to state: inout PlayerState) -> VeinEffectResult {
        for theme in [MineTheme.crystal, .ruins, .abyss]
        where !state.unlockedThemes.contains(theme) {
            state.unlockedThemes.insert(theme)
            return .themeUnlocked(theme)
        }
        for decoration in [MineDecoration.marker, .rail, .lamp, .cart]
        where !state.unlockedDecorations.contains(decoration) {
            state.unlockedDecorations.insert(decoration)
            return .decorationUnlocked(decoration)
        }
        state.resources.crystals = saturatingAdd(
            state.resources.crystals,
            Balance.vaultCrystalConversionQuantity
        )
        return .vaultConvertedToCrystals(Balance.vaultCrystalConversionQuantity)
    }

    private static func saturatingAdd(_ value: Int, _ addition: Int) -> Int {
        guard value >= 0 else { return addition }
        return value > Int.max - addition ? Int.max : value + addition
    }
}
