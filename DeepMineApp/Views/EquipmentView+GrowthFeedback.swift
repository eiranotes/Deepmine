import DeepMineCore
import SwiftUI

@MainActor
extension EquipmentView {
    @ViewBuilder
    var noticePanel: some View {
        switch notice {
        case .success:
            DeepMineRivetedPanel {
                Label(
                    DeepMineStrings.text(.equipmentPurchaseSuccess),
                    systemImage: "checkmark.seal.fill"
                )
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DeepMinePalette.brass.color)
            }
            .accessibilityIdentifier("equipment-notice-success")
        case let .purchase(equipment, physical, impact, crewSize):
            purchaseNotice(
                equipment: equipment,
                physical: physical,
                impact: impact,
                crewSize: crewSize
            )
        case let .refinement(impact):
            refinementNotice(impact)
        case let .insufficient(required, available):
            DeepMineRivetedPanel {
                VStack(alignment: .leading, spacing: 4) {
                    Label(
                        DeepMineStrings.text(.equipmentInsufficientTitle),
                        systemImage: "shippingbox"
                    )
                    .font(.subheadline.weight(.bold))
                    Text(
                        "\(DeepMineNumberFormatter.string(big: available)) / "
                            + DeepMineNumberFormatter.string(big: required)
                    )
                    .font(.caption.monospacedDigit())
                    Text(DeepMineStrings.text(.equipmentInsufficientBody)).font(.caption)
                }
                .foregroundStyle(DeepMinePalette.brass.color)
                .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityIdentifier("equipment-notice-insufficient")
        case .storageFailure, .none:
            EmptyView()
        }
    }

    private func purchaseNotice(
        equipment: EquipmentKind,
        physical: RigUpgradePhysicalPresentation,
        impact: PurchaseImpact?,
        crewSize: Int?
    ) -> some View {
        DeepMineRivetedPanel {
            HStack(alignment: .top, spacing: 12) {
                RigGenerationHousing(visual: physical.visual, size: 54)
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Label(
                        DeepMineStrings.text(.equipmentPurchaseSuccess),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    Text(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(equipment)))
                        .font(.caption.weight(.semibold))
                    Text(physical.detail)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                        .fixedSize(horizontal: false, vertical: true)
                    if let impact { impactRows(impact) }
                    if let crewSize {
                        Label(
                            String(format: DeepMineStrings.text(.returnCrewGrew), crewSize),
                            systemImage: "person.2.fill"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DeepMinePalette.brass.color)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("equipment-notice-success")
    }

    private func refinementNotice(_ refinement: RefinementImpact) -> some View {
        let factorKey: DeepMineStringKey = refinement.equipment == .lamp
            ? .equipmentRefinementCriticalMultiplier
            : .equipmentRefinementOutputMultiplier
        return DeepMineRivetedPanel {
            HStack(alignment: .top, spacing: 12) {
                DeepMinePixelImage(
                    name: GameArtCatalog.refinementBadgeName(
                        kind: refinement.equipment.rawValue
                    ),
                    size: 44
                )
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Label(
                        DeepMineStrings.text(.equipmentRefinementSuccess),
                        systemImage: "sparkles"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    Text(
                        "\(DeepMineStrings.text(DeepMineProgressLabels.equipmentKey(refinement.equipment)))  "
                            + "R\(refinement.beforeTier) → R\(refinement.afterTier)"
                    )
                    .font(.caption.monospacedDigit().weight(.semibold))
                    Text(
                        "\(DeepMineStrings.text(factorKey))  "
                            + "×\(DeepMineRateFormatter.string(refinement.coreMultiplier))"
                    )
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(DeepMinePalette.brass.color)
                    impactRows(refinement.purchaseImpact)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("equipment-notice-refinement")
    }

    @ViewBuilder
    private func impactRows(_ impact: PurchaseImpact) -> some View {
        let presentation = PurchaseImpactPresentation(impact)
        Text(presentation.transition)
            .font(.caption.monospacedDigit().weight(.semibold))
            .fixedSize(horizontal: false, vertical: true)
        Text(presentation.changeValue)
            .font(.caption.monospacedDigit().weight(.heavy))
            .foregroundStyle(DeepMinePalette.brass.color)
    }
}
