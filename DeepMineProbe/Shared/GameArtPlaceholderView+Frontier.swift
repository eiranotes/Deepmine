import SwiftUI

/// Placeholders for the two D-055 slots. Separate from the main placeholder file only to
/// keep both under the 300-line limit.

/// Two rock shoulders leaving an open throat between them, with the contact notch at the
/// bottom centre where the fracture grows from.
struct ShaftFrontierLipPlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            let notchWidth = proxy.size.width * 0.34
            ZStack {
                HStack(spacing: notchWidth) {
                    shoulder(mirrored: false)
                    shoulder(mirrored: true)
                }
                Rectangle()
                    .fill(ProbePalette.shale)
                    .frame(width: notchWidth * 0.36, height: proxy.size.height * 0.18)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private func shoulder(mirrored: Bool) -> some View {
        UnevenRoundedRectangle(
            topLeadingRadius: mirrored ? 26 : 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: mirrored ? 0 : 26
        )
        .fill(ProbePalette.shale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Four equal frames on one baseline: ready, anticipation, contact, recoil. The bar height
/// steps down at contact so a wrong frame index is visible rather than merely wrong.
struct MinerMiningStripPlaceholder: View {
    var body: some View {
        GeometryReader { proxy in
            let frameWidth = proxy.size.width / CGFloat(GameArtCatalog.minerMiningFrameCount)
            HStack(spacing: 0) {
                ForEach(0..<GameArtCatalog.minerMiningFrameCount, id: \.self) { frame in
                    Rectangle()
                        .fill(ProbePalette.limestone)
                        .frame(
                            width: frameWidth * 0.5,
                            height: proxy.size.height * (frame == 2 ? 0.6 : 0.82)
                        )
                        .frame(width: frameWidth, height: proxy.size.height, alignment: .bottom)
                }
            }
        }
    }
}
