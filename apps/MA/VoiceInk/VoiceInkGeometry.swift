import CoreGraphics
import SwiftUI

/// Deterministic geometry engine for the voice-ink language. All control
/// points are the exact values from docs/design/paper-ui-handoff.md (320×240
/// viewBox for the contour, 342×150 for the yield strip). Pure functions of
/// time — no randomness, renderable at any fixed timestamp.
enum VoiceInkGeometry {
    struct CurveSegment: Equatable, Sendable {
        let c1: CGPoint
        let c2: CGPoint
        let end: CGPoint
    }

    struct PathSpec: Equatable, Sendable {
        let start: CGPoint
        let curves: [CurveSegment]
        let closed: Bool
    }

    enum LayerKind: Equatable, Sendable {
        case fill(opacity: Double)
        case stroke(width: Double, opacity: Double, dash: [Double])
    }

    struct Layer: Equatable, Sendable {
        let spec: PathSpec
        let kind: LayerKind
        /// 0...1 trim of the path used for the はい wake reveal.
        var reveal: Double = 1.0
    }

    struct Dot: Equatable, Sendable {
        let center: CGPoint
        let radius: Double
        let opacity: Double
    }

    // MARK: Canvas spaces

    static let contourCanvas = CGSize(width: 320, height: 240)
    static let yieldCanvas = CGSize(width: 342, height: 150)

    /// Breathing anchor = the speaking contour's center dot.
    static let contourAnchor = CGPoint(x: 163, y: 126)

    // MARK: Speaking geometry (screen 02)

    static let mistFill = PathSpec(
        start: CGPoint(x: 152, y: 54),
        curves: [
            CurveSegment(c1: .init(x: 184, y: 46), c2: .init(x: 218, y: 60), end: .init(x: 230, y: 84)),
            CurveSegment(c1: .init(x: 240, y: 102), c2: .init(x: 234, y: 112), end: .init(x: 246, y: 128)),
            CurveSegment(c1: .init(x: 256, y: 144), c2: .init(x: 242, y: 168), end: .init(x: 218, y: 180)),
            CurveSegment(c1: .init(x: 194, y: 192), c2: .init(x: 162, y: 196), end: .init(x: 140, y: 187)),
            CurveSegment(c1: .init(x: 114, y: 177), c2: .init(x: 96, y: 158), end: .init(x: 92, y: 132)),
            CurveSegment(c1: .init(x: 88, y: 104), c2: .init(x: 116, y: 62), end: .init(x: 152, y: 54)),
        ],
        closed: true
    )

    static let outerLoop = PathSpec(
        start: CGPoint(x: 150, y: 28),
        curves: [
            CurveSegment(c1: .init(x: 198, y: 18), c2: .init(x: 248, y: 40), end: .init(x: 262, y: 74)),
            CurveSegment(c1: .init(x: 272, y: 98), c2: .init(x: 264, y: 112), end: .init(x: 280, y: 134)),
            CurveSegment(c1: .init(x: 294, y: 156), c2: .init(x: 274, y: 192), end: .init(x: 240, y: 206)),
            CurveSegment(c1: .init(x: 206, y: 220), c2: .init(x: 158, y: 226), end: .init(x: 126, y: 213)),
            CurveSegment(c1: .init(x: 94, y: 200), c2: .init(x: 68, y: 174), end: .init(x: 64, y: 140)),
            CurveSegment(c1: .init(x: 60, y: 102), c2: .init(x: 100, y: 38), end: .init(x: 150, y: 28)),
        ],
        closed: true
    )

    static let midLoop = PathSpec(
        start: CGPoint(x: 152, y: 52),
        curves: [
            CurveSegment(c1: .init(x: 186, y: 44), c2: .init(x: 220, y: 58), end: .init(x: 232, y: 84)),
            CurveSegment(c1: .init(x: 242, y: 104), c2: .init(x: 234, y: 114), end: .init(x: 246, y: 130)),
            CurveSegment(c1: .init(x: 258, y: 146), c2: .init(x: 244, y: 170), end: .init(x: 219, y: 182)),
            CurveSegment(c1: .init(x: 194, y: 194), c2: .init(x: 161, y: 197), end: .init(x: 138, y: 188)),
            CurveSegment(c1: .init(x: 112, y: 178), c2: .init(x: 94, y: 158), end: .init(x: 90, y: 132)),
            CurveSegment(c1: .init(x: 86, y: 102), c2: .init(x: 114, y: 60), end: .init(x: 152, y: 52)),
        ],
        closed: true
    )

