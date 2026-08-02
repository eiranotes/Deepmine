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
    /// Ore equal to the segments an abyss vein used to skip.
    case bonusOre(Double)
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
        // The record, not the current position: a region opened before a prestige stays
        // open after it (D-046).
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
            // Used to skip 60m of intact rock. That handed depth to whoever ran the most
            // sessions while paying no ore for the skipped segments — and the segments
            // stayed unpaid forever, so the richest vein in the game was a long-run loss.
            // A heavy persona took ~108 of these over 180 days: 6,480m of its 7,408m was
            // skipped rather than dug, which is why its depth led every persona while its
            // ore trailed all of them.
            //
            // Depth is earned by breaking rock (D-045). The vein now pays what those
            // segments would have paid, so it is a large reward that does not bypass the
            // economy it belongs to.
            // Paying the skipped segments' ore instead was worse: that reward scales
            // exponentially with depth, so six sessions a day collected six times an
            // exponent and the heavy persona ran away from every other one (4.2e11x at
            // 180 days). A session reward must not scale with the rock, or focus stops
            // being an amplifier and becomes the economy (D-037).
            //
            // Crystals do not compound. They buy refinement, which is exactly the axis a
            // deep player wants next, and the reward stays legible at every depth.
            let quantity = Balance.abyssVeinCrystals
            state.resources.crystals = saturatingAdd(state.resources.crystals, quantity)
            return .crystals(quantity)
        }
    }

    /// Ore the next `abyssBonusDepthMeters` of rock would have paid, at the player's
    /// current position. Scales with depth exactly as digging it would.
    static func skippedSegmentOre(from segmentIndex: Int) -> Double {
        let segments = max(1, Balance.abyssBonusDepthMeters / Balance.metersPerSegment)
        var total = BigNumber.zero
        for offset in 0..<segments {
            total += RockGenerator.segment(at: max(0, segmentIndex) + offset).oreYield
        }
        let value = total.doubleValue
        return value.isFinite && value > 0 ? value : 0
    }

    private static func saturatingOre(_ current: Double, adding gained: Double) -> Double {
        guard gained.isFinite, gained > 0 else { return current }
        return current <= Double.greatestFiniteMagnitude - gained
            ? current + gained
            : Double.greatestFiniteMagnitude
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
