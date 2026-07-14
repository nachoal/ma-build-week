import SwiftUI

/// Static miniature of the voice-ink contour — the app's motif carried into
/// onboarding and the home menu. Rest pose only, no motion, decorative.
struct InkGlyph: View {
    var body: some View {
        Canvas { context, size in
            let canvas = VoiceInkGeometry.contourCanvas
            let fit = min(size.width / canvas.width, size.height / canvas.height)
            let offset = CGSize(
                width: (size.width - canvas.width * fit) / 2,
                height: (size.height - canvas.height * fit) / 2
            )
            context.translateBy(x: offset.width, y: offset.height)
            context.scaleBy(x: fit, y: fit)

            for layer in VoiceInkGeometry.speakingLayers() {
                let path = VoiceInkGeometry.path(for: layer.spec)
                switch layer.kind {
                case .fill(let opacity):
                    context.fill(path, with: .color(MATheme.mist.opacity(opacity)))
                case .stroke(let width, let opacity, let dash):
                    context.stroke(
                        path,
                        with: .color(MATheme.ai.opacity(opacity)),
                        style: StrokeStyle(
                            lineWidth: width, lineCap: .round, dash: dash.map { CGFloat($0) }
                        )
                    )
                }
            }
            let dot = VoiceInkGeometry.contourCenterDot
            context.fill(
                Path(ellipseIn: CGRect(
                    x: dot.center.x - dot.radius,
                    y: dot.center.y - dot.radius,
                    width: dot.radius * 2,
                    height: dot.radius * 2
                )),
                with: .color(MATheme.ai)
            )
        }
        .accessibilityHidden(true)
    }
}
