import SwiftUI
import UIKit

struct GuidedLessonView: View {
    let feature: GuidedLessonFeature
    var onExit: (() -> Void)?
    var onToggleLanguage: (() -> Void)?
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(
                badge: feature.state.sourceBadge(in: language),
                onExit: onExit,
                onToggleLanguage: onToggleLanguage
            )
            content
        }
        .background(MATheme.paper)
    }

    @ViewBuilder
    private var content: some View {
        switch feature.state.phase {
        case .orientation:
            GuidedOrientationScreen(send: feature.send)
        case .model(let step):
            GuidedModelScreen(state: feature.state, step: step, send: feature.send)
        case .attempt(let context, let step):
            GuidedAttemptScreen(
                state: feature.state,
                context: context,
                step: step,
                send: feature.send
            )
        case .situationBrief:
            GuidedSituationBriefScreen(state: feature.state, send: feature.send)
        case .tutorTurn(let step):
            GuidedTutorTurnScreen(state: feature.state, step: step, send: feature.send)
        case .complete:
            GuidedCompleteScreen(state: feature.state, send: feature.send)
        }
    }
}

private struct GuidedOrientationScreen: View {
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    MicroCapsLabel(text: language.text(
                        english: "TODAY’S GOAL",
                        spanish: "OBJETIVO DE HOY"
                    ), color: MATheme.ai)
                    Text(language.text(
                        english: "Say you’re dining alone.",
                        spanish: "Di que vienes solo."
                    ))
                        .font(MATheme.display())
                        .foregroundStyle(MATheme.sumi)
                    Text(language.text(
                        english: "You’ll learn one short answer. MA will review your attempt before you move on.",
                        spanish: "Aprenderás una respuesta corta. MA revisará tu intento antes de avanzar."
                    ))
                        .font(MATheme.body(17, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    teachingPromise
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 30)

                Spacer(minLength: 32)
                PrimaryButton(
                    title: language.text(
                        english: "Show my phrase",
                        spanish: "Ver mi frase"
                    ),
                    identifier: "guided.cta.show-phrase"
                ) {
                    send(.showPhrase)
                } icon: {
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 12)
            }
        }
    }

    private var teachingPromise: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(language.text(
                english: "Listen to a short model",
                spanish: "Escucha un modelo corto"
            ), systemImage: "speaker.wave.2.fill")
            Label(language.text(
                english: "Say the phrase when you decide",
                spanish: "Di la frase cuando tú decidas"
            ), systemImage: "mic.fill")
            Label(language.text(
                english: "See what MA understood and one useful adjustment",
                spanish: "Lee qué entendió MA y un ajuste útil"
            ), systemImage: "checkmark.bubble.fill")
        }
        .font(MATheme.body(15, weight: .medium))
        .foregroundStyle(MATheme.sumi)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 18))
        .padding(.top, 12)
    }
}

private struct GuidedModelScreen: View {
    let state: GuidedLessonState
    let step: GuidedModelStep
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    MicroCapsLabel(text: language.text(
                        english: "LISTEN FIRST",
                        spanish: "ESCUCHA PRIMERO"
                    ), color: MATheme.ai)
                    Text(state.targetJapanese)
                        .font(MATheme.jp(40))
                        .foregroundStyle(MATheme.sumi)
                    Text(state.targetRomaji)
                        .font(MATheme.heading(weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    Text(language == .english ? state.targetEnglish : state.targetSpanish)
                        .font(MATheme.heading())
                    Divider()
                    Text(language.text(
                        english: "Listen for hi-to-ri / de-su. You don’t need to memorize it yet.",
                        spanish: "Escucha hi-to-ri / de-su. No tienes que memorizarlo todavía."
                    ))
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(22)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                if step == .completed {
                    Button {
                        send(.playModel)
                    } label: {
                        Label(language.text(
                            english: "Listen again",
                            spanish: "Escuchar de nuevo"
                        ), systemImage: "speaker.wave.2")
                            .font(MATheme.body(15, weight: .semibold))
                            .foregroundStyle(MATheme.ai)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("guided.audio.model-replay")
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 14)
                }

                Spacer(minLength: 28)
                PrimaryButton(
                    title: primaryTitle,
                    identifier: step == .completed
                        ? "guided.cta.try-voice" : "guided.audio.model"
                ) {
                    send(step == .completed ? .beginAttempt : .playModel)
                } icon: {
                    Image(systemName: step == .completed ? "mic.fill" : "speaker.wave.2.fill")
                }
                .disabled(step == .playing)
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 12)
            }
        }
    }

    private var primaryTitle: String {
        switch step {
        case .ready:
            language.text(english: "Listen to MA", spanish: "Escuchar a MA")
        case .playing:
            language.text(english: "Listening…", spanish: "Escuchando…")
        case .completed:
            language.text(english: "Try it aloud", spanish: "Probar con mi voz")
        }
    }
}