    static let innerLoop = PathSpec(
        start: CGPoint(x: 152, y: 80),
        curves: [
            CurveSegment(c1: .init(x: 178, y: 74), c2: .init(x: 202, y: 86), end: .init(x: 210, y: 104)),
            CurveSegment(c1: .init(x: 217, y: 118), c2: .init(x: 211, y: 126), end: .init(x: 219, y: 138)),
            CurveSegment(c1: .init(x: 226, y: 149), c2: .init(x: 216, y: 163), end: .init(x: 198, y: 170)),
            CurveSegment(c1: .init(x: 180, y: 177), c2: .init(x: 156, y: 178), end: .init(x: 141, y: 170)),
            CurveSegment(c1: .init(x: 124, y: 161), c2: .init(x: 113, y: 147), end: .init(x: 112, y: 130)),
            CurveSegment(c1: .init(x: 111, y: 108), c2: .init(x: 128, y: 85), end: .init(x: 152, y: 80)),
        ],
        closed: true
    )

    // MARK: はい wake (screen 03) — arcs entering from lower-left

    static let wakeArcs: [(spec: PathSpec, width: Double, opacity: Double)] = [
        (arc(from: CGPoint(x: 76, y: 176), to: CGPoint(x: 88, y: 214), radius: 28), 2.5, 1.0),
        (arc(from: CGPoint(x: 94, y: 156), to: CGPoint(x: 116, y: 228), radius: 56), 2.0, 0.6),
        (arc(from: CGPoint(x: 114, y: 136), to: CGPoint(x: 146, y: 236), radius: 86), 1.5, 0.32),
    ]

    static let wakeOrigin = Dot(center: CGPoint(x: 58, y: 200), radius: 5, opacity: 1)

    /// Approximates an SVG arc command with a single cubic segment. The wake
    /// arcs span < 90°, where this approximation is visually exact.
    private static func arc(from start: CGPoint, to end: CGPoint, radius: Double) -> PathSpec {
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let dx = end.x - start.x
        let dy = end.y - start.y
        let chord = (dx * dx + dy * dy).squareRoot()
        let sagitta = radius - (radius * radius - chord * chord / 4).squareRoot()
        // Push the control points outward, perpendicular to the chord
        // (clockwise sweep, bulging away from the contour).
        let nx = -dy / chord
        let ny = dx / chord
        let bulge = CGPoint(x: mid.x - nx * sagitta * 1.33, y: mid.y - ny * sagitta * 1.33)
        let c1 = CGPoint(
            x: start.x + (bulge.x - start.x) * 0.55,
            y: start.y + (bulge.y - start.y) * 0.55
        )
        let c2 = CGPoint(
            x: end.x + (bulge.x - end.x) * 0.55,
            y: end.y + (bulge.y - end.y) * 0.55
        )
        return PathSpec(start: start, curves: [CurveSegment(c1: c1, c2: c2, end: end)], closed: false)
    }

    // MARK: Yield strip (screen 04)

    static let tutorContractedLoop = PathSpec(
        start: CGPoint(x: 262, y: 22),
        curves: [
            CurveSegment(c1: .init(x: 278, y: 19), c2: .init(x: 292, y: 28), end: .init(x: 294, y: 42)),
            CurveSegment(c1: .init(x: 296, y: 56), c2: .init(x: 285, y: 67), end: .init(x: 269, y: 68)),
            CurveSegment(c1: .init(x: 254, y: 69), c2: .init(x: 241, y: 60), end: .init(x: 240, y: 45)),
            CurveSegment(c1: .init(x: 239, y: 32), c2: .init(x: 248, y: 24), end: .init(x: 262, y: 22)),
        ],
        closed: true
    )

