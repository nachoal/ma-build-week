import SwiftUI

/// Focused introduction of the two conversation keys — taught only after the
/// first success, right before natural-speed mode needs them.
struct ControlsIntroView: View {
    let send: (PracticeIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: "ANTES DE LA VELOCIDAD NATURAL", color: MATheme.ai)
                    Text("Tus dos llaves.")
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 34))
                        .foregroundStyle(MATheme.sumi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("A velocidad natural no entenderás cada palabra. Estas dos frases mantienen viva la conversación.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                VStack(alignment: .leading, spacing: 18) {
                    keyRow(
                        glyph: AnyView(haiGlyph),
                        japanese: "はい",
                        romaji: "hai",
                        claim: "«Te sigo, continúa.»",
                        note: "El tutor no se detiene. Es tu forma de acompañar."
                    )
                    keyRow(
                        glyph: AnyView(sumimasenGlyph),
                        japanese: "すみません",
                        romaji: "sumimasen",
                        claim: "«Pausa, necesito ayuda.»",
                        note: "El tutor te cede el turno y repasas lo último que oíste."
                    )
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                Spacer(minLength: 16)
                VStack(spacing: 10) {
                    PrimaryButton(title: "Ver la simulación natural", identifier: "cta.natural") {
                        send(.startListening)
                    } icon: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Secuencia visual sin audio · tocas tus llaves para marcar.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 8)
            }
        }
    }

    private func keyRow(
        glyph: AnyView, japanese: String, romaji: String, claim: String, note: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            glyph
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(japanese)
                        .font(MATheme.jp(22))
                        .foregroundStyle(MATheme.sumi)
                    Text(romaji)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                Text(claim)
                    .font(MATheme.body())
                    .foregroundStyle(MATheme.sumi)
                Text(note)
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var haiGlyph: some View {
        ZStack {
            Circle().stroke(MATheme.ai, lineWidth: 2).frame(width: 30, height: 30)
            Circle().stroke(MATheme.ai.opacity(0.45), lineWidth: 1.5).frame(width: 17, height: 17)
            Circle().fill(MATheme.ai).frame(width: 5, height: 5)
        }
    }

    private var sumimasenGlyph: some View {
        ZStack {
            Circle()
                .trim(from: 0.07, to: 0.93)
                .rotation(.degrees(180))
                .stroke(MATheme.ai, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 30, height: 30)
            Circle().fill(MATheme.ai).frame(width: 10, height: 10)
        }
    }
}

#Preview("Dos llaves") {
    PracticeRootView(feature: .preview(through: .controlsIntro))
}
