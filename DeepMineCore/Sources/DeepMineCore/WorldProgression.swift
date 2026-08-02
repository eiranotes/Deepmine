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
    case bonusOre(Double)
    case duplicate
}

public enum ThemeSelectionResult: String, Codable, Equatable, Sendable {
    case selected
    case unchanged
    case locked
}

public struct ThemePurchaseCommand: Codable, Equatable, Sendable {
    public let id: UUID
    public let theme: MineTheme

    public init(id: UUID, theme: MineTheme) {
        self.id = id
        self.theme = theme
    }
}

public enum ThemePurchaseResult: Codable, Equatable, Sendable {
    case purchased(theme: MineTheme, cost: Int)
    case insufficientCrystals(required: Int, available: Int)
    case alreadyUnlocked
    case duplicate
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

    public static func crystalCost(for theme: MineTheme) -> Int {
        switch theme {
        case .entry: 0
        case .crystal: 3
        case .ruins: 6
        case .abyss: 10
        }
    }

    @discardableResult
    public static func purchaseTheme(
        _ command: ThemePurchaseCommand,
        in state: inout PlayerState
    ) -> ThemePurchaseResult {
        guard !state.appliedPurchaseIDs.contains(command.id) else { return .duplicate }
        guard !state.unlockedThemes.contains(command.theme) else { return .alreadyUnlocked }
        let cost = crystalCost(for: command.theme)
        guard state.resources.crystals >= cost else {
            return .insufficientCrystals(
                required: cost,
                available: state.resources.crystals
            )
        }
        state.resources.crystals -= cost
        state.unlockedThemes.insert(command.theme)
        state.selectedTheme = command.theme
        state.appliedPurchaseIDs.insert(command.id)
        return .purchased(theme: command.theme, cost: cost)
    }

    @discardableResult
    public static func unlockThemesForCurrentDepth(in state: inout PlayerState) -> Set<MineTheme> {
        let before = state.unlockedThemes
        let depth = state.recordDepthMeters
        if depth >= Balance.crystalRegionDepth { state.unlockedThemes.insert(.crystal) }
        if depth >= Balance.ruinsRegionDepth { state.unlockedThemes.insert(.ruins) }
        if depth >= Balance.abyssRegionDepth { state.unlockedThemes.insert(.abyss) }
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
            let quantity = Balance.abyssVeinCrystals
            state.resources.crystals = saturatingAdd(state.resources.crystals, quantity)
            return .crystals(quantity)
        }
    }

    static func skippedSegmentOre(from segmentIndex: Int) -> Double {
        let segments = max(1, Balance.abyssBonusDepthMeters / Balance.metersPerSegment)
        var total = BigNumber.zero
        for offset in 0..<segments {
            total += RockGenerator.segment(at: max(0, segmentIndex) + offset).oreYield
        }
        let value = total.doubleValue
        return value.isFinite && value > 0 ? value : 0
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
