import SwiftUI

/// The first-minute coached ladder: three rounds of the same exchange with
/// shrinking scaffold. The learner marks each attempt themself — the fixture
/// never claims to have heard anything.
struct CoachedPracticeView: View {
    let state: PracticeState
    let send: (PracticeIntent) -> Void

    private var roundNumber: Int { state.coachedAttempts.count + 1 }

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                header
                tutorPrompt
                answerScaffold
                Spacer(minLength: 12)
                bottomActions
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: state.coachedAttempts.count)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PRÁCTICA GUIADA · RONDA \(roundNumber) DE 3")
                    .font(MATheme.caption(.semibold))
                    .tracking(MATheme.capsTracking(fontSize: 13))
                    .foregroundStyle(MATheme.ai)
                Spacer()
            }
            scaffoldSteps
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    /// Non-color progress: the current rung is filled and wider.
    private var scaffoldSteps: some View {
        HStack(spacing: 6) {
            stepPill("FRASE", active: state.coachedScaffold == .full, done: state.coachedAttempts.contains(.full))
            stepPill("RITMO", active: state.coachedScaffold == .rhythmOnly, done: state.coachedAttempts.contains(.rhythmOnly))
            stepPill("DE MEMORIA", active: state.coachedScaffold == ScaffoldLevel.none, done: state.coachedAttempts.contains(ScaffoldLevel.none))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ronda \(roundNumber) de 3. Ayuda actual: \(state.coachedScaffold.spanishDescription).")
    }

    private func stepPill(_ label: String, active: Bool, done: Bool) -> some View {
        HStack(spacing: 4) {
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
            }
            Text(label)
                .font(MATheme.micro())
                .tracking(MATheme.capsTracking(fontSize: 10))
        }
        .foregroundStyle(active ? MATheme.ai : MATheme.stone)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(active ? MATheme.mist : .white, in: Capsule())
        .overlay(Capsule().stroke(active ? MATheme.ai : MATheme.hairline, lineWidth: 1))
    }

    private var tutorPrompt: some View {
        VStack(alignment: .leading, spacing: 6) {
            MicroCapsLabel(text: "LA PREGUNTA DEL TUTOR · TEXTO SIN AUDIO")
            Text(RestaurantForOneFixture.questionLine.japanese)
                .font(MATheme.jp(28))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(RestaurantForOneFixture.questionLine.romaji)
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                Text(RestaurantForOneFixture.questionLine.spanish)
                    .font(MATheme.caption(.medium))
                    .foregroundStyle(MATheme.sumi)
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 26)
    }

    @ViewBuilder
    private var answerScaffold: some View {
        VStack(alignment: .leading, spacing: 12) {
            MicroCapsLabel(text: "TU RESPUESTA · DILA EN VOZ ALTA", color: MATheme.ai)
                .padding(.top, 16)
                .overlay(Rectangle().fill(MATheme.hairline).frame(height: 1), alignment: .top)

            switch state.coachedScaffold {
            case .full:
                // Rail as overlay: its height tracks the phrase content, never
                // the screen's flexible whitespace.
                VStack(alignment: .leading, spacing: 8) {
                    Text(RestaurantForOneFixture.phraseJapanese)
                        .font(MATheme.jp(34))
                        .foregroundStyle(MATheme.sumi)
                    Text(RestaurantForOneFixture.phraseRomaji)
                        .font(MATheme.heading(weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    Text(RestaurantForOneFixture.phraseSpanish)
                        .font(MATheme.body())
                        .foregroundStyle(MATheme.sumi)
                }
                .padding(.leading, 20)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(MATheme.ai)
                        .frame(width: 4)
                }
                rhythmChips
            case .rhythmOnly:
                Text("Solo el ritmo. Ya la confirmaste una vez.")
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                rhythmChips
            case .none:
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sin texto. Respira y dila de memoria.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    // Deliberately empty of any answer text: just the ink
                    // motif as a breath cue.
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(MATheme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                        .frame(height: 64)
                        .overlay(
                            InkGlyph()
                                .frame(width: 52, height: 40)
                                .opacity(0.85)
                        )
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 24)
    }

    private var rhythmChips: some View {
        HStack(spacing: 8) {
            ForEach(RestaurantForOneFixture.rhythmBeats, id: \.self) { syllable in
                Text(syllable)
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(MATheme.ai)
                    .frame(width: 48)
                    .padding(.vertical, 8)
                    .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    @ViewBuilder
    private var bottomActions: some View {
        if state.coachedAwaitingAssessment {
            selfAssessment
        } else {
            VStack(spacing: 10) {
                PrimaryButton(title: "Ya dije mi respuesta", identifier: "cta.marcar.intento") {
                    send(.markCoachedAttempt)
                } icon: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(state.coachedRoundRetries > 0
                     ? "Sin prisa. Otra vez cuando quieras."
                     : "Tú marcas tu intento. El prototipo no te escucha.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, MATheme.sideMargin)
            .padding(.bottom, 8)
        }
    }

    /// The learner's own verdict decides progress — three "Me salió" taps are
    /// the only path to first success.
    private var selfAssessment: some View {
        VStack(spacing: 10) {
            Text("¿Cómo te salió?")
                .font(MATheme.body(16, weight: .semibold))
                .foregroundStyle(MATheme.sumi)
            HStack(spacing: 10) {
                Button {
                    send(.assessCoachedSuccess)
                } label: {
                    Text("Me salió")
                        .font(MATheme.body(16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(MATheme.ai, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cta.mesalio")

                Button {
                    send(.assessCoachedRetry)
                } label: {
                    Text("Necesito otra vez")
                        .font(MATheme.body(16, weight: .medium))
                        .foregroundStyle(MATheme.sumi)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .overlay(Capsule().stroke(MATheme.hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("cta.otravez")
            }
            Text("Tu propia valoración; nadie te está evaluando.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.bottom, 8)
    }
}

#Preview("Coached · frase completa") {
    PracticeRootView(feature: .preview(through: .coachedFull))
}

#Preview("Coached · solo ritmo") {
    PracticeRootView(feature: .preview(through: .coachedRhythm))
}

#Preview("Coached · de memoria") {
    PracticeRootView(feature: .preview(through: .coachedNoText))
}
