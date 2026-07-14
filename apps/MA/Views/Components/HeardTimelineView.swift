import SwiftUI

/// Tutor timeline: one capsule per provenance-tagged beat, a ring per
/// acknowledged はい, a live dot, then open track. Fixture simulation and
/// rendered audio share geometry without sharing evidence semantics.
struct TutorTimelineView: View {
    let beats: [TimelineBeat]
    let backchannelMarks: [Double]
    let outputActive: Bool

    private var recentBeats: [TimelineBeat] { Array(beats.suffix(4)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroCapsLabel(text: "LA VOZ DEL TUTOR · SIMULADA")
            HStack(spacing: 6) {
                ForEach(Array(recentBeats.enumerated()), id: \.element.id) { index, beat in
                    let isLast = index == recentBeats.count - 1
                    Capsule()
                        .fill(MATheme.ai.opacity(isLast ? 1.0 : 0.35 + 0.15 * Double(index)))
                        .frame(width: strokeWidth(for: beat), height: strokeHeight(for: beat))
                    if hasMark(after: beat, at: index) {
                        Circle()
                            .stroke(MATheme.ai, lineWidth: 2.5)
                            .background(Circle().fill(.white))
                            .frame(width: 12, height: 12)
                    }
                }
                if outputActive {
                    Circle()
                        .fill(MATheme.ai)
                        .frame(width: 8, height: 8)
                }
                Rectangle()
                    .fill(MATheme.hairline)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 28)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private func strokeWidth(for beat: TimelineBeat) -> CGFloat {
        20 + 40 * beat.amplitude
    }

    private func strokeHeight(for beat: TimelineBeat) -> CGFloat {
        8 + 10 * beat.amplitude
    }

    /// A ring renders between the beat containing the はい mark and the next.
    private func hasMark(after beat: TimelineBeat, at index: Int) -> Bool {
        backchannelMarks.contains { mark in
            mark >= beat.start && mark < beat.end
        }
    }

    private var accessibilitySummary: String {
        var parts = ["Línea de tiempo simulada: \(beats.count) golpes de voz del tutor, sin audio."]
        if !backchannelMarks.isEmpty {
            parts.append("Tu はい quedó marcado sin cortar la secuencia.")
        }
        parts.append(outputActive ? "La secuencia sigue." : "La secuencia está en pausa.")
        return parts.joined(separator: " ")
    }
}
