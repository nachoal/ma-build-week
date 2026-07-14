import SwiftUI

/// The first-success moment: name what just happened before teaching anything
/// new. One screen, one claim, one action.
struct FirstSuccessView: View {
    let send: (PracticeIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        MicroCapsLabel(text: "PRIMER LOGRO", color: MATheme.ai)
                        Spacer()
                        InkGlyph()
                            .frame(width: 84, height: 64)
                    }
                    Text("Completaste tu primer intercambio guiado.")
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 34))
                        .foregroundStyle(MATheme.sumi)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Confirmaste tres repeticiones por tu cuenta; la última, sin texto. Esta maqueta no escuchó ni evaluó tu voz.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                exchangeRecap
                Spacer(minLength: 16)
                VStack(spacing: 10) {
                    PrimaryButton(title: "Seguir", identifier: "cta.exito.seguir") {
                        send(.acknowledgeFirstSuccess)
                    } icon: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("Siguiente: dos llaves para la velocidad natural.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 8)
            }
        }
    }

    private var exchangeRecap: some View {
        VStack(alignment: .leading, spacing: 14) {
            MicroCapsLabel(text: "TU INTERCAMBIO GUIADO")
                .padding(.top, 16)
                .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)

            recapRow(
                speaker: "TUTOR",
                japanese: RestaurantForOneFixture.questionLine.japanese,
                spanish: RestaurantForOneFixture.questionLine.spanish
            )
            recapRow(
                speaker: "TÚ",
                japanese: RestaurantForOneFixture.phraseJapanese,
                spanish: RestaurantForOneFixture.phraseSpanish,
                highlight: true
            )
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 26)
    }

    private func recapRow(
        speaker: String, japanese: String, spanish: String, highlight: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            MicroCapsLabel(text: speaker, color: highlight ? MATheme.ai : MATheme.stone)
                .frame(width: 44, alignment: .leading)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(japanese)
                    .font(MATheme.jp(20))
                    .foregroundStyle(MATheme.sumi)
                Text(spanish)
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Primer logro") {
    PracticeRootView(feature: .preview(through: .firstSuccess))
}
