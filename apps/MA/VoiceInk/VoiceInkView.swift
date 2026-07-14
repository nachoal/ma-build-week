import SwiftUI

/// Canvas renderer for the voice-ink object. The canvas itself is hidden from
/// assistive tech; the parent supplies a Spanish semantic label.
struct VoiceInkView: View {
    enum Mode: Equatable {
        case speaking
        case hai(elapsedSinceBackchannel: Double)
    }

    let mode: Mode
    /// Fixture-anchored time used only for the breathing modulation.
    let time: Double
    let reduceMotion: Bool

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

            let breath = VoiceInkGeometry.breathingScale(at: time, breathing: !reduceMotion)
            let anchor = VoiceInkGeometry.contourAnchor
            var breathing = context
            breathing.translateBy(x: anchor.x, y: anchor.y)
            breathing.scaleBy(x: breath, y: breath)
            breathing.translateBy(x: -anchor.x, y: -anchor.y)

            for layer in VoiceInkGeometry.speakingLayers() {
                draw(layer, in: &breathing)
            }
            let center = VoiceInkGeometry.contourCenterDot
            breathing.fill(
                Path(ellipseIn: CGRect(
                    x: center.center.x - center.radius,
                    y: center.center.y - center.radius,
                    width: center.radius * 2,
                    height: center.radius * 2
                )),
                with: .color(MATheme.ai)
            )

            if case .hai(let elapsed) = mode {
                let reveal = VoiceInkGeometry.wakeReveal(
                    elapsedSinceBackchannel: elapsed, reduceMotion: reduceMotion
                )
                for layer in VoiceInkGeometry.wakeLayers(reveal: reveal) {
                    draw(layer, in: &context)
                }
                let origin = VoiceInkGeometry.wakeOrigin
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: origin.center.x - origin.radius,
                        y: origin.center.y - origin.radius,
                        width: origin.radius * 2,
                        height: origin.radius * 2
                    )),
                    with: .color(MATheme.ai)
                )
            }
        }
        .accessibilityHidden(true)
    }

    private func draw(_ layer: VoiceInkGeometry.Layer, in context: inout GraphicsContext) {
        var path = VoiceInkGeometry.path(for: layer.spec)
        if layer.reveal < 1.0 {
            path = path.trimmedPath(from: 0, to: layer.reveal)
        }
        switch layer.kind {
        case .fill(let opacity):
            context.fill(path, with: .color(MATheme.mist.opacity(opacity)))
        case .stroke(let width, let opacity, let dash):
            context.stroke(
                path,
                with: .color(MATheme.ai.opacity(opacity)),
                style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash.map { CGFloat($0) })
            )
        }
    }
}

/// Static yield strip for screen 04: contracted tutor ink upper-right, the
/// learner's firm loop lower-left, a dotted handoff trace between them. The
/// composition itself is the negative-space cut — no motion required.
struct YieldStripView: View {
    var body: some View {
        Canvas { context, size in
            let canvas = VoiceInkGeometry.yieldCanvas
            let fit = min(size.width / canvas.width, size.height / canvas.height)
            let offset = CGSize(
                width: (size.width - canvas.width * fit) / 2,
                height: (size.height - canvas.height * fit) / 2
            )
            context.translateBy(x: offset.width, y: offset.height)
            context.scaleBy(x: fit, y: fit)

            for layer in VoiceInkGeometry.yieldLayers() {
                let path = VoiceInkGeometry.path(for: layer.spec)
                if case .stroke(let width, let opacity, let dash) = layer.kind {
                    context.stroke(
                        path,
                        with: .color(MATheme.ai.opacity(opacity)),
                        style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash.map { CGFloat($0) })
                    )
                }
            }
            for dot in [VoiceInkGeometry.tutorContractedDot, VoiceInkGeometry.learnerDot] {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: dot.center.x - dot.radius,
                        y: dot.center.y - dot.radius,
                        width: dot.radius * 2,
                        height: dot.radius * 2
                    )),
                    with: .color(MATheme.ai.opacity(dot.opacity))
                )
            }
        }
        .accessibilityHidden(true)
    }
}
