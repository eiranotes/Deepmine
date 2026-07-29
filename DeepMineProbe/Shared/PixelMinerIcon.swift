import SwiftUI

struct PixelMinerIcon: View {
    var size: CGFloat = 24
    var lampColor: Color = ProbePalette.brass

    var body: some View {
        Canvas(rendersAsynchronously: false) { context, size in
            context.withCGContext { $0.setShouldAntialias(false) }
            let cell = min(size.width, size.height) / 24

            func fill(_ x: Int, _ y: Int, _ width: Int, _ height: Int, color: Color) {
                let rect = CGRect(
                    x: CGFloat(x) * cell,
                    y: CGFloat(y) * cell,
                    width: CGFloat(width) * cell,
                    height: CGFloat(height) * cell
                )
                context.fill(Path(rect), with: .color(color))
            }

            let shadow = ProbePalette.rockMid
            let rock = ProbePalette.metal
            let highlight = ProbePalette.highlight

            fill(8, 4, 7, 2, color: rock)
            fill(7, 6, 9, 2, color: highlight)
            fill(9, 8, 6, 5, color: rock)
            fill(8, 13, 7, 6, color: shadow)
            fill(7, 19, 3, 3, color: rock)
            fill(13, 19, 3, 3, color: rock)
            fill(12, 5, 2, 2, color: lampColor)
            fill(16, 8, 2, 2, color: highlight)
            fill(17, 7, 2, 2, color: highlight)
            fill(18, 6, 4, 1, color: highlight)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("광부 픽셀 실루엣")
    }
}