    static let handoffTrace = PathSpec(
        start: CGPoint(x: 236, y: 62),
        curves: [
            CurveSegment(c1: .init(x: 200, y: 84), c2: .init(x: 158, y: 96), end: .init(x: 118, y: 98))
        ],
        closed: false
    )

    static let learnerLoop = PathSpec(
        start: CGPoint(x: 74, y: 62),
        curves: [
            CurveSegment(c1: .init(x: 96, y: 58), c2: .init(x: 114, y: 72), end: .init(x: 116, y: 92)),
            CurveSegment(c1: .init(x: 118, y: 112), c2: .init(x: 102, y: 128), end: .init(x: 80, y: 129)),
            CurveSegment(c1: .init(x: 58, y: 130), c2: .init(x: 40, y: 116), end: .init(x: 39, y: 95)),
            CurveSegment(c1: .init(x: 38, y: 76), c2: .init(x: 52, y: 65), end: .init(x: 74, y: 62)),
        ],
        closed: true
    )

    static let tutorContractedDot = Dot(center: CGPoint(x: 267, y: 45), radius: 2.5, opacity: 0.38)
    static let learnerDot = Dot(center: CGPoint(x: 78, y: 95), radius: 5.5, opacity: 1)
    static let contourCenterDot = Dot(center: contourAnchor, radius: 4, opacity: 1)

    // MARK: Time-dependent composition

    /// Gentle breathing: ±1.5% scale on a 3.6-second cycle. `breathing: false`
    /// (Reduce Motion) returns the rest pose for every timestamp.
    static func breathingScale(at time: Double, breathing: Bool) -> Double {
        guard breathing else { return 1.0 }
        return 1.0 + 0.015 * sin(time * 2 * .pi / 3.6)
    }

    static func speakingLayers() -> [Layer] {
        [
            Layer(spec: mistFill, kind: .fill(opacity: 0.6)),
            Layer(spec: outerLoop, kind: .stroke(width: 1.5, opacity: 0.22, dash: [])),
            Layer(spec: midLoop, kind: .stroke(width: 2.0, opacity: 0.5, dash: [])),
            Layer(spec: innerLoop, kind: .stroke(width: 2.5, opacity: 1.0, dash: [])),
        ]
    }

    /// Wake reveal progress: 0→1 over 0.9 s after the はい event. Reduce
    /// Motion renders the completed wake immediately.
    static func wakeReveal(elapsedSinceBackchannel elapsed: Double, reduceMotion: Bool) -> Double {
        guard !reduceMotion else { return 1.0 }
        return min(1.0, max(0.0, elapsed / 0.9))
    }

    static func wakeLayers(reveal: Double) -> [Layer] {
        wakeArcs.map { arcSpec in
            Layer(
                spec: arcSpec.spec,
                kind: .stroke(width: arcSpec.width, opacity: arcSpec.opacity, dash: []),
                reveal: reveal
            )
        }
    }

    static func yieldLayers() -> [Layer] {
        [
            Layer(spec: tutorContractedLoop, kind: .stroke(width: 2.0, opacity: 0.38, dash: [])),
            Layer(spec: handoffTrace, kind: .stroke(width: 1.5, opacity: 0.45, dash: [1, 7])),
            Layer(spec: learnerLoop, kind: .stroke(width: 2.5, opacity: 1.0, dash: [])),
        ]
    }

    // MARK: Path construction

    static func path(for spec: PathSpec) -> Path {
        var path = Path()
        path.move(to: spec.start)
        for segment in spec.curves {
            path.addCurve(to: segment.end, control1: segment.c1, control2: segment.c2)
        }
        if spec.closed {
            path.closeSubpath()
        }
        return path
    }

    /// A stable textual fingerprint used by determinism tests.
    static func fingerprint(layers: [Layer], time: Double, breathing: Bool) -> String {
        let scale = breathingScale(at: time, breathing: breathing)
        let parts = layers.map { layer -> String in
            let trimmed = layer.reveal < 1.0
                ? path(for: layer.spec).trimmedPath(from: 0, to: layer.reveal)
                : path(for: layer.spec)
            return "\(trimmed.description)|\(layer.kind)|\(scale)"
        }
        return parts.joined(separator: ";")
    }
}
