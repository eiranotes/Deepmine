import DeepMineCore
import SwiftUI

@MainActor
extension EquipmentView {
    var refinementPanel: some View {
        DeepMineRivetedPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(DeepMineStrings.text(.equipmentRefinementTitle), systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .accessibilityIdentifier("equipment-refinement")
                    Spacer()
                    Text("R\(player.refinementTiers.total)")
                        .font(.caption.monospacedDigit().weight(.heavy))
                        .padding(.horizontal, 8)
                        .frame(minHeight: 28)
                        .background(
                            DeepMinePalette.brass.color.opacity(0.14),
                            in: Capsule()
                        )
                }
                Text(DeepMineStrings.text(.equipmentRefinementIntro))
                    .font(.caption)
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(EquipmentKind.allCases, id: \.self) { refinementRow($0) }
            }
        }
    }

    private func refinementRow(_ kind: EquipmentKind) -> some View {
        let level = EquipmentEngine.level(of: kind, in: player.equipment)
        let tier = player.refinementTiers.tier(for: kind)
        let nextTier = tier + 1
        let unlocked = tier < RefinementEngine.unlockedTiers(forLevel: level)
        let required = RefinementEngine.requiredLevel(forTier: nextTier)
        let cost = RefinementEngine.oreCostBig(for: kind, tier: nextTier)
        let factor = RefinementImpact.coreMultiplier(for: kind, in: player)
        let factorKey: DeepMineStringKey = kind == .lamp
            ? .equipmentRefinementCriticalMultiplier
            : .equipmentRefinementOutputMultiplier

        return Button { purchaseRefinement(kind) } label: {
            HStack(spacing: 10) {
                DeepMinePixelImage(
                    name: GameArtCatalog.refinementBadgeName(kind: kind.rawValue),
                    size: 36
                )
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind)))
                        .font(.subheadline.weight(.bold))
                    Text("\(DeepMineStrings.text(factorKey)) ×\(DeepMineRateFormatter.string(factor))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.68))
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("R\(tier) → R\(nextTier)")
                    Text(unlocked ? "◆\(DeepMineNumberFormatter.string(big: cost))" : "Lv. \(required)")
                        .foregroundStyle(unlocked
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.limestone.color.opacity(0.58))
                }
                .font(.caption.monospacedDigit().weight(.bold))
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(DeepMineMetalButtonStyle(role: .secondary))
        .disabled(!unlocked || isLoading || notice == .storageFailure)
        .accessibilityLabel(
            "\(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(kind))), "
                + "R\(tier), R\(nextTier), "
                + "\(DeepMineStrings.text(factorKey)) ×\(DeepMineRateFormatter.string(factor)), "
                + (unlocked ? DeepMineNumberFormatter.string(big: cost) : "Lv. \(required)")
        )
        .accessibilityHint(DeepMineStrings.text(.equipmentRefinementIntro))
        .accessibilityIdentifier("equipment-refinement-\(kind.rawValue)")
    }
}
