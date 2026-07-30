import SwiftUI

struct PixelMinerIcon: View {
    var size: CGFloat = 24

    var body: some View {
        Image("MinerSprite")
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

    var body: some View {
        Group {
            switch phase {
            case .mining:
                PixelMinerIcon(size: size)
            case .completed:
                PixelSurfaceIcon(name: "CompletedSprite", size: size)
            case .vein:
                PixelSurfaceIcon(name: "VeinSprite", size: size)
            case .collapsed:
                PixelSurfaceIcon(name: "CollapsedSprite", size: size)
            case .waiting:
                PixelMinerIcon(size: size)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
