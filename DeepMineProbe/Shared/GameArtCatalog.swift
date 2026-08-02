import Foundation

/// Every image the clicker needs but does not have yet, in one place.
///
/// The swap contract: an entry renders a procedural placeholder until an imageset with
/// the matching `name` exists in an asset catalog, and renders the real art the moment
/// one does. Shipping a finished asset requires no code change — drop the imageset in,
/// and the placeholder disappears on next launch.
enum GameArtCatalog {
    static let promptDocumentPath = "docs/ROCK_ART_PROMPTS.md"
    static let shaftPromptDocumentPath = "docs/SHAFT_ART_PROMPTS.md"
    static let prestigeMemoryRingName = "PrestigeMemoryRing"

    static func refinementBadgeName(kind: String) -> String {
        switch kind {
        case "cart", "lamp": "RefinementBadge_\(kind)"
        default: "RefinementBadge_drill"
        }
    }

    static func rockFace(region: String, stage: Int) -> GameArtEntry {
        let safeRegion = normalizedRegion(region)
        let safeStage = min(4, max(1, stage))
        return GameArtEntry(
            name: "RockFace_\(safeRegion)_stage\(safeStage)",
            promptID: "rockface-\(safeRegion)-\(safeStage)",
            placeholder: .rockFace(region: safeRegion, stage: safeStage)
        )
    }

    static func fracture(intensity: FractureIntensity) -> GameArtEntry {
        GameArtEntry(
            name: "Fracture_\(intensity.rawValue)",
            promptID: "fracture-\(intensity.rawValue)",
            placeholder: .fracture(intensity: intensity)
        )
    }

    static func weakPoint(isStruck: Bool) -> GameArtEntry {
        let state = isStruck ? "hit" : "idle"
        return GameArtEntry(
            name: "WeakPoint_\(state)",
            promptID: "weakpoint-\(state)",
            placeholder: .weakPoint(isStruck: isStruck)
        )
    }

    static func debris(isLarge: Bool) -> GameArtEntry {
        let size = isLarge ? "large" : "small"
        return GameArtEntry(
            name: "Debris_\(size)",
            promptID: "debris-\(size)",
            placeholder: .debris(isLarge: isLarge)
        )
    }

    static let resonanceNode = GameArtEntry(
        name: "ResonanceNode",
        promptID: "resonance-node",
        placeholder: .resonanceNode
    )

    static let shaftGantry = GameArtEntry(
        name: "ShaftGantry",
        promptID: "shaft-gantry",
        placeholder: .shaftGantry
    )

    static let seamVein = GameArtEntry(
        name: "SeamVein",
        promptID: "seam-vein",
        placeholder: .seamVein
    )

    static func shaftRock(region: String) -> GameArtEntry {
        shaftRock(region: region, depthMeters: 0)
    }

    /// Economic regions still determine ore and unlocks. At extreme depth the art gains
    /// additional geological generations so the abyss does not repeat for hundreds of km.
    static func shaftRock(region: String, depthMeters: Double) -> GameArtEntry {
        let fallback = normalizedRegion(region)
        let visual = deepGeologyKey(depthMeters: depthMeters) ?? fallback
        return GameArtEntry(
            name: "ShaftRock_\(visual)",
            promptID: "shaft-rock-\(visual)",
            placeholder: .shaftRock(region: fallback)
        )
    }

    static let shaftSurface = GameArtEntry(
        name: "ShaftSurface",
        promptID: "shaft-surface",
        placeholder: .shaftSurface
    )

    static let miningPickaxe = GameArtEntry(
        name: "MiningPickaxe",
        promptID: "mining-pickaxe",
        placeholder: .miningPickaxe
    )

    static func shaftFracture(intensity: FractureIntensity) -> GameArtEntry {
        GameArtEntry(
            name: "ShaftFractureVertical_\(intensity.rawValue)",
            promptID: "shaft-fracture-vertical-\(intensity.rawValue)",
            placeholder: .shaftFracture(intensity: intensity)
        )
    }

    static let shaftFrontierLip = GameArtEntry(
        name: "ShaftFrontierLip",
        promptID: "shaft-frontier-lip",
        placeholder: .shaftFrontierLip
    )

    static let minerMiningStrip = GameArtEntry(
        name: "MinerMiningStrip",
        promptID: "miner-mining-strip",
        placeholder: .minerMiningStrip
    )

    static let minerMiningFrameCount = 4

    static var allEntries: [GameArtEntry] {
        var entries: [GameArtEntry] = []
        for region in ["entry", "crystal", "ruins", "abyss"] {
            for stage in 1...4 {
                entries.append(rockFace(region: region, stage: stage))
            }
        }
        entries.append(contentsOf: FractureIntensity.allCases.map(fracture(intensity:)))
        entries.append(weakPoint(isStruck: false))
        entries.append(weakPoint(isStruck: true))
        entries.append(debris(isLarge: false))
        entries.append(debris(isLarge: true))
        entries.append(resonanceNode)
        return entries
    }

    static let shaftEntries = [
        shaftGantry,
        seamVein,
        shaftRock(region: "entry"),
        shaftRock(region: "crystal"),
        shaftRock(region: "ruins"),
        shaftRock(region: "abyss"),
        shaftRock(region: "abyss", depthMeters: 5_000),
        shaftRock(region: "abyss", depthMeters: 20_000),
        shaftRock(region: "abyss", depthMeters: 100_000),
        shaftSurface,
        miningPickaxe,
        shaftFracture(intensity: .light),
        shaftFracture(intensity: .medium),
        shaftFracture(intensity: .heavy),
        shaftFrontierLip,
        minerMiningStrip,
    ]

    static var installedEntries: [GameArtEntry] {
        allEntries + shaftEntries
    }

    private static func deepGeologyKey(depthMeters: Double) -> String? {
        switch max(0, depthMeters) {
        case 100_000...: "core"
        case 20_000...: "fault"
        case 5_000...: "pressure"
        default: nil
        }
    }

    private static func normalizedRegion(_ region: String) -> String {
        switch region {
        case "crystal", "ruins", "abyss": region
        default: "entry"
        }
    }
}

enum FractureIntensity: String, CaseIterable, Sendable {
    case light
    case medium
    case heavy
}

struct GameArtEntry: Equatable, Sendable {
    let name: String
    let promptID: String
    let placeholder: GameArtPlaceholder
}

enum GameArtPlaceholder: Equatable, Sendable {
    case rockFace(region: String, stage: Int)
    case fracture(intensity: FractureIntensity)
    case weakPoint(isStruck: Bool)
    case debris(isLarge: Bool)
    case resonanceNode
    case shaftGantry
    case seamVein
    case shaftRock(region: String)
    case shaftSurface
    case miningPickaxe
    case shaftFracture(intensity: FractureIntensity)
    case shaftFrontierLip
    case minerMiningStrip
}