private struct GuidedAttemptScreen: View {
    let state: GuidedLessonState
    let context: GuidedAttemptContext
    let step: GuidedAttemptStep
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                header
                bodyContent
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 22)
                Spacer(minLength: 24)
                controls
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.bottom, 12)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: headerLabel, color: MATheme.ai)
            Text(headerTitle)
                .font(MATheme.title())
                .foregroundStyle(MATheme.sumi)
            if context == .restaurantTurn {
                Text(language.text(
                    english: "The server has finished. Answer that it’s one person.",
                    spanish: "El mesero ya terminó. Responde que eres una persona."
                ))
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
            }
        }
        .padding(.horizontal, MATheme.sideMargin)
        .padding(.top, 26)
    }

    @ViewBuilder
    private var bodyContent: some View {
        switch step {
        case .ready, .requestingPermission, .recording:
            targetCard
            if case .recording = step {
                HStack(spacing: 10) {
                    Circle().fill(.red).frame(width: 10, height: 10)
                    Text(language.text(
                        english: "I’m listening. Say the phrase once, then tap Finish.",
                        spanish: "Te escucho. Di la frase una vez y toca terminar."
                    ))
                        .font(MATheme.body(15, weight: .semibold))
                }
                .foregroundStyle(MATheme.sumi)
                .padding(.top, 18)
            } else {
                privacyNote.padding(.top, 16)
            }

        case .reviewing:
            VStack(alignment: .leading, spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(MATheme.ai)
                Text(language.text(
                    english: "I’m comparing it with \(state.targetJapanese).",
                    spanish: "Estoy comparándolo con \(state.targetJapanese)."
                ))
                    .font(MATheme.heading())
                Text(language.text(
                    english: "The transcript is an approximate guide and may be wrong. MA does not generate pronunciation scores.",
                    spanish: "La transcripción es una guía aproximada y puede equivocarse. MA no genera puntuaciones de pronunciación."
                ))
                    .font(MATheme.body(15, weight: .regular))
                    .foregroundStyle(MATheme.stone)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))

        case .feedback(let result):
            feedbackCards(result)

        case .recoverableError(let failure):
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(MATheme.ai)
                Text(failure.message(in: language))
                    .font(MATheme.body(17, weight: .regular))
                    .foregroundStyle(MATheme.sumi)
                if failure == .microphoneDenied {
                    Button(language.text(english: "Open Settings", spanish: "Abrir Ajustes")) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .font(MATheme.body(15, weight: .semibold))
                    .foregroundStyle(MATheme.ai)
                    .accessibilityIdentifier("guided.cta.settings")
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: language.text(
                english: "YOUR ANSWER",
                spanish: "TU RESPUESTA"
            ))
            Text(state.targetJapanese)
                .font(MATheme.jp(34))
            Text(state.targetRomaji)
                .font(MATheme.body(17, weight: .regular))
                .foregroundStyle(MATheme.stone)
            Text(language == .english ? state.targetEnglish : state.targetSpanish)
                .font(MATheme.body(16, weight: .semibold))
            Text(language.text(
                english: "MA will show what it understood and one useful adjustment.",
                spanish: "MA te mostrará lo que entendió y un solo ajuste útil."
            ))
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
    }

    private var privacyNote: some View {
        Label(
            language.text(
                english: "When you record, this short turn goes directly to OpenAI for transcription and review. MA does not save it as a file.",
                spanish: "Al grabar, este turno breve se envía directo a OpenAI para transcripción y revisión. MA no lo guarda como archivo."
            ),
            systemImage: "lock.shield.fill"
        )
        .font(MATheme.caption())
        .foregroundStyle(MATheme.stone)
    }

    private func feedbackCards(_ result: GuidedRealtimeReviewResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            feedbackCard(
                label: language.text(
                    english: "MA APPROXIMATELY UNDERSTOOD",
                    spanish: "MA ENTENDIÓ APROXIMADAMENTE"
                ),
                text: result.approximateTranscript
                    ?? result.review.heardJapanese
                    ?? language.text(
                        english: "I couldn’t recognize words clearly enough.",
                        spanish: "No pude reconocer palabras con suficiente claridad."
                    )
            )
            feedbackCard(
                label: language.text(english: "WHAT WORKED", spanish: "LO QUE FUNCIONÓ"),
                text: result.review.positive(in: language)
            )
            feedbackCard(
                label: language.text(
                    english: "FOR YOUR NEXT TRY",
                    spanish: "PARA EL SIGUIENTE INTENTO"
                ),
                text: result.review.retryFocus(in: language)
                    ?? result.review.correction(in: language)
                    ?? language.text(
                        english: "Say the phrase once more, at the same pace.",
                        spanish: "Repite la frase una vez, con el mismo ritmo."
                    )
            )
            if state.audioState == .playingRealtime {
                Label(language.text(
                    english: "MA is explaining this adjustment…",
                    spanish: "MA está explicando este ajuste…"
                ), systemImage: "waveform")
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(MATheme.ai)
            } else if state.spokenFeedbackUnavailable {
                Text(language.text(
                    english: "The review is complete on screen; its audio wasn’t available.",
                    spanish: "La revisión está completa en pantalla; su audio no estuvo disponible."
                ))
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            }
        }
    }

    private func feedbackCard(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            MicroCapsLabel(text: label, color: MATheme.ai)
            Text(text)
                .font(MATheme.body(16, weight: .regular))
                .foregroundStyle(MATheme.sumi)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var controls: some View {
        switch step {
        case .ready:
            PrimaryButton(title: language.text(
                english: "Record my attempt",
                spanish: "Grabar mi intento"
            ), identifier: "guided.capture.start") {
                send(.beginAttempt)
            } icon: {
                Image(systemName: "mic.fill")
            }
        case .requestingPermission:
            PrimaryButton(title: language.text(
                english: "Waiting for permission…",
                spanish: "Esperando permiso…"
            ), identifier: "guided.capture.permission") {} icon: {
                ProgressView().tint(.white)
            }
            .disabled(true)
        case .recording:
            PrimaryButton(title: language.text(
                english: "Finish and review",
                spanish: "Terminar y revisar"
            ), identifier: "guided.capture.stop") {
                send(.finishAttempt)
            } icon: {
                Image(systemName: "stop.fill")
            }
        case .reviewing:
            PrimaryButton(title: language.text(
                english: "Reviewing your attempt…",
                spanish: "Revisando tu intento…"
            ), identifier: "guided.review.pending") {} icon: {
                ProgressView().tint(.white)
            }
            .disabled(true)
        case .feedback(let result):
            feedbackControls(result)
        case .recoverableError:
            if state.feedbackTransition == .retrying {
                PrimaryButton(title: language.text(
                    english: "Preparing another attempt…",
                    spanish: "Preparando otro intento…"
                ), identifier: "guided.feedback.transition") {} icon: {
                    ProgressView().tint(.white)
                }
                .disabled(true)
            } else {
                PrimaryButton(title: language.text(
                    english: "Record again",
                    spanish: "Grabar de nuevo"
                ), identifier: "guided.capture.retry-error") {
                    send(.retryAttempt)
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackControls(_ result: GuidedRealtimeReviewResult) -> some View {
        if let transition = state.feedbackTransition {
            PrimaryButton(title: transition == .retrying
                ? language.text(
                    english: "Preparing another attempt…",
                    spanish: "Preparando otro intento…"
                )
                : language.text(
                    english: "Preparing the next turn…",
                    spanish: "Preparando el siguiente turno…"
                ), identifier: "guided.feedback.transition") {} icon: {
                ProgressView().tint(.white)
            }
            .disabled(true)
        } else if result.review.targetMatch == .different
                    || result.review.targetMatch == .unclear {
            PrimaryButton(title: language.text(
                english: "Try again",
                spanish: "Intentar otra vez"
            ), identifier: "guided.feedback.retry") {
                send(.retryAttempt)
            } icon: {
                Image(systemName: "arrow.clockwise")
            }
            secondaryButton(
                context == .taughtPhrase
                    ? language.text(
                        english: "Enter with the answer visible",
                        spanish: "Entrar con la respuesta visible"
                    )
                    : language.text(
                        english: "Finish with the answer visible",
                        spanish: "Terminar con la respuesta visible"
                    ),
                identifier: "guided.feedback.continue-supported"
            ) {
                send(.continueWithFeedback)
            }
        } else {
            PrimaryButton(
                title: context == .taughtPhrase
                    ? language.text(
                        english: "Use it in the restaurant",
                        spanish: "Usarlo en el restaurante"
                    )
                    : language.text(
                        english: "Finish the scene",
                        spanish: "Terminar la escena"
                    ),
                identifier: "guided.feedback.continue"
            ) {
                send(.continueWithFeedback)
            } icon: {
                Image(systemName: "arrow.right")
            }
            secondaryButton(language.text(
                english: "Try again",
                spanish: "Intentar otra vez"
            ), identifier: "guided.feedback.retry") {
                send(.retryAttempt)
            }
        }
    }

    private func secondaryButton(
        _ title: String,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(MATheme.body(15, weight: .semibold))
                .foregroundStyle(MATheme.ai)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var headerLabel: String {
        switch step {
        case .reviewing:
            language.text(english: "REVIEWING YOUR ATTEMPT", spanish: "REVISANDO TU INTENTO")
        case .feedback:
            language.text(english: "MA’S FEEDBACK", spanish: "RETROALIMENTACIÓN DE MA")
        case .recoverableError:
            language.text(english: "ATTEMPT NOT REVIEWED", spanish: "INTENTO SIN REVISAR")
        default:
            context == .restaurantTurn
                ? language.text(
                    english: "YOUR ANSWER TO THE SERVER",
                    spanish: "TU RESPUESTA AL MESERO"
                )
                : language.text(english: "YOUR TURN", spanish: "TU TURNO")
        }
    }

    private var headerTitle: String {
        switch step {
        case .recording:
            language.text(english: "I’m listening.", spanish: "Te escucho.")
        case .reviewing:
            language.text(english: "One moment.", spanish: "Un momento.")
        case .feedback:
            language.text(english: "This is what MA heard.", spanish: "Esto oyó MA.")
        case .recoverableError:
            language.text(
                english: "We’re staying with the same phrase.",
                spanish: "Seguimos en la misma frase."
            )
        default:
            language.text(
                english: "Say: \(state.targetJapanese)",
                spanish: "Di: \(state.targetJapanese)"
            )
        }
    }
}

private struct GuidedSituationBriefScreen: View {
    let state: GuidedLessonState
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    MicroCapsLabel(text: language.text(
                        english: "NOW AT THE RESTAURANT",
                        spanish: "AHORA EN EL RESTAURANTE"
                    ), color: MATheme.ai)
                    Text(language.text(
                        english: "You know what to do.",
                        spanish: "Ya sabes qué hacer."
                    ))
                        .font(MATheme.display())
                    Text(language.text(
                        english: "Your task: listen to the full question. Then answer that it’s one person.",
                        spanish: "Tu tarea: escucha la pregunta completa. Después responde que eres una persona."
                    ))
                        .font(MATheme.body(17, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                waiterCard
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 24)
                answerCard
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 12)

                Spacer(minLength: 28)
                PrimaryButton(title: language.text(
                    english: "Listen to the server",
                    spanish: "Escuchar al mesero"
                ), identifier: "guided.waiter.play") {
                    send(.playWaiterTurn)
                } icon: {
                    Image(systemName: "play.fill")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 12)
            }
        }
    }

    private var waiterCard: some View {
        phraseCard(
            label: language.text(english: "YOU’LL HEAR", spanish: "VAS A OÍR"),
            japanese: state.waiterJapanese,
            romaji: state.waiterRomaji,
            meaning: language == .english ? state.waiterEnglish : state.waiterSpanish
        )
    }

    private var answerCard: some View {
        phraseCard(
            label: language.text(english: "YOUR ANSWER", spanish: "TU RESPUESTA"),
            japanese: state.targetJapanese,
            romaji: state.targetRomaji,
            meaning: language == .english ? state.targetEnglish : state.targetSpanish
        )
    }

    private func phraseCard(
        label: String,
        japanese: String,
        romaji: String,
        meaning: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            MicroCapsLabel(text: label, color: MATheme.ai)
            Text(japanese).font(MATheme.jp(26))
            Text(romaji).font(MATheme.caption()).foregroundStyle(MATheme.stone)
            Text(meaning).font(MATheme.body(15, weight: .semibold))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct GuidedTutorTurnScreen: View {
    let state: GuidedLessonState
    let step: GuidedTutorTurnStep
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: language.text(
                        english: "SERVER’S TURN · REALTIME",
                        spanish: "TURNO DEL MESERO · REALTIME"
                    ), color: MATheme.ai)
                    Text(title)
                        .font(MATheme.display())
                    Text(language.text(
                        english: "Your task stays visible: answer that it’s one person after the server finishes.",
                        spanish: "Tu tarea sigue visible: después responde que eres una persona."
                    ))
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 8) {
                    MicroCapsLabel(text: language.text(
                        english: "CAPTIONS AND MEANING",
                        spanish: "SUBTÍTULOS Y SIGNIFICADO"
                    ))
                    Text(state.waiterJapanese).font(MATheme.jp(30))
                    Text(state.waiterRomaji)
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                    Text(language == .english ? state.waiterEnglish : state.waiterSpanish)
                        .font(MATheme.heading())
                    Divider().padding(.vertical, 4)
                    Text(language.text(
                        english: "Answer: \(state.targetJapanese) · \(state.targetRomaji)",
                        spanish: "Responde: \(state.targetJapanese) · \(state.targetRomaji)"
                    ))
                        .font(MATheme.body(16, weight: .semibold))
                }
                .padding(20)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                Spacer(minLength: 28)
                control
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.bottom, 12)
            }
        }
    }

    @ViewBuilder
    private var control: some View {
        switch step {
        case .ready, .recoverableError:
            PrimaryButton(title: language.text(
                english: "Listen to the server",
                spanish: "Escuchar al mesero"
            ), identifier: "guided.waiter.retry") {
                send(.playWaiterTurn)
            } icon: {
                Image(systemName: "play.fill")
            }
        case .preparing:
            PrimaryButton(title: language.text(
                english: "Preparing the turn…",
                spanish: "Preparando el turno…"
            ), identifier: "guided.waiter.preparing") {} icon: {
                ProgressView().tint(.white)
            }
            .disabled(true)
        case .speaking:
            PrimaryButton(title: language.text(
                english: "Listening to the server…",
                spanish: "Escuchando al mesero…"
            ), identifier: "guided.waiter.speaking") {} icon: {
                Image(systemName: "waveform")
            }
            .disabled(true)
        case .responseReady:
            PrimaryButton(title: language.text(
                english: "Answer now",
                spanish: "Responder ahora"
            ), identifier: "guided.waiter.respond") {
                send(.beginAttempt)
            } icon: {
                Image(systemName: "mic.fill")
            }
        }
    }

    private var title: String {
        switch step {
        case .preparing:
            language.text(
                english: "MA is preparing a short question.",
                spanish: "MA prepara una pregunta corta."
            )
        case .speaking:
            language.text(english: "Listen to the question.", spanish: "Escucha la pregunta.")
        case .responseReady:
            language.text(
                english: "The server finished. Now you answer.",
                spanish: "El mesero terminó. Ahora respondes."
            )
        case .recoverableError:
            language.text(
                english: "The question didn’t play.",
                spanish: "La pregunta no se reprodujo."
            )
        case .ready:
            language.text(
                english: "Listen whenever you’re ready.",
                spanish: "Cuando quieras, escucha."
            )
        }
    }
}

