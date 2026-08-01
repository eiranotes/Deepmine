import Foundation

/// Every image the clicker needs but does not have yet, in one place.
///
/// The swap contract: an entry renders a procedural placeholder until an imageset with
/// the matching `name` exists in an asset catalog, and renders the real art the moment
/// one does. Shipping a finished asset requires no code change — drop the imageset in,
/// and the placeholder disappears on next launch.
///
/// `promptID` is the heading under which the generation prompt lives in
/// `docs/ROCK_ART_PROMPTS.md`. It is the link between an unfilled slot and the text that
/// fills it, which is why it lives in code instead of only in the document.
enum GameArtCatalog {
    static let promptDocumentPath = "docs/ROCK_ART_PROMPTS.md"
    static let shaftPromptDocumentPath = "docs/SHAFT_ART_PROMPTS.md"

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
        let safeRegion = normalizedRegion(region)
        return GameArtEntry(
            name: "ShaftRock_\(safeRegion)",
            promptID: "shaft-rock-\(safeRegion)",
            placeholder: .shaftRock(region: safeRegion)
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

    /// The full slot list, used by the audit test that keeps this registry and the prompt
    /// document from drifting apart.
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
        shaftSurface,
        miningPickaxe,
        shaftFracture(intensity: .light),
        shaftFracture(intensity: .medium),
        shaftFracture(intensity: .heavy),
    ]

    static var installedEntries: [GameArtEntry] {
        allEntries + shaftEntries
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

/// What to draw when the real image is absent. Deliberately drawn in the same four pigments
/// as the finished art, so an unfinished screen still reads as the same game rather than
/// as a broken one.
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
}
