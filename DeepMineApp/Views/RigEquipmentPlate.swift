import DeepMineCore
import SwiftUI

/// A readable stamped plate for one persistent rig subsystem.
///
/// Major art swaps stop at T3, so exact level, housing generation and refinement remain
/// physical labels. The service cells show the next housing generation filling up.
struct RigEquipmentPlate: View {
    let code: String
    let visual: RigToolVisualState

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text("\(code)\(visual.level)")
                Text("G\(visual.generation)")
                    .foregroundStyle(DeepMinePalette.limestone.color.opacity(0.76))
                if visual.refinementTier > 0 {
                    Text("R\(visual.refinementTier)")
                        .foregroundStyle(DeepMinePalette.brass.color)
                }
            }
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundStyle(DeepMinePalette.limestone.color)
            .fixedSize()

            HStack(spacing: 2) {
                ForEach(0..<Balance.rigUpgradeCellsPerGeneration, id: \.self) { index in
                    Rectangle()
                        .fill(index < visual.upgradeCells
                            ? DeepMinePalette.brass.color
                            : DeepMinePalette.shale.color)
                        .frame(width: 5, height: 5)
                        .overlay {
                            Rectangle().stroke(
                                DeepMinePalette.limestone.color.opacity(0.24),
                                lineWidth: 0.5
                            )
                        }
                }
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(DeepMinePalette.coal.color.opacity(0.96))
        .overlay { Rectangle().stroke(DeepMinePalette.brass.color.opacity(0.7), lineWidth: 1) }
        .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 2)
    }
}

/// A generation rollover replaces the full subsystem chassis with authored art.
/// The four silhouettes cycle like an industrial model family while the exact G stamp
/// keeps late generations distinct.
struct RigGenerationHousing: View {
    let visual: RigToolVisualState
    let size: CGFloat

    var body: some View {
        GameArtView(
            entry: GameArtCatalog.rigHousing(variant: visual.housingVariant),
            size: size
        )
        .accessibilityHidden(true)
    }
}

extension EquipmentModificationKind {
    var rigDisplayName: String {
        switch self {
        case .drillWide: "확폭 비트 장착"
        case .drillImpact: "충격 비트 장착"
        case .cartFleet: "쌍선 레일 장착"
        case .cartFreight: "대형 호퍼 장착"
        case .lampReach: "장거리 반사경 장착"
        case .lampFortune: "광맥 렌즈 장착"
        }
    }
}
