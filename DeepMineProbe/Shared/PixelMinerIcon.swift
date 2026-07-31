import SwiftUI

enum GameArtName {
    static func miner(planID: String) -> String {
        switch planID {
        case "deep": "MinerPlan_deep"
        case "survey": "MinerPlan_survey"
        default: "MinerSprite"
        }
    }

    static func vein(_ veinID: String?) -> String {
        switch veinID {
        case "blue": "Vein_blue"
        case "crystal": "Vein_crystal"
        case "vault": "Vein_vault"
        case "resonance": "Vein_resonance"
        case "abyss": "Vein_abyss"
        default: "VeinSprite"
        }
    }

    static func region(_ regionID: String, prefix: String) -> String {
        let region = switch regionID {
        case "crystal", "ruins", "abyss": regionID
        default: "entry"
        }
        return "\(prefix)_\(region)"
    }
}

struct PixelMinerIcon: View {
    var size: CGFloat = 24
    var planID = "safe"

    var body: some View {
        Image(GameArtName.miner(planID: planID))
            .resizable()
            .interpolation(.none)
            .antialiased(false)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

private struct PixelSurfaceIcon: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .antialiased(false)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct GameSurfaceMark: View {
    let phase: GameSurfacePhase
    var size: CGFloat = 24
    var planID = "safe"
    var veinID: String?

    var body: some View {
        Group {
            switch phase {
            case .mining:
                PixelMinerIcon(size: size, planID: planID)
            case .completed:
                PixelSurfaceIcon(name: "CompletedSprite", size: size)
            case .vein:
                PixelSurfaceIcon(name: GameArtName.vein(veinID), size: size)
            case .collapsed:
                PixelSurfaceIcon(name: "CollapsedSprite", size: size)
            case .waiting:
                PixelMinerIcon(size: size, planID: planID)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
