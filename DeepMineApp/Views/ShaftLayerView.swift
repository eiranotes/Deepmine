import DeepMineCore
import SwiftUI

/// Continuous geology, the permanent passage cut through it, and the work rig at the
/// head. Four-metre segments exist only in the economy; no view here draws a row per
/// segment.
struct ShaftGeologyView: View {
    let scene: ShaftScene
    let player: PlayerState
    let isStruck: Bool
    let onStrike: (Bool) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                geology(width: proxy.size.width)
                passedBore(width: proxy.size.width)
                currentBore(width: proxy.size.width)
                installations(width: proxy.size.width)
                futureDarkness
                ShaftWorkingLightView(scene: scene, width: proxy.size.width)
                currentFace(width: proxy.size.width)
                depthRecordPlate(width: proxy.size.width)
            }
            .contentShape(Rectangle())
            .onTapGesture { onStrike(false) }
            .accessibilityIdentifier("rock-face")
            .accessibilityLabel(
                Text("\(DeepMineStrings.text(.gameDepth)) \(player.depthMeters)m")
            )
            .accessibilityAddTraits(.isButton)
        }
    }

    private func geology(width: CGFloat) -> some View {
        ForEach(scene.strata) { stratum in
            GeometryReader { proxy in
                GameArtView(
                    entry: GameArtCatalog.shaftRock(region: stratum.region.rawValue),
                    fill: proxy.size
                )
                .overlay {
                    LinearGradient(
                        colors: [
                            DeepMinePalette.limestone.color.opacity(0.05),
                            DeepMinePalette.coal.color.opacity(0.16)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .frame(
                width: width,
                height: ShaftGeometry.height(
                    from: stratum.startDepthMeters,
                    to: stratum.endDepthMeters
                )
            )
            .offset(y: ShaftGeometry.y(for: stratum.startDepthMeters, in: scene))
            .accessibilityHidden(true)
        }
    }

    private func passedBore(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(scene.boreHistory) { record in
                let start = Double(record.depthMeters)
                Rectangle()
                    .fill(DeepMinePalette.coal.color)
                    .frame(
                        width: min(width * 0.72, CGFloat(record.boreWidthPoints)),
                        height: ShaftGeometry.height(
                            from: start,
                            to: start + Double(Balance.metersPerSegment)
                        ) + 1
                    )
                    .overlay(alignment: .leading) { cutEdge }
                    .overlay(alignment: .trailing) { cutEdge }
                    .position(
                        x: width / 2,
                        y: ShaftGeometry.y(for: start, in: scene)
                            + ShaftGeometry.height(
                                from: start,
                                to: start + Double(Balance.metersPerSegment)
                            ) / 2
                    )
                if record.segmentIndex.isMultiple(of: 3) {
                    GameArtView(entry: GameArtCatalog.fracture(intensity: .light), size: 52)
                        .opacity(0.42)
                        .position(
                            x: width / 2,
                            y: ShaftGeometry.y(
                                for: start + Double(Balance.metersPerSegment),
                                in: scene
                            )
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func currentBore(width: CGFloat) -> some View {
        let startY = ShaftGeometry.y(for: scene.faceDepthMeters, in: scene)
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        return RoundedRectangle(cornerRadius: 9)
            .fill(DeepMinePalette.coal.color)
            .frame(
                width: min(width * 0.72, CGFloat(scene.currentBoreWidthPoints)),
                height: max(8, headY - startY + 10)
            )
            .overlay(alignment: .leading) { cutEdge }
            .overlay(alignment: .trailing) { cutEdge }
            .position(
                x: width / 2,
                y: startY + max(8, headY - startY + 10) / 2
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var cutEdge: some View {
        Rectangle()
            .fill(DeepMinePalette.limestone.color.opacity(0.14))
            .frame(width: 2)
    }

    private func installations(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if player.equipment.cart > Balance.minimumEquipmentLevel {
                rail(width: width)
                ShaftCartTrafficView(
                    scene: scene,
                    level: player.equipment.cart,
                    modification: player.equipmentModifications.cart,
                    width: width
                )
            }
            ForEach(scene.boreHistory.filter {
                $0.cartLevel > Balance.minimumEquipmentLevel
                    && $0.segmentIndex.isMultiple(of: 8)
            }) { record in
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.cart, level: record.cartLevel),
                    size: 34
                )
                .position(
                    x: width / 2,
                    y: ShaftGeometry.y(
                        for: Double(record.depthMeters) + 2,
                        in: scene
                    )
                )
            }
            ForEach(scene.boreHistory.filter {
                $0.lampLevel > Balance.minimumEquipmentLevel
                    && $0.segmentIndex.isMultiple(of: 5)
            }) { record in
                let boreHalf = min(width * 0.34, CGFloat(record.boreWidthPoints) / 2)
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.lamp, level: record.lampLevel),
                    size: 24
                )
                .position(
                    x: width / 2 + boreHalf - 9,
                    y: ShaftGeometry.y(
                        for: Double(record.depthMeters) + 1,
                        in: scene
                    )
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func rail(width: CGFloat) -> some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        return HStack(spacing: 34) {
            Rectangle().fill(DeepMinePalette.brass.color.opacity(0.48)).frame(width: 2)
            Rectangle().fill(DeepMinePalette.brass.color.opacity(0.48)).frame(width: 2)
        }
        .frame(width: 40, height: max(0, headY))
        .overlay {
            VStack(spacing: 12) {
                ForEach(0..<max(1, Int(headY / 12)), id: \.self) { _ in
                    Rectangle()
                        .fill(DeepMinePalette.brass.color.opacity(0.3))
                        .frame(width: 38, height: 1)
                }
            }
        }
        .position(x: width / 2, y: headY / 2)
    }

    private var futureDarkness: some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        return LinearGradient(
            colors: [.clear, DeepMinePalette.coal.color.opacity(0.94)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: max(0, ShaftGeometry.columnHeight(for: scene) - headY))
        .offset(y: headY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func currentFace(width: CGFloat) -> some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        return ZStack {
            GameArtView(
                entry: GameArtCatalog.fracture(intensity: fractureIntensity),
                size: 98 + CGFloat(player.mineFace.brokenFraction * 42)
            )
            .opacity(0.92)
            GameArtView(entry: GameArtCatalog.shaftGantry, size: 94)
                .offset(y: -18)
            HStack(spacing: -9) {
                WorkingMinerView(
                    isWorking: true,
                    intensity: min(
                        1,
                        player.mineFace.impact.fraction
                            + (player.equipmentModifications.drill == .drillImpact ? 0.28 : 0)
                    )
                )
                    .frame(width: 54, height: 54)
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.drill, level: player.equipment.drill),
                    size: 38
                )
            }
            .offset(y: -16)
            DeepMinePixelImage(
                name: DeepMineArt.equipment(.lamp, level: player.equipment.lamp),
                size: 25
            )
            .position(
                x: width / 2 + min(width * 0.31, CGFloat(scene.currentBoreWidthPoints) / 2) - 8,
                y: 35
            )
            if let point = player.mineFace.segment.weakPoint {
                weakPoint(point, width: width)
            }
        }
        .frame(width: width, height: 112)
        .position(x: width / 2, y: headY)
        .allowsHitTesting(true)
    }

    private func weakPoint(_ point: RockSegment.WeakPoint, width: CGFloat) -> some View {
        GameArtView(entry: GameArtCatalog.weakPoint(isStruck: isStruck), size: 36)
            .shadow(
                color: player.equipmentModifications.lamp == .lampFortune
                    ? DeepMinePalette.brass.color.opacity(0.9)
                    : .clear,
                radius: player.equipmentModifications.lamp == .lampFortune ? 11 : 0
            )
            .frame(width: 48, height: 48)
            .position(
                x: width * point.unitX,
                y: 56 + 36 * (point.unitY - 0.5)
            )
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded { onStrike(true) })
            .accessibilityIdentifier("rock-weak-point")
            .accessibilityLabel(DeepMineStrings.text(.shaftWeakPoint))
            .accessibilityAddTraits(.isButton)
    }

    private func depthRecordPlate(width: CGFloat) -> some View {
        let record = Double(player.recordDepthMeters)
        return Group {
            if record >= scene.topDepthMeters && record <= scene.bottomDepthMeters {
                Text("RECORD · \(player.recordDepthMeters)m")
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(DeepMinePalette.coal.color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(DeepMinePalette.brass.color, in: Capsule())
                    .position(
                        x: width - 62,
                        y: ShaftGeometry.y(for: record, in: scene)
                    )
                    .accessibilityIdentifier("shaft-record-plate")
            }
        }
    }

    private var fractureIntensity: FractureIntensity {
        switch player.mineFace.damageStage {
        case ...1: .light
        case 2: .medium
        default: .heavy
        }
    }
}
