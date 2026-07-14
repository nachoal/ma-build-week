import SwiftUI

/// The one decision on the home screen: the scene that is ready now.
/// Semantically a single Button — the whole card is the action, the
/// CTA-looking capsule inside is purely visual, and assistive tech gets
/// exactly one target with the full story.
struct HeroSceneCard: View {
    let scene: SceneInfo
    let onStart: () -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        Button(action: onStart) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    MicroCapsLabel(
                        text: language.text(
                            english: "SCENE \(scene.index) · \(scene.statusLabel(in: language))",
                            spanish: "ESCENA \(scene.index) · \(scene.statusLabel(in: language))"
                        ),
                        color: MATheme.ai
                    )
                    Spacer()
                    InkGlyph()
                        .frame(width: 64, height: 48)
                }
                Text(scene.title(in: language))
                    .font(MATheme.title())
                    .tracking(MATheme.tightTracking(fontSize: 28))
                    .foregroundStyle(MATheme.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(scene.subtitle(in: language))
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
                    Text(language.text(
                        english: "About \(minutes) minutes · guided step by step",
                        spanish: "Unos \(minutes) minutos · guiado paso a paso"
                    ))
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                // Purely visual CTA — the enclosing Button is the interaction.
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                    Text(language.text(
                        english: "Start the scene",
                        spanish: "Empezar la escena"
                    ))
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
        language.text(
            english: "Learn one short answer, say it, and see what MA understood before using it with a waiter.",
            spanish: "Aprendes una respuesta corta, la dices y MA te muestra qué entendió antes de usarla con un mesero."
        )
    }

    private var lessonArc: String {
        language.text(
            english: "UNDERSTAND → LISTEN → SPEAK → GET FEEDBACK → RESPOND",
            spanish: "ENTIENDE → ESCUCHA → DI → RECIBE FEEDBACK → RESPONDE"
        )
    }

    private var accessibilitySummary: String {
        var parts = [
            language.text(
                english: "Scene \(scene.index), available: \(scene.title(in: language)).",
                spanish: "Escena \(scene.index), disponible: \(scene.title(in: language))."
            ),
            situationOutcome,
            language.text(
                english: "The path: understand, listen, say the phrase, get feedback, and respond.",
                spanish: "El camino: entiende, escucha, di la frase, recibe feedback y responde."
            ),
        ]
        if let minutes = scene.minutes {
            parts.append(language.text(
                english: "About \(minutes) minutes, guided step by step.",
                spanish: "Unos \(minutes) minutos, guiado paso a paso."
            ))
        }
        return parts.joined(separator: " ")
    }
}
