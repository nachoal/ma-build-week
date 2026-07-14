import SwiftUI

/// The one decision on the home screen: the scene that is ready now.
/// Semantically a single Button — the whole card is the action, the
/// CTA-looking capsule inside is purely visual, and assistive tech gets
/// exactly one target with the full story.
struct HeroSceneCard: View {
    let scene: SceneInfo
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    MicroCapsLabel(
                        text: "ESCENA \(scene.index) · \(scene.statusLabel)",
                        color: MATheme.ai
                    )
                    Spacer()
                    InkGlyph()
                        .frame(width: 64, height: 48)
                }
                Text(scene.title)
                    .font(MATheme.title())
                    .tracking(MATheme.tightTracking(fontSize: 28))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(scene.subtitle)
                        .font(MATheme.body(16, weight: .medium))
                        .foregroundStyle(MATheme.sumi)
                    Text(scene.japaneseAccent)
                        .font(MATheme.jp(15))
                        .foregroundStyle(MATheme.stone)
                }
                Text(situationOutcome)
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lessonArc)
                    .font(MATheme.micro())
                    .tracking(MATheme.capsTracking(fontSize: 10))
                    .foregroundStyle(MATheme.ai)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
                if let minutes = scene.minutes {
                    Text("Unos \(minutes) minutos · guiado paso a paso")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                // Purely visual CTA — the enclosing Button is the interaction.
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Empezar la escena")
                        .font(MATheme.body(16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .padding(.vertical, 6)
                .background(MATheme.ai, in: Capsule())
                .padding(.top, 8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("hero.\(scene.id.rawValue)")
    }

    private var situationOutcome: String {
        "Llegas sin reserva. Te preguntarán cuántas personas y terminarás respondiendo sin leer."
    }

    private var lessonArc: String {
        "APRENDE → CONVERSA → REPARA → REPITE"
    }

    private var accessibilitySummary: String {
        var parts = [
            "Escena \(scene.index), disponible: \(scene.title).",
            situationOutcome,
            "El camino: aprende, conversa, repara y repite.",
        ]
        if let minutes = scene.minutes {
            parts.append("Unos \(minutes) minutos, guiado paso a paso.")
        }
        return parts.joined(separator: " ")
    }
}
