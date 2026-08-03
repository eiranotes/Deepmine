import DeepMineCore
import SwiftUI

@MainActor
struct EquipmentView: View {
    enum Notice: Equatable {
        case success
        case purchase(
            equipment: EquipmentKind,
            physical: RigUpgradePhysicalPresentation,
            impact: PurchaseImpact?,
            crewSize: Int?
        )
        case refinement(RefinementImpact)
        case insufficient(required: BigNumber, available: BigNumber)
        case storageFailure
    }

    let gameStore: GameStore?
    let handoffRecommendation: ReturnUpgradeRecommendation?
    let onPlayerChange: (PlayerState) -> Void
    @State var player: PlayerState
    @State var recommendation: UpgradeRecommendation?
    @State var notice: Notice?
    @State var pendingPurchase: (equipment: EquipmentKind, commandID: UUID, before: PlayerState)?
    @State var pendingBulk: (equipment: EquipmentKind, maximum: Int?, remembered: Bool, commandID: UUID, before: PlayerState)?
    @State var pendingModification: (kind: EquipmentModificationKind, commandID: UUID, before: PlayerState)?
    @State var pendingRefinement: (equipment: EquipmentKind, commandID: UUID, before: PlayerState)?
    @State var handoffConsumed = false
    @State var isLoading = false

    init(
        gameStore: GameStore?,
        player: PlayerState,
        handoffRecommendation: ReturnUpgradeRecommendation? = nil,
        onPlayerChange: @escaping (PlayerState) -> Void = { _ in }
    ) {
        self.gameStore = gameStore
        self.handoffRecommendation = handoffRecommendation
        self.onPlayerChange = onPlayerChange
        _player = State(initialValue: player)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 17) {
                oreHeader
                handoffPanel
                if notice == .storageFailure { recoveryPanel }
                if notice != nil, notice != .storageFailure { noticePanel }
                refinementPanel
                ForEach(EquipmentKind.allCases, id: \.self) { equipmentRow($0) }
                modificationPanel
            }
            .padding(17)
        }
        .background(DeepMinePalette.coal.color.ignoresSafeArea())
        .foregroundStyle(DeepMinePalette.limestone.color)
        .navigationTitle(DeepMineStrings.text(.navigationEquipment))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("equipment-screen")
        .task { refresh() }
        .onDisappear { onPlayerChange(player) }
    }

    private var oreHeader: some View {
        DeepMineRivetedPanel {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DeepMineStrings.text(.navigationEquipment)).font(.caption.weight(.bold))
                    Label(DeepMineStrings.text(.gameOre), systemImage: "shippingbox.fill")
                        .font(.headline)
                }
                Spacer()
                Text(DeepMineNumberFormatter.string(big: player.resources.ore))
                    .font(.title3.monospacedDigit().weight(.heavy))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("equipment-ore")
            }
        }
    }

    @ViewBuilder
    private var handoffPanel: some View {
        if let highlightedEquipment {
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        DeepMineStrings.text(.equipmentRecommendation),
                        systemImage: "signpost.right.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityIdentifier("equipment-recommendation")
                    Text(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(highlightedEquipment)))
                        .font(.subheadline.weight(.bold))
                        .accessibilityIdentifier("equipment-recommendation-kind-\(highlightedEquipment.rawValue)")
                    if let handoffRecommendation, !handoffConsumed {
                        Text(DeepMineStrings.text(
                            handoffRecommendation.isAffordable
                                ? .returnEquipmentHandoffAffordable
                                : .returnEquipmentHandoffUnaffordable
                        ))
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(
                            handoffRecommendation.isAffordable
                                ? "equipment-handoff-affordable"
                                : "equipment-handoff-unaffordable"
                        )
                    }
                }
            }
        }
    }

}

