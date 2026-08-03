import DeepMineCore
import SwiftUI
import UIKit
/// A guided work cage locks to the face and lowers only after a breakthrough.
/// Equipment purchases replace or add real modules; none is only a number.
struct SuspendedMiningRigView: View {
    let player: PlayerState
    let strikeSignal: Int
    let strikeVariant: StrikeVariant
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drillOffset: CGFloat = 0
    @State private var frameCompression: CGFloat = 1
    @State private var descentOffset: CGFloat = 0
    @State private var cablePhase = 0
    @State private var didAppear = false
    @State private var lastAnimatedSegmentIndex = 0
    @State private var advanceCueSegments = 0
    @State private var advanceAnnouncement = "작업면 체결됨"
    private var plant: MineInfrastructure {
        MineInfrastructureEngine.infrastructure(
            equipment: player.equipment,
            modifications: player.equipmentModifications,
            refinements: player.refinementTiers
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            cableTravel
            GameArtView(
                entry: GameArtCatalog.suspendedRigFrame,
                fit: CGSize(width: 300, height: 120)
            )
            .position(x: 150, y: 60)
            operatorCrew
            transportReadout
            lightingReadout
            drillAssembly
            RigEquipmentPlate(code: "D", visual: plant.drillVisual)
                .position(x: 194, y: 65)
            RigEquipmentPlate(code: "C", visual: plant.cartVisual)
                .position(x: 230, y: 112)
            RigEquipmentPlate(code: "L", visual: plant.lampVisual)
                .position(x: 255, y: 35)
            if let module = plant.cartBranchModule {
                branchModule(module, size: 42)
                    .position(x: 244, y: 70)
            }
            if let module = plant.lampBranchModule {
                branchModule(module, size: 38)
                    .position(x: 278, y: 25)
            }
            if advanceCueSegments > 0 {
                Text("WINCH \(advanceCueSegments * Balance.metersPerSegment)m")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(DeepMinePalette.coal.color.opacity(0.9))
                    .overlay {
                        Rectangle().stroke(DeepMinePalette.brass.color, lineWidth: 1)
                    }
                    .position(x: 150, y: 18)
            }
        }
        .frame(width: 300, height: 132)
        .offset(y: descentOffset)
        .scaleEffect(x: 1, y: frameCompression, anchor: .top)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("현수식 채굴 리그")
        .accessibilityValue(accessibilitySummary)
        .accessibilityIdentifier("suspended-mining-rig")
        .task(id: strikeSignal) { await animateStrike() }
        .onAppear {
            lastAnimatedSegmentIndex = player.mineFace.segmentIndex
            didAppear = true
        }
        .task(id: player.mineFace.segmentIndex) {
            guard didAppear else { return }
            let target = player.mineFace.segmentIndex
            let segments = target - lastAnimatedSegmentIndex
            guard segments > 0 else { return }
            await animateLowering(segments: segments, targetIndex: target)
        }
    }
    private var drillAssembly: some View {
        ZStack(alignment: .top) {
            RigGenerationHousing(visual: plant.drillVisual, size: 86)
            GameArtView(
                entry: GameArtCatalog.rigDrill(tier: plant.drillTier),
                size: 76
            )
            if let module = plant.drillBranchModule {
                branchModule(module, size: 38)
                    .offset(x: 39, y: 24)
            }
            refinementBands(count: plant.drillRefinementBands, width: 42)
                .offset(y: 8)
        }
        .frame(width: 118, height: 88, alignment: .top)
        .position(x: 150, y: 83)
        .offset(y: drillOffset)
    }
    private var cableTravel: some View {
        HStack(spacing: 230) {
            cable
            cable
        }
        .frame(width: 270)
        .position(x: 150, y: 28)
        .offset(y: CGFloat(cablePhase % 2) * 3)
    }
    private var cable: some View {
        VStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { index in
                Rectangle()
                    .fill(index.isMultiple(of: 2)
                        ? DeepMinePalette.shale.color
                        : DeepMinePalette.limestone.color.opacity(0.68))
                    .frame(width: 3, height: 5)
            }
        }
    }
    private var operatorCrew: some View {
        ZStack {
            DeepMinePixelImage(name: "MinerSprite", size: 32)
                .position(x: 69, y: 69)
            ForEach(1..<max(1, plant.crew), id: \.self) { index in
                DeepMinePixelImage(name: "MinerSprite", size: 20)
                    .opacity(0.84)
                    .position(x: 42 + CGFloat(index) * 23, y: 82)
            }
        }
    }

    private var transportReadout: some View {
        HStack(spacing: plant.railLanes == 2 ? 2 : 5) {
            ForEach(0..<plant.carts, id: \.self) { _ in
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.cart, level: player.equipment.cart),
                    size: plant.carts > 2 ? 15 : 18
                )
            }
        }
        .background { RigGenerationHousing(visual: plant.cartVisual, size: 58) }
        .overlay(alignment: .bottom) {
            refinementBands(count: plant.cartRefinementBands, width: 34)
                .offset(y: 6)
        }
        .position(x: 234, y: 101)
    }

    private var lightingReadout: some View {
        HStack(spacing: 4) {
            ForEach(0..<min(3, plant.serviceLamps), id: \.self) { _ in
                DeepMinePixelImage(
                    name: DeepMineArt.equipment(.lamp, level: player.equipment.lamp),
                    size: 15
                )
            }
        }
        .background { RigGenerationHousing(visual: plant.lampVisual, size: 52) }
        .overlay(alignment: .bottom) {
            refinementBands(count: plant.lampRefinementBands, width: 28)
                .offset(y: 6)
        }
        .position(x: 250, y: 32)
    }

    private func branchModule(_ kind: EquipmentModificationKind, size: CGFloat) -> some View {
        GameArtView(entry: GameArtCatalog.rigModification(kind.rawValue), size: size)
            .transition(.scale(scale: 0.72).combined(with: .opacity))
    }

    private func refinementBands(count: Int, width: CGFloat) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<count, id: \.self) { _ in
                Rectangle()
                    .fill(DeepMinePalette.brass.color)
                    .frame(width: width, height: 2)
            }
        }
    }

    private var impactDistance: CGFloat {
        switch strikeVariant {
        case .quick: 9
        case .heavy: 14
        case .critical: 19
        }
    }

    @MainActor
    private func animateStrike() async {
        guard strikeSignal > 0 else { return }
        let timeline = StrikeTimeline.timeline(for: strikeVariant, reduceMotion: reduceMotion)
        let anticipation = max(0.03, timeline.contact * 0.55)
        let travel = max(0.02, timeline.contact - anticipation)
        withAnimation(.easeOut(duration: anticipation)) {
            drillOffset = reduceMotion ? -1 : -4
        }
        do { try await Task.sleep(for: .seconds(anticipation)) }
        catch {
            drillOffset = 0
            frameCompression = 1
            return
        }
        withAnimation(.easeIn(duration: travel)) {
            drillOffset = impactDistance
            frameCompression = reduceMotion ? 1 : 0.975
        }
        do { try await Task.sleep(for: .seconds(travel)) }
        catch {
            drillOffset = 0
            frameCompression = 1
            return
        }
        let recovery = max(0.06, timeline.duration - timeline.contact)
        withAnimation(reduceMotion
            ? .easeOut(duration: recovery)
            : .interactiveSpring(response: recovery, dampingFraction: 0.78)) {
            drillOffset = 0
            frameCompression = 1
        }
    }

    @MainActor
    private func animateLowering(segments: Int, targetIndex: Int) async {
        let batchScale = log2(Double(max(1, segments)))
        let dip = CGFloat(min(14, 7 + batchScale * 2))
        let travel = min(0.9, 0.32 + batchScale * 0.14)
        cablePhase &+= 1
        advanceCueSegments = segments
        announce("윈치 \(segments)개 구간, \(segments * Balance.metersPerSegment)미터 하강 시작")
        if reduceMotion {
            lastAnimatedSegmentIndex = targetIndex
            advanceCueSegments = 0
            announce("윈치 \(segments)개 구간, \(segments * Balance.metersPerSegment)미터 하강 완료")
            return
        }
        withAnimation(.easeIn(duration: 0.14)) { frameCompression = 0.985 }
        do { try await Task.sleep(for: .milliseconds(140)) }
        catch {
            descentOffset = 0
            frameCompression = 1
            advanceCueSegments = 0
            return
        }
        withAnimation(.easeInOut(duration: travel)) { descentOffset = dip }
        do { try await Task.sleep(for: .seconds(travel)) }
        catch {
            descentOffset = 0
            frameCompression = 1
            advanceCueSegments = 0
            return
        }
        withAnimation(.easeOut(duration: 0.16)) {
            descentOffset = 0
            frameCompression = 1
        }
        do { try await Task.sleep(for: .milliseconds(160)) }
        catch {
            descentOffset = 0
            frameCompression = 1
            advanceCueSegments = 0
            return
        }
        lastAnimatedSegmentIndex = targetIndex
        advanceCueSegments = 0
        announce("윈치 \(segments)개 구간, \(segments * Balance.metersPerSegment)미터 하강 완료")
    }
    private var accessibilitySummary: String {
        [
            toolSummary("드릴", visual: plant.drillVisual, module: plant.drillBranchModule),
            toolSummary("광차", visual: plant.cartVisual, module: plant.cartBranchModule),
            toolSummary("조명", visual: plant.lampVisual, module: plant.lampBranchModule),
            "광차 \(plant.carts)대, 레일 \(plant.railLanes)선, 작업등 \(plant.serviceLamps)기",
            advanceAnnouncement
        ].joined(separator: ", ")
    }

    private func toolSummary(
        _ name: String,
        visual: RigToolVisualState,
        module: EquipmentModificationKind?
    ) -> String {
        let moduleName = module?.rigDisplayName ?? "분기 모듈 없음"
        return "\(name) 레벨 \(visual.level), 티어 \(visual.artTier), 세대 \(visual.generation), "
            + "\(visual.housingVariant)형 하우징, "
            + "정비 셀 \(visual.upgradeCells)/\(Balance.rigUpgradeCellsPerGeneration), "
            + "정제 R\(visual.refinementTier), \(moduleName)"
    }

    @MainActor
    private func announce(_ message: String) {
        advanceAnnouncement = message
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
