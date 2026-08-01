import SwiftUI

/// Stand-in art drawn from shapes, in the same four pigments as the finished assets.
///
/// These are meant to be replaced, not shipped. They exist so the clicker loop can be
/// built, played and screenshotted before any image is generated — and so a missing asset
/// reads as "not drawn yet" rather than as a rendering bug.
struct GameArtPlaceholderView: View {
    let placeholder: GameArtPlaceholder

    var body: some View {
        switch placeholder {
        case let .rockFace(region, stage):
            RockFacePlaceholder(region: region, stage: stage)
        case let .fracture(intensity):
            FracturePlaceholder(intensity: intensity)
        case let .weakPoint(isStruck):
            WeakPointPlaceholder(isStruck: isStruck)
        case let .debris(isLarge):
            DebrisPlaceholder(isLarge: isLarge)
        case .resonanceNode:
            ResonanceNodePlaceholder()
        case .shaftGantry:
            ShaftGantryPlaceholder()
        case .seamVein:
            SeamVeinPlaceholder()
        case let .shaftRock(region):
            ShaftRockPlaceholder(region: region)
        case .shaftSurface:
            ShaftSurfacePlaceholder()
        }
    }
}

private struct RockFacePlaceholder: View {
    let region: String
    let stage: Int

    /// Regions differ only in fill so the four layers are distinguishable at a glance
    /// while remaining obviously provisional.
    private var fill: Color {
        switch region {
        case "crystal": ProbePalette.shale
        case "ruins": ProbePalette.brass.opacity(0.55)
        case "abyss": ProbePalette.coal
        default: ProbePalette.shale.opacity(0.8)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: side * 0.12)
                    .fill(fill)
                RoundedRectangle(cornerRadius: side * 0.12)
                    .strokeBorder(ProbePalette.limestone.opacity(0.5), lineWidth: side * 0.03)

                // Damage reads as chunks missing from the silhouette, which is how the
                // real stages will read too.
                ForEach(0..<max(0, stage - 1), id: \.self) { index in
                    Circle()
                        .fill(ProbePalette.coal.opacity(0.85))
                        .frame(width: side * 0.22, height: side * 0.22)
                        .offset(
                            x: side * (index == 1 ? 0.22 : -0.2),
                            y: side * (index == 2 ? 0.24 : -0.18)
                        )
                }

                Text("\(stage)")
                    .font(.system(size: side * 0.2, weight: .bold, design: .monospaced))
                    .foregroundStyle(ProbePalette.limestone.opacity(0.7))
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct FracturePlaceholder: View {
    let intensity: FractureIntensity

    private var strokeCount: Int {
        switch intensity {
        case .light: 1
        case .medium: 3
        case .heavy: 5
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                ForEach(0..<strokeCount, id: \.self) { index in
                    Path { path in
                        let offset = side * (0.16 * Double(index) - 0.16)
                        path.move(to: CGPoint(x: side * 0.5 + offset, y: 0))
                        path.addLine(to: CGPoint(x: side * 0.38 + offset, y: side * 0.45))
                        path.addLine(to: CGPoint(x: side * 0.58 + offset, y: side * 0.6))
                        path.addLine(to: CGPoint(x: side * 0.44 + offset, y: side))
                    }
                    .stroke(ProbePalette.coal, lineWidth: side * 0.035)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WeakPointPlaceholder: View {
    let isStruck: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .strokeBorder(ProbePalette.brass, lineWidth: side * 0.1)
                if isStruck {
                    Circle()
                        .fill(ProbePalette.brass)
                        .frame(width: side * 0.45, height: side * 0.45)
                } else {
                    Circle()
                        .fill(ProbePalette.brass.opacity(0.35))
                        .frame(width: side * 0.28, height: side * 0.28)
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct DebrisPlaceholder: View {
    let isLarge: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let chip = side * (isLarge ? 0.42 : 0.24)
            ZStack {
                RoundedRectangle(cornerRadius: chip * 0.2)
                    .fill(ProbePalette.shale)
                    .frame(width: chip, height: chip)
                    .rotationEffect(.degrees(18))
                RoundedRectangle(cornerRadius: chip * 0.2)
                    .fill(ProbePalette.coal)
                    .frame(width: chip * 0.6, height: chip * 0.6)
                    .offset(x: chip * 0.4, y: chip * 0.35)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ResonanceNodePlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            ZStack {
                Circle()
                    .fill(ProbePalette.brass)
                    .frame(width: side * 0.55, height: side * 0.55)
                Circle()
                    .strokeBorder(ProbePalette.limestone, lineWidth: side * 0.045)
                    .frame(width: side * 0.85, height: side * 0.85)
                Circle()
                    .strokeBorder(ProbePalette.brass.opacity(0.5), lineWidth: side * 0.03)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct ShaftGantryPlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HStack {
                    Rectangle().fill(ProbePalette.shale).frame(width: proxy.size.width * 0.08)
                    Spacer()
                    Rectangle().fill(ProbePalette.shale).frame(width: proxy.size.width * 0.08)
                }
                VStack {
                    Rectangle().fill(ProbePalette.shale).frame(height: proxy.size.height * 0.12)
                    Spacer()
                    Rectangle().fill(ProbePalette.brass).frame(height: proxy.size.height * 0.04)
                }
            }
        }
    }
}

private struct SeamVeinPlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: proxy.size.height * 0.55))
                path.addLine(to: CGPoint(x: proxy.size.width * 0.28, y: proxy.size.height * 0.42))
                path.addLine(to: CGPoint(x: proxy.size.width * 0.56, y: proxy.size.height * 0.60))
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height * 0.44))
            }
            .stroke(ProbePalette.limestone, lineWidth: max(2, proxy.size.height * 0.08))
        }
    }
}

private struct ShaftRockPlaceholder: View {
    let region: String

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ProbePalette.shale
                ForEach(0..<5, id: \.self) { row in
                    Path { path in
                        let y = proxy.size.height * (0.12 + Double(row) * 0.2)
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: proxy.size.width * 0.32, y: y - 3))
                        path.addLine(to: CGPoint(x: proxy.size.width * 0.66, y: y + 2))
                        path.addLine(to: CGPoint(x: proxy.size.width, y: y - 1))
                    }
                    .stroke(row.isMultiple(of: 2) ? ProbePalette.coal : accent, lineWidth: 2)
                }
            }
        }
    }

    private var accent: Color {
        switch region {
        case "crystal": ProbePalette.limestone
        case "ruins": ProbePalette.brass.opacity(0.55)
        case "abyss": ProbePalette.coal
        default: ProbePalette.limestone.opacity(0.35)
        }
    }
}

private struct ShaftSurfacePlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(ProbePalette.shale)
                    .frame(height: max(5, proxy.size.height * 0.14))
                HStack {
                    Rectangle().fill(ProbePalette.shale).frame(width: 8)
                    Spacer()
                    Rectangle().fill(ProbePalette.shale).frame(width: 8)
                }
            }
        }
    }
}
