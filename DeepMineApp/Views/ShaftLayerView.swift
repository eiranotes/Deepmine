import DeepMineCore
import SwiftUI

/// Continuous geology, the permanent passage cut through it, and the work rig at the
/// head. Four-metre segments exist only in the economy; no view here draws a row per
/// segment.
struct ShaftGeologyView: View {
    let scene: ShaftScene
    let player: PlayerState
    let isStruck: Bool
    let strikeSignal: Int
    let strikeVariant: StrikeVariant
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
            .accessibilityElement(children: .contain)
        }
    }

    private func geology(width: CGFloat) -> some View {
        ForEach(scene.strata) { stratum in
            GeometryReader { proxy in
                GameArtView(
                    entry: GameArtCatalog.shaftRock(
                        region: stratum.region.rawValue,
                        depthMeters: stratum.startDepthMeters
                    ),
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

    private var plant: MineInfrastructure {
        MineInfrastructureEngine.infrastructure(
            equipment: player.equipment,
            modifications: player.equipmentModifications
        )
    }

    private func workCrew(width: CGFloat) -> some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        return ForEach(1..<max(2, plant.crew), id: \.self) { index in
            let x = width / 2 + (index.isMultiple(of: 2) ? 54 : -58) + CGFloat(index) * 4
            let y = max(30, headY - 26 - CGFloat(index % 2) * 34)
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(DeepMinePalette.brass.color.opacity(0.42))
                    .frame(width: 34, height: 2)
                DeepMinePixelImage(name: "MinerSprite", size: 24)
                    .opacity(0.88)
                    .offset(y: -2)
            }
            .frame(width: 34, height: 26, alignment: .bottom)
            .position(x: x, y: y)
        }
    }

    private func serviceLamps(width: CGFloat) -> some View {
        let headY = ShaftGeometry.y(for: scene.headDepthMeters, in: scene)
        let span = max(40, headY - 30)
        return ForEach(0..<plant.serviceLamps, id: \.self) { index in
            let ratio = CGFloat(index + 1) / CGFloat(plant.serviceLamps + 1)
            DeepMinePixelImage(
                name: DeepMineArt.equipment(.lamp, level: player.equipment.lamp),
                size: 18
            )
            .opacity(0.86)
            .position(
                x: width / 2 + (index.isMultiple(of: 2) ? -1 : 1) * min(width * 0.32, 74),
                y: 24 + span * ratio
            )
        }
    }

    private func installations(width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            serviceLamps(width: width)
            workCrew(width: width)
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
        return ShaftWorkFaceView(
            width: width,
            player: player,
            isStruck: isStruck,
            strikeSignal: strikeSignal,
            strikeVariant: strikeVariant,
            onStrike: onStrike
        )
        .position(x: width / 2, y: headY + 26)
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
}