private struct GuidedCompleteScreen: View {
    let state: GuidedLessonState
    let send: (GuidedLessonIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    MicroCapsLabel(text: language.text(
                        english: "SCENE COMPLETE",
                        spanish: "ESCENA COMPLETA"
                    ), color: MATheme.ai)
                    Text(language.text(
                        english: "You completed the exchange.",
                        spanish: "Ya hiciste el intercambio."
                    ))
                        .font(MATheme.display())
                    Text(language.text(
                        english: "You heard the question, answered, and received a review of your voice.",
                        spanish: "Escuchaste la pregunta, respondiste y recibiste una revisión de tu voz."
                    ))
                        .font(MATheme.body(17, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 30)

                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: language.text(
                        english: "TODAY’S PHRASE",
                        spanish: "FRASE DE HOY"
                    ))
                    Text(state.targetJapanese).font(MATheme.jp(34))
                    Text(state.targetRomaji).font(MATheme.heading(weight: .regular))
                    Text(reviewCountText)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                if let plannerStep = state.plannerStep {
                    plannerCard(plannerStep)
                        .padding(.horizontal, MATheme.sideMargin)
                        .padding(.top, 14)
                }

                Spacer(minLength: 24)
                PrimaryButton(title: language.text(
                    english: "Practice from the beginning",
                    spanish: "Practicar desde el inicio"
                ), identifier: "guided.restart") {
                    send(.restart)
                } icon: {
                    Image(systemName: "arrow.clockwise")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 12)
            }
        }
    }

    private var reviewCountText: String {
        let count = state.reviewedAttempts.count
        if language == .english {
            let noun = count == 1 ? "attempt" : "attempts"
            return "MA reviewed \(count) \(noun). No score or self-rating."
        }
        let noun = count == 1 ? "intento" : "intentos"
        return "MA revisó \(count) \(noun). Sin puntuación ni autocalificación."
    }

    private func plannerCard(_ step: GuidedPlannerStep) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                MicroCapsLabel(text: language.text(
                    english: "NEXT PRACTICE",
                    spanish: "SIGUIENTE PRÁCTICA"
                ), color: MATheme.ai)
                Spacer()
                MicroCapsLabel(text: sourceLabel(for: step))
            }
            Text(step.action.explanation(in: language))
                .font(MATheme.body(16, weight: .semibold))
                .foregroundStyle(MATheme.sumi)
                .fixedSize(horizontal: false, vertical: true)
            Text(step.action.evidenceReason(in: language))
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
                .fixedSize(horizontal: false, vertical: true)

            switch step {
            case .requesting:
                HStack(spacing: 8) {
                    ProgressView().tint(MATheme.ai)
                    Text(language.text(
                        english: "GPT-5.6 is preparing the bounded plan…",
                        spanish: "GPT-5.6 prepara el plan acotado…"
                    ))
                }
                .font(MATheme.caption(.semibold))
                .foregroundStyle(MATheme.ai)
                .accessibilityIdentifier("guided.plan.loading")
            case .local, .unavailable:
                Button {
                    send(.requestNextPlan)
                } label: {
                    Text(language.text(
                        english: "Improve my next practice with GPT-5.6",
                        spanish: "Mejorar mi siguiente práctica con GPT-5.6"
                    ))
                        .font(MATheme.body(15, weight: .semibold))
                        .foregroundStyle(MATheme.ai)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .overlay(Capsule().stroke(MATheme.ai.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("guided.plan.request")
                if case .unavailable = step {
                    Text(language.text(
                        english: "GPT-5.6 was unavailable, so your safe local plan stayed in place.",
                        spanish: "GPT-5.6 no estuvo disponible; por eso se conservó tu plan local seguro."
                    ))
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .accessibilityIdentifier("guided.plan.unavailable")
                }
            case .model:
                EmptyView()
            }

            Text(language.text(
                english: "Optional: sends only each stage’s qualitative result, context, and visible-help level. It does not resend audio, transcripts, or feedback text.",
                spanish: "Opcional: envía solo el resultado cualitativo, el contexto y la ayuda visible de cada etapa. No reenvía audio, transcripción ni comentarios."
            ))
                .font(MATheme.micro())
                .foregroundStyle(MATheme.stone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 18))
    }

    private func sourceLabel(for step: GuidedPlannerStep) -> String {
        switch step {
        case .model:
            "GPT-5.6"
        case .local, .requesting, .unavailable:
            language.text(english: "LOCAL PLAN", spanish: "PLAN LOCAL")
        }
    }
}