@MainActor
extension EquipmentView {
    var modificationPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        DeepMineStrings.text(.equipmentModificationTitle),
                        systemImage: "arrow.triangle.branch"
                    )
                    .font(.headline)
                    .foregroundStyle(DeepMinePalette.brass.color)
                    Text(DeepMineStrings.text(.equipmentModificationIntro))
                        .font(.caption)
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(EquipmentKind.allCases, id: \.self) { modificationRow($0) }
            }
        }
        .accessibilityIdentifier("equipment-modifications")
    }

    private func modificationRow(_ equipment: EquipmentKind) -> some View {
        let level = EquipmentEngine.level(of: equipment, in: player.equipment)
        let selected = player.equipmentModifications.selected(for: equipment)
        let options = EquipmentModificationKind.allCases.filter { $0.equipment == equipment }
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(equipment)))
                    .font(.subheadline.weight(.bold))
                Spacer()
                if let selected {
                    Label(
                        DeepMineStrings.text(.equipmentModificationSelected),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    .accessibilityLabel(DeepMineStrings.text(
                        DeepMineProgressLabels.modificationTitleKey(selected)
                    ))
                } else if level < Balance.equipmentModificationUnlockLevel {
                    Text(String(
                        format: DeepMineStrings.text(.equipmentModificationLocked),
                        Balance.equipmentModificationUnlockLevel
                    ))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.58))
                }
            }
            HStack(alignment: .top, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    modificationButton(option, selected: selected, level: level)
                }
            }
        }
        .padding(.top, 2)
        .accessibilityIdentifier("equipment-modification-row-\(equipment.rawValue)")
    }

    private func modificationButton(
        _ option: EquipmentModificationKind,
        selected: EquipmentModificationKind?,
        level: Int
    ) -> some View {
        let isSelected = selected == option
        let enabled = selected == nil
            && level >= Balance.equipmentModificationUnlockLevel
            && !isLoading
            && notice != .storageFailure
        return Button { purchaseModification(option) } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    GameArtView(
                        entry: GameArtCatalog.rigModification(option.rawValue),
                        size: 34
                    )
                    Text(DeepMineStrings.text(DeepMineProgressLabels.modificationTitleKey(option)))
                        .font(.caption.weight(.bold))
                    if isSelected { Image(systemName: "checkmark.circle.fill") }
                }
                Text(DeepMineStrings.text(DeepMineProgressLabels.modificationEffectKey(option)))
                    .font(.caption2)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                Text(DeepMineNumberFormatter.string(
                    EquipmentModificationEngine.cost(for: option.equipment)
                ))
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(DeepMinePalette.brass.color)
            }
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
            .padding(9)
            .background(
                isSelected ? DeepMinePalette.shale.color : DeepMinePalette.coal.color,
                in: RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DeepMineMetrics.badgeCornerRadius)
                    .stroke(
                        isSelected
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.24),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled || isSelected ? 1 : 0.48)
        .accessibilityIdentifier("equipment-modification-\(option.rawValue)")
    }

    func purchaseModification(
        _ modification: EquipmentModificationKind,
        commandID: UUID? = nil
    ) {
        guard let gameStore else { notice = .storageFailure; return }
        let commandID = commandID ?? UUID()
        let retryBaseline = pendingModification.flatMap {
            $0.commandID == commandID ? $0.before : nil
        }
        guard let before = retryBaseline ?? (try? gameStore.playerState()) else {
            notice = .storageFailure
            return
        }
        isLoading = true
        pendingModification = (modification, commandID, before)
        defer { isLoading = false }
        do {
            switch try gameStore.purchaseEquipmentModification(
                modification,
                commandID: commandID
            ) {
            case .purchased, .duplicate:
                let after = try gameStore.playerState()
                player = after
                notice = purchaseNotice(
                    equipment: modification.equipment,
                    before: before,
                    after: after
                )
                pendingModification = nil
            case .alreadySelected:
                player = try gameStore.playerState()
                notice = .success
                pendingModification = nil
            case let .insufficientOre(required, available):
                notice = .insufficient(
                    required: BigNumber(required),
                    available: BigNumber(available)
                )
                pendingModification = nil
            case .levelLocked:
                notice = nil
                pendingModification = nil
            }
        } catch {
            notice = .storageFailure
        }
    }
}
