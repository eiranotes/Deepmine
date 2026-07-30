import DeepMineCore
import SwiftUI

@MainActor
struct EquipmentView: View {
    enum Notice: Equatable {
        case success
        case crewGrew(Int)
        case insufficient(required: Double, available: Double)
        case storageFailure
    }

    let gameStore: GameStore?
    let handoffRecommendation: ReturnUpgradeRecommendation?
    let onPlayerChange: (PlayerState) -> Void
    @State var player: PlayerState
    @State var recommendation: UpgradeRecommendation?
    @State var notice: Notice?
    @State var pendingPurchase: (equipment: EquipmentKind, commandID: UUID)?
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
                if !maximumEquipment.isEmpty { maximumPanel }
                ForEach(EquipmentKind.allCases, id: \.self) { equipmentRow($0) }
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
                    Text(DeepMineStrings.text(.navigationEquipment))
                        .font(.caption.weight(.bold))
                    Label(DeepMineStrings.text(.gameOre), systemImage: "shippingbox.fill")
                        .font(.headline)
                }
                Spacer()
                Text(DeepMineNumberFormatter.string(player.resources.ore))
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
                        .accessibilityIdentifier(
                            "equipment-recommendation-kind-\(highlightedEquipment.rawValue)"
                        )
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
