import SwiftUI
import UIKit

struct KaiwaLoopView: View {
    let feature: KaiwaLoopFeature
    var onExit: (() -> Void)?
    var onToggleLanguage: (() -> Void)?
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(
                badge: feature.state.sourceBadge,
                onExit: onExit,
                onToggleLanguage: onToggleLanguage
            )
            if feature.state.presentationSource == .labeledReplay {
                Text(language.text(
                    english: "Controlled visual replay · no microphone, network, or live audio.",
                    spanish: "Replay visual controlado · sin micrófono, red ni audio en vivo."
                ))
                    .font(MATheme.micro())
                    .foregroundStyle(MATheme.stone)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.vertical, 6)
                    .background(MATheme.mist)
                    .accessibilityIdentifier("kaiwa.replay.disclosure")
            }
            if let error = feature.state.lastError {
                ProductAudioErrorBanner(error: error)
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 8)
            }
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MATheme.paper)
    }

    @ViewBuilder
    private var content: some View {
        let state = feature.state
        if state.isLabeledReplay {
            KaiwaReplayContent(state: state, send: feature.send)
        } else {
            switch state.phase {
            case .setup:
                KaiwaSetupScreen(state: state, send: feature.send)
            case .coached:
                KaiwaCoachedScreen(state: state, send: feature.send)
            case .firstSuccess:
                KaiwaFirstSuccessScreen(state: state, send: feature.send)
            case .controls:
                KaiwaControlsScreen(state: state, send: feature.send)
            case .natural:
                KaiwaNaturalScreen(state: state, send: feature.send)
            case .repair:
                KaiwaRepairScreen(state: state, send: feature.send)
            case .resuming:
                KaiwaResumingScreen(state: state, send: feature.send)
            case .retry:
                KaiwaRetryScreen(state: state, send: feature.send)
            case .proof:
                KaiwaProofScreen(state: state, send: feature.send)
            }
        }
    }
}

/// The submission fallback has its own copy and controls so a sanitized
/// visual replay can never inherit learner, microphone, or playback claims
/// from the shipping local-product screens.
private struct KaiwaReplayContent: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    @ViewBuilder
    var body: some View {
        if state.phase == .proof {
            KaiwaReplayProofScreen(state: state, send: send)
        } else {
            KaiwaReplayStageScreen(state: state)
        }
    }
}

private struct KaiwaReplayStageScreen: View {
    let state: KaiwaLoopState
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: stageLabel, color: MATheme.ai)
                    Text(stageTitle)
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 36))
                        .foregroundStyle(MATheme.sumi)
                    Text(stageDetail)
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 26)

                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: cardLabel)
                    Text(cardJapanese)
                        .font(MATheme.jp(30))
                        .foregroundStyle(MATheme.sumi)
                    Text(cardRomaji)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                    if !cardMeaning.isEmpty {
                        Text(cardMeaning)
                            .font(MATheme.body(16, weight: .regular))
                            .foregroundStyle(MATheme.sumi)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)
                .accessibilityElement(children: .combine)

                Spacer(minLength: 20)
                Label(language.text(
                    english: "The replay advances through fixed sample events.",
                    spanish: "El replay avanza con eventos fijos de muestra."
                ), systemImage: "play.rectangle")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.bottom, 18)
                    .accessibilityIdentifier("kaiwa.replay.stage")
            }
        }
    }

    private var stageLabel: String {
        switch state.phase {
        case .setup: language.text(english: "VISUAL REPLAY · START", spanish: "REPLAY VISUAL · INICIO")
        case .coached: language.text(english: "VISUAL REPLAY · SAMPLE ANSWER", spanish: "REPLAY VISUAL · RESPUESTA DE MUESTRA")
        case .firstSuccess: language.text(english: "VISUAL REPLAY · FULL SUPPORT", spanish: "REPLAY VISUAL · ANDAMIO COMPLETO")
        case .controls: language.text(english: "VISUAL REPLAY · PAUSE RULE", spanish: "REPLAY VISUAL · REGLA DE PAUSA")
        case .natural: language.text(english: "VISUAL REPLAY · PAUSE POINT", spanish: "REPLAY VISUAL · PUNTO DE PAUSA")
        case .repair: language.text(english: "VISUAL REPLAY · CONTROLLED SEGMENT", spanish: "REPLAY VISUAL · SEGMENTO CONTROLADO")
        case .resuming: language.text(english: "VISUAL REPLAY · SAME TASK", spanish: "REPLAY VISUAL · MISMA OBLIGACIÓN")
        case .retry: language.text(english: "VISUAL REPLAY · SECOND SAMPLE", spanish: "REPLAY VISUAL · SEGUNDA MUESTRA")
        case .proof: language.text(english: "VISUAL REPLAY · RESULT", spanish: "REPLAY VISUAL · RESULTADO")
        }
    }

    private var stageTitle: String {
        switch state.phase {
        case .setup: language.text(english: "A sample introduces the phrase.", spanish: "Una muestra presenta la frase.")
        case .coached: language.text(english: "The sample reduces visible help in three steps.", spanish: "La ayuda se reduce en tres pasos.")
        case .firstSuccess: language.text(english: "The replay completed the support ladder.", spanish: "El replay completó el andamio.")
        case .controls: language.text(english: "The sample introduces pause and help.", spanish: "La muestra presenta pausa y ayuda.")
        case .natural: language.text(english: "The sample reaches the pause point.", spanish: "La muestra llega al punto de pausa.")
        case .repair: language.text(english: "The sample isolates a prepared segment.", spanish: "La muestra aísla un segmento preparado.")
        case .resuming: language.text(english: "The sample returns to the same situation.", spanish: "La muestra vuelve a la misma situación.")
        case .retry: language.text(english: "A second sample tries the same task.", spanish: "Una segunda muestra intenta lo mismo.")
        case .proof: language.text(english: "The replay finished.", spanish: "El replay terminó.")
        }
    }

    private var stageDetail: String {
        switch state.phase {
        case .setup:
            language.text(
                english: "This screen uses fixed text and timing; it requests no permission and plays no sound.",
                spanish: "Esta vista usa texto y tiempos fijos; no solicita permisos ni reproduce sonido."
            )
        case .coached:
            language.text(
                english: "The attempts are demonstration data. There is no learner voice, capture, or self-assessment.",
                spanish: "Los intentos son datos de demostración. No hay voz, captura ni autoevaluación del aprendiz."
            )
        case .firstSuccess:
            language.text(
                english: "Three fixed results show the historical guided flow; they are not viewer achievements.",
                spanish: "Tres resultados fijos muestran cómo termina la práctica guiada; no son logros del espectador."
            )
        case .controls:
            language.text(
                english: "The replay shows the historical rule without activating playout, microphone, or network.",
                spanish: "El replay muestra la regla del producto sin activar playout, micrófono ni red."
            )
        case .natural:
            language.text(
                english: "The fixed timeline shows where help would be requested; it does not represent played audio.",
                spanish: "La línea de tiempo fija demuestra dónde se pediría ayuda; no representa sonido reproducido."
            )
        case .repair:
            language.text(
                english: "This labeled segment is not an exact window of heard audio and does not play here.",
                spanish: "Este segmento etiquetado no es una ventana exacta de algo oído y no se reproduce aquí."
            )
        case .resuming:
            language.text(
                english: "The event keeps the fixed task of asking for a table for one; it activates no sound.",
                spanish: "El evento conserva la obligación de pedir mesa para una persona; no activa sonido."
            )
        case .retry:
            language.text(
                english: "The second sample’s values are fixed and do not belong to the viewer.",
                spanish: "Los valores de la segunda muestra son fijos y no pertenecen al espectador."
            )
        case .proof:
            language.text(english: "Fixed demonstration data.", spanish: "Datos fijos de demostración.")
        }
    }

    private var cardLabel: String {
        switch state.phase {
        case .repair: language.text(english: "SAMPLE SEGMENT TEXT", spanish: "TEXTO DEL SEGMENTO DE MUESTRA")
        case .resuming, .natural: language.text(english: "SAMPLE TEXT", spanish: "TEXTO DE LA MUESTRA")
        default: language.text(english: "SAMPLE PHRASE", spanish: "FRASE DE MUESTRA")
        }
    }

    private var cardJapanese: String {
        switch state.phase {
        case .repair, .resuming: state.repairSegment.japanese
        case .natural: RestaurantForOneFixture.continuationLine.japanese
        default: RestaurantForOneFixture.phraseJapanese
        }
    }

    private var cardRomaji: String {
        switch state.phase {
        case .repair, .resuming: state.repairSegment.romaji
        case .natural: RestaurantForOneFixture.continuationLine.romaji
        case .coached where state.scaffold == .rhythmOnly: "hi · to · ri · de · su"
        case .coached where state.scaffold == .none:
            language.text(english: "no text in the historical product", spanish: "sin texto en el producto")
        default: RestaurantForOneFixture.phraseRomaji
        }
    }

    private var cardMeaning: String {
        switch state.phase {
        case .repair, .resuming:
            language.text(english: "“This way, please.”", spanish: state.repairSegment.spanish)
        case .natural:
            language.text(
                english: "One person, correct? I’ll show you the way.",
                spanish: RestaurantForOneFixture.continuationLine.spanish
            )
        default:
            language.text(
                english: "One person · I’m dining alone.",
                spanish: RestaurantForOneFixture.phraseSpanish
            )
        }
    }
}

private struct KaiwaReplayProofScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: language.text(
                        english: "REPLAY COMPLETE · TWO SAMPLE ATTEMPTS",
                        spanish: "FIN DEL REPLAY · DOS INTENTOS DE MUESTRA"
                    ), color: MATheme.ai)
                    Text(language.text(
                        english: "The sample repaired and returned.",
                        spanish: "La muestra reparó y regresó."
                    ))
                        .font(MATheme.display())
                        .accessibilityIdentifier("kaiwa.replay.proof.title")
                    Text(language.text(
                        english: "This is fixed demonstration data: there was no learner, capture, sound, or assessment.",
                        spanish: "Son datos fijos de demostración: no hubo aprendiz, captura, sonido ni evaluación."
                    ))
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                if let first = state.completedPreRepairAttempt {
                    sampleCard(language.text(
                        english: "SAMPLE BEFORE REPAIR",
                        spanish: "MUESTRA ANTES DE LA REPARACIÓN"
                    ), attempt: first)
                        .padding(.top, 24)
                }
                if let second = state.completedPostRepairAttempt {
                    sampleCard(language.text(
                        english: "SAMPLE AFTER REPAIR",
                        spanish: "MUESTRA DESPUÉS DE LA REPARACIÓN"
                    ), attempt: second)
                        .padding(.top, 12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    MicroCapsLabel(text: language.text(
                        english: "CHANGE IN THE FIXED DATA",
                        spanish: "CAMBIO EN LOS DATOS FIJOS"
                    ))
                    Text(language.text(
                        english: "The second sample starts earlier and completes the same fixed task after repair.",
                        spanish: "La segunda muestra empieza antes y completa la misma obligación después de la reparación."
                    ))
                        .font(MATheme.heading())
                    Text(language.text(
                        english: "This comparison describes the fixture, not the person watching the replay.",
                        spanish: "Esta comparación describe el fixture; no describe a quien mira el replay."
                    ))
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 20)

                if let action = state.nextLearningAction {
                    VStack(alignment: .leading, spacing: 8) {
                        MicroCapsLabel(text: language.text(
                            english: "PLAN · CONTROLLED REPLAY",
                            spanish: "PLAN · REPLAY CONTROLADO"
                        ), color: MATheme.ai)
                        Text(planExplanation(for: action))
                            .font(MATheme.heading())
                        Text(planEvidence(for: action))
                            .font(MATheme.caption())
                            .foregroundStyle(MATheme.stone)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 16)
                }

                Spacer(minLength: 16)
                PrimaryButton(title: language.text(
                    english: "Restart replay",
                    spanish: "Reiniciar replay"
                ), identifier: "kaiwa.cta.restart") {
                    send(.restart)
                } icon: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }

    private func sampleCard(
        _ title: String,
        attempt: PracticeAttemptEvidence
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: title, color: MATheme.ai)
            Label(language.text(
                english: "Fixed demonstration result",
                spanish: "Resultado fijo de demostración"
            ), systemImage: "checkmark.circle.fill")
                .font(MATheme.body(16, weight: .semibold))
            Text(language.text(
                english: "Sample duration: \(attempt.capturedDuration.formatted(.number.precision(.fractionLength(1)))) s",
                spanish: "Duración de muestra: \(attempt.capturedDuration.formatted(.number.precision(.fractionLength(1)))) s"
            ))
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
            if let onset = attempt.estimatedVoiceOnset {
                Text(language.text(
                    english: "Sample onset: \(onset.formatted(.number.precision(.fractionLength(1)))) s",
                    spanish: "Inicio de muestra: \(onset.formatted(.number.precision(.fractionLength(1)))) s"
                ))
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            }
            Text(language.text(
                english: "The replay did not capture or discard audio.",
                spanish: "El replay no capturó ni descartó audio."
            ))
                .font(MATheme.micro())
                .foregroundStyle(MATheme.stone)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, MATheme.sideMargin)
    }

    private func planExplanation(for action: NextLearningAction) -> String {
        if language == .spanish { return action.explanationES }
        return switch action.action {
        case .repeatLesson: "Repeat the same answer before changing situations."
        case .reduceScaffold: "Try again with less visible help."
        case .isolateSegment: "Isolate one short part before returning to the situation."
        case .advance: "The fixed data advances to the next practice objective."
        case .abstain: "Keep the local plan because there are not enough facts."
        }
    }

    private func planEvidence(for action: NextLearningAction) -> String {
        if language == .spanish { return action.evidenceReasonES }
        return switch action.reason {
        case .completedAfterRepair: "The fixed sample completed the same task after repair."
        case .incompleteSelfReport: "The latest fixed sample is marked incomplete."
        case .speechPresenceMissing: "The fixture contains no local speech-presence signal."
        case .scaffoldStillPresent: "The latest fixed sample still used visible help."
        case .repairNeeded: "The fixed sample remained incomplete after requesting help."
        case .insufficientEvidence: "The available fixture facts do not justify changing the objective."
        }
    }
}

private struct KaiwaSetupScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: RestaurantForOneFixture.sceneKicker, color: MATheme.ai)
                    Text(RestaurantForOneFixture.goal)
                        .font(MATheme.display())
                        .tracking(MATheme.tightTracking(fontSize: 36))
                        .foregroundStyle(MATheme.sumi)
                    Text("Primero escucha una frase pequeña. Después la dirás con menos ayuda cada vez.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                phraseCard
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 28)

                Spacer(minLength: 18)
                VStack(spacing: 10) {
                    PrimaryButton(title: "Practicar con mi voz", identifier: "kaiwa.cta.practicar") {
                        send(.beginCoachedPractice)
                    } icon: {
                        Image(systemName: "arrow.right")
                    }
                    Text("El micrófono se pedirá solo cuando empieces tu primer intento.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }

    private var phraseCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroCapsLabel(text: "TU FRASE")
            Text(RestaurantForOneFixture.phraseJapanese)
                .font(MATheme.jp(38))
                .foregroundStyle(MATheme.sumi)
            Text(RestaurantForOneFixture.phraseRomaji)
                .font(MATheme.heading(weight: .regular))
                .foregroundStyle(MATheme.stone)
            Text(RestaurantForOneFixture.phraseSpanish)
                .font(MATheme.body())
                .foregroundStyle(MATheme.sumi)
            Button {
                send(.playModel)
            } label: {
                Label(
                    state.audioState == .playing(.hitoriDesu)
                        ? "Escuchando…"
                        : (state.playedPrompts.contains(.hitoriDesu)
                            ? "Escuchar de nuevo" : "Escuchar el modelo"),
                    systemImage: state.audioState == .playing(.hitoriDesu)
                        ? "waveform" : "speaker.wave.2"
                )
                .font(MATheme.body(16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .padding(.vertical, 4)
                .background(MATheme.ai, in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(state.isCapturing || state.isRequestingPermission || state.isPlaying)
            .accessibilityIdentifier("kaiwa.audio.modelo")
            .accessibilityValue(
                state.audioState == .playing(.hitoriDesu)
                    ? "Reproduciendo"
                    : (state.playedPrompts.contains(.hitoriDesu) ? "Reproducido" : "Listo")
            )
            MicroCapsLabel(text: BundledPrompt.hitoriDesu.provenanceLabel, color: MATheme.ai)
        }
        .padding(20)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct KaiwaCoachedScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    private var round: Int { min(3, state.successfulScaffolds.count + 1) }

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: "PRÁCTICA GUIADA · RONDA \(round) DE 3", color: MATheme.ai)
                    Text("¿Cuántas personas?")
                        .font(MATheme.title())
                        .foregroundStyle(MATheme.sumi)
                    Text("Tutor: \(RestaurantForOneFixture.questionLine.japanese) · \(RestaurantForOneFixture.questionLine.romaji)")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                answerScaffold
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 28)

                Spacer(minLength: 18)
                attemptControls
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    private var answerScaffold: some View {
        VStack(alignment: .leading, spacing: 12) {
            MicroCapsLabel(text: "TU RESPUESTA · EN VOZ ALTA", color: MATheme.ai)
            switch state.scaffold {
            case .full:
                Text(RestaurantForOneFixture.phraseJapanese)
                    .font(MATheme.jp(34))
                Text(RestaurantForOneFixture.phraseRomaji)
                    .font(MATheme.heading(weight: .regular))
                    .foregroundStyle(MATheme.stone)
                Text(RestaurantForOneFixture.phraseSpanish)
                    .font(MATheme.body())
            case .rhythmOnly:
                Text("hi · to · ri · de · su")
                    .font(MATheme.title())
                    .foregroundStyle(MATheme.ai)
                Text("Solo el ritmo. La frase ya no está a la vista.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            case .none:
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MATheme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    .frame(height: 90)
                    .overlay(InkGlyph().frame(width: 64, height: 50))
                    .accessibilityLabel("Sin texto. Responde de memoria.")
                Text("Sin texto. Respira y responde de memoria.")
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
            }
            Button {
                send(.playModel)
            } label: {
                Label(
                    state.audioState == .playing(.hitoriDesu)
                        ? "Escuchando…"
                        : (state.playedPrompts.contains(.hitoriDesu)
                            ? "Escuchar de nuevo" : "Escuchar el modelo"),
                    systemImage: state.audioState == .playing(.hitoriDesu)
                        ? "waveform" : "speaker.wave.2"
                )
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(MATheme.ai)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(state.isCapturing || state.isRequestingPermission || state.isPlaying)
        }
    }

    @ViewBuilder
    private var attemptControls: some View {
        if state.awaitingSelfAssessment {
            VStack(spacing: 10) {
                if let receipt = state.pendingReceipt {
                    LocalCaptureDisclosure(receipt: receipt)
                }
                Text("¿Completaste la frase?")
                    .font(MATheme.body(16, weight: .semibold))
                HStack(spacing: 10) {
                    assessmentButton("Sí, me salió", filled: true, id: "kaiwa.assess.ok") {
                        send(.assessSuccess)
                    }
                    assessmentButton("Otra vez", filled: false, id: "kaiwa.assess.retry") {
                        send(.assessRetry)
                    }
                }
                Text("Tu respuesta decide el avance; MA no califica tu pronunciación.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .multilineTextAlignment(.center)
            }
        } else {
            VStack(spacing: 10) {
                PrimaryButton(
                    title: state.isRequestingPermission
                        ? "Esperando permiso…"
                        : (state.isCapturing ? "Terminar mi intento" : "Grabar mi respuesta"),
                    identifier: state.isCapturing ? "kaiwa.capture.stop" : "kaiwa.capture.start"
                ) {
                    send(state.isCapturing ? .finishAttempt : .startAttempt)
                } icon: {
                    Image(systemName: state.isRequestingPermission
                          ? "ellipsis" : (state.isCapturing ? "stop.fill" : "mic.fill"))
                }
                .disabled(state.isRequestingPermission)
                Text(state.isCapturing
                     ? "Escuchando solo hasta 8 segundos. Toca terminar cuando acabes."
                     : "Audio local: se conserva presencia y tiempo aproximado, nunca la grabación.")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func assessmentButton(
        _ title: String,
        filled: Bool,
        id: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(MATheme.body(15, weight: .semibold))
                .foregroundStyle(filled ? .white : MATheme.sumi)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(filled ? MATheme.ai : .white, in: Capsule())
                .overlay(Capsule().stroke(filled ? MATheme.ai : MATheme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

private struct KaiwaFirstSuccessScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    MicroCapsLabel(text: "PRIMER INTERCAMBIO", color: MATheme.ai)
                    Text("Ya respondiste sin leer.")
                        .font(MATheme.display())
                        .foregroundStyle(MATheme.sumi)
                    Text(RestaurantForOneFixture.phraseJapanese)
                        .font(MATheme.jp(34))
                    Text("Tres éxitos confirmados por ti. La app solo registró señales locales de voz; no puntuó tu japonés.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 32)
                Spacer(minLength: 24)
                PrimaryButton(title: "Entrar a la conversación", identifier: "kaiwa.cta.controls") {
                    send(.acknowledgeFirstSuccess)
                } icon: {
                    Image(systemName: "arrow.right")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct KaiwaControlsScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: "ANTES DE LA VELOCIDAD NATURAL", color: MATheme.ai)
                    Text("Una llave: pausa y ayuda.")
                        .font(MATheme.display())
                        .foregroundStyle(MATheme.sumi)
                    Text("Cuando el japonés se vuelva ruido, toca el botón. El audio local se detiene y MA repasa un segmento preparado de esta escena.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Pausa y ayuda", systemImage: "hand.raised.fill")
                        .font(MATheme.heading())
                        .foregroundStyle(MATheme.ai)
                    Text("No es una conversación en vivo y no hablas encima del tutor. Tú eliges el punto de pausa.")
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                    MicroCapsLabel(text: "AUDIO LOCAL · SIN REALTIME")
                }
                .padding(20)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 30)

                Spacer(minLength: 20)
                PrimaryButton(title: "Escuchar la escena natural", identifier: "kaiwa.cta.natural") {
                    send(.startNatural)
                } icon: {
                    Image(systemName: "play.fill")
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct KaiwaNaturalScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: "ESCENA NATURAL · AUDIO INCLUIDO", color: MATheme.ai)
                    Text(state.isPlaying ? "Escucha la intención." : "La toma terminó.")
                        .font(MATheme.display())
                        .foregroundStyle(MATheme.sumi)
                    Text("No necesitas entender cada palabra. Marca el momento en que necesitas ayuda.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                VStack(spacing: 18) {
                    InkGlyph()
                        .frame(width: 160, height: 120)
                        .symbolEffect(
                            .pulse,
                            options: .repeating,
                            isActive: state.isPlaying && !reduceMotion
                        )
                    MicroCapsLabel(text: BundledPrompt.tutorTurn.provenanceLabel, color: MATheme.ai)
                    TutorCaptionCard(line: RestaurantForOneFixture.continuationLine)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 46)

                Spacer(minLength: 20)
                VStack(spacing: 10) {
                    if state.canPauseNaturalAudio {
                        PrimaryButton(title: "Pausa y ayuda", identifier: "kaiwa.cta.repair") {
                            send(.pauseForRepair)
                        } icon: {
                            Image(systemName: "hand.raised.fill")
                        }
                    } else {
                        PrimaryButton(title: "Reproducir la escena", identifier: "kaiwa.cta.natural.replay") {
                            send(.startNatural)
                        } icon: {
                            Image(systemName: "play.fill")
                        }
                    }
                    if state.canPauseNaturalAudio {
                        Text("El botón detiene este audio local; no cancela a un proveedor.")
                            .font(MATheme.caption())
                            .foregroundStyle(MATheme.stone)
                    } else if state.naturalTutorFinished {
                        Text("La toma terminó. Reprodúcela y toca pausa mientras esté sonando.")
                            .font(MATheme.caption())
                            .foregroundStyle(MATheme.stone)
                    }
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct KaiwaRepairScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: "PAUSA LOCAL · TURNO CEDIDO", color: MATheme.ai)
                    Text("Repara un segmento completo.")
                        .font(MATheme.display())
                        .foregroundStyle(MATheme.sumi)
                    Text("Este es un segmento preparado de la escena, no los últimos segundos exactos que oíste.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 26)

                VStack(alignment: .leading, spacing: 10) {
                    MicroCapsLabel(text: state.repairSegment.sourceBadge, color: MATheme.ai)
                    Text(state.repairSegment.japanese)
                        .font(MATheme.jp(28))
                    Text(state.repairSegment.romaji)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                    Text(state.repairSegment.spanish)
                        .font(MATheme.heading())
                    Text(state.repairSegment.teachingCue)
                        .font(MATheme.caption())
                        .foregroundStyle(MATheme.stone)
                    Button {
                        send(.playRepairSegment)
                    } label: {
                        Label(
                            state.audioState == .playing(.repairBeat)
                                ? "Reproduciendo segmento…" : "Escuchar segmento completo",
                            systemImage: "speaker.wave.2.fill"
                        )
                        .font(MATheme.body(15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .padding(.vertical, 4)
                        .background(MATheme.ai, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("kaiwa.audio.segment")
                }
                .padding(20)
                .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 24)

                Spacer(minLength: 16)
                PrimaryButton(
                    title: state.canResumeAfterRepair
                        ? "Volver a la misma situación"
                        : "Escucha el segmento primero",
                    identifier: "kaiwa.cta.resume"
                ) {
                    send(.resumeScene)
                } icon: {
                    Image(systemName: "arrow.right")
                }
                .disabled(!state.canResumeAfterRepair)
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct KaiwaResumingScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 18) {
                MicroCapsLabel(text: "MISMA OBLIGACIÓN · CONTINUACIÓN LOCAL", color: MATheme.ai)
                Text("Vuelves a la mesa para uno.")
                    .font(MATheme.display())
                Text("El tutor continúa con audio incluido. Cuando termine, responderás otra vez sin texto.")
                    .font(MATheme.body(16, weight: .regular))
                    .foregroundStyle(MATheme.stone)
                InkGlyph()
                    .frame(width: 160, height: 120)
                    .frame(maxWidth: .infinity)
                TutorCaptionCard(line: RestaurantForOneFixture.repairLine)
                if !state.isPlaying {
                    PrimaryButton(title: "Intentar la continuación", identifier: "kaiwa.cta.resume.retry") {
                        send(.resumeScene)
                    } icon: {
                        Image(systemName: "play.fill")
                    }
                }
            }
            .padding(.horizontal, MATheme.sideMargin)
            .padding(.top, 32)
        }
    }
}

private struct TutorCaptionCard: View {
    let line: TutorLine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MicroCapsLabel(text: "SUBTÍTULOS DEL AUDIO")
            Text(line.japanese)
                .font(MATheme.jp(20))
                .foregroundStyle(MATheme.sumi)
            Text(line.romaji)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
            Text(line.spanish)
                .font(MATheme.caption(.medium))
                .foregroundStyle(MATheme.sumi)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Subtítulos del audio. Japonés: \(line.japanese). Romaji: \(line.romaji). Significado: \(line.spanish)"
        )
    }
}

private struct KaiwaRetryScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: "MEJOR SIGUIENTE INTENTO", color: MATheme.ai)
                    Text("La misma respuesta. Sin texto.")
                        .font(MATheme.display())
                    Text("Responde a cuántas personas son. MA comparará solo señales honestas: tu confirmación, presencia de voz y un inicio aproximado.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                RoundedRectangle(cornerRadius: 18)
                    .stroke(MATheme.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    .frame(height: 120)
                    .overlay(InkGlyph().frame(width: 72, height: 56))
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.top, 30)
                    .accessibilityLabel("Respuesta sin texto")

                Spacer(minLength: 18)
                retryControls
                    .padding(.horizontal, MATheme.sideMargin)
                    .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    private var retryControls: some View {
        if state.awaitingSelfAssessment {
            VStack(spacing: 10) {
                if let receipt = state.pendingReceipt {
                    LocalCaptureDisclosure(receipt: receipt)
                }
                Text("¿Completaste la frase esta vez?")
                    .font(MATheme.body(16, weight: .semibold))
                HStack(spacing: 10) {
                    Button("Sí, me salió") { send(.assessSuccess) }
                        .buttonStyle(KaiwaAssessmentButtonStyle(filled: true))
                        .accessibilityIdentifier("kaiwa.retry.ok")
                    Button("Otra vez") { send(.assessRetry) }
                        .buttonStyle(KaiwaAssessmentButtonStyle(filled: false))
                        .accessibilityIdentifier("kaiwa.retry.again")
                }
            }
        } else {
            PrimaryButton(
                title: state.isRequestingPermission
                    ? "Esperando permiso…"
                    : (state.isCapturing ? "Terminar segundo intento" : "Grabar segundo intento"),
                identifier: state.isCapturing ? "kaiwa.retry.stop" : "kaiwa.retry.start"
            ) {
                send(state.isCapturing ? .finishAttempt : .startAttempt)
            } icon: {
                Image(systemName: state.isRequestingPermission
                      ? "ellipsis" : (state.isCapturing ? "stop.fill" : "mic.fill"))
            }
            .disabled(state.isRequestingPermission)
        }
    }
}

private struct KaiwaProofScreen: View {
    let state: KaiwaLoopState
    let send: (KaiwaLoopIntent) -> Void

    var body: some View {
        AdaptiveScreen {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    MicroCapsLabel(text: "FIN DE LA ESCENA · TUS DOS INTENTOS", color: MATheme.ai)
                    Text("Reparaste y volviste.")
                        .font(MATheme.display())
                    Text("No hay nota de pronunciación. Solo hechos locales y tu propia confirmación.")
                        .font(MATheme.body(16, weight: .regular))
                        .foregroundStyle(MATheme.stone)
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.top, 28)

                if let first = state.completedPreRepairAttempt {
                    evidenceCard("ANTES DE LA REPARACIÓN", attempt: first)
                        .padding(.top, 24)
                }
                if let second = state.completedPostRepairAttempt {
                    evidenceCard("DESPUÉS DE LA REPARACIÓN", attempt: second)
                        .padding(.top, 12)
                }
                comparison
                    .padding(.top, 20)
                if let action = state.nextLearningAction {
                    nextStepCard(action)
                        .padding(.top, 16)
                }
                if state.learningReport != nil,
                   !state.remotePlannerRequestAttempted {
                    optionalPlannerCard
                        .padding(.top, 16)
                }

                Spacer(minLength: 16)
                VStack(spacing: 10) {
                    if state.plannerIsRefreshing {
                        Text("Preparando el siguiente paso; el resultado local ya está listo…")
                            .font(MATheme.caption())
                            .foregroundStyle(MATheme.stone)
                    }
                    PrimaryButton(title: "Practicar otra vez", identifier: "kaiwa.cta.restart") {
                        send(.restart)
                    } icon: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                .padding(.horizontal, MATheme.sideMargin)
                .padding(.bottom, 10)
            }
        }
    }

    private var optionalPlannerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MicroCapsLabel(text: "OPCIONAL · PLAN CON GPT-5.6", color: MATheme.ai)
            Text("Tú decides si estos hechos salen del iPhone.")
                .font(MATheme.heading())
                .foregroundStyle(MATheme.sumi)
            Text("Se envían la escena, ayuda usada, duración, inicio estimado de voz, presencia de voz, tu confirmación y número de reparaciones. Nunca se envían audio ni transcripción.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
            Button {
                send(.requestRemotePlan)
            } label: {
                Text("Pedir mi plan opcional")
                    .font(MATheme.body(15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .padding(.vertical, 2)
                    .background(MATheme.ai, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("kaiwa.plan.request")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, MATheme.sideMargin)
    }

    private func evidenceCard(
        _ title: String,
        attempt: PracticeAttemptEvidence
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: title, color: MATheme.ai)
            Label(
                state.presentationSource == .labeledReplay
                    ? "Resultado de demostración" : "Completado según tú",
                systemImage: "checkmark.circle.fill"
            )
                .font(MATheme.body(16, weight: .semibold))
            Text(attempt.speechPresenceDetected
                 ? "Señal de voz local detectada"
                 : "Sin señal de voz suficiente para estimar")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
            if let onset = attempt.estimatedVoiceOnset {
                Text("Inicio estimado: \(onset.formatted(.number.precision(.fractionLength(1)))) s · no es una calificación")
                    .font(MATheme.caption())
                    .foregroundStyle(MATheme.stone)
            }
            Text("Audio crudo descartado")
                .font(MATheme.micro())
                .foregroundStyle(MATheme.stone)
            if attempt.provenance == .replayFixture {
                Text("Datos fijos de muestra; no pertenecen al aprendiz.")
                    .font(MATheme.micro())
                    .foregroundStyle(MATheme.stone)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, MATheme.sideMargin)
    }

    private var comparison: some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: "LO QUE CAMBIÓ")
            if let first = state.completedPreRepairAttempt,
               let second = state.completedPostRepairAttempt,
               let firstOnset = first.estimatedVoiceOnset,
               let secondOnset = second.estimatedVoiceOnset {
                Text(secondOnset < firstOnset
                     ? "Empezaste antes en la segunda toma."
                     : "Completaste otra toma después de reparar el segmento.")
                    .font(MATheme.heading())
            } else {
                Text("Completaste otra toma después de reparar el segmento.")
                    .font(MATheme.heading())
            }
            Text("La obligación siguió siendo pedir mesa para una persona; el plan no puede cambiar estos hechos.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .padding(.horizontal, MATheme.sideMargin)
    }

    private func nextStepCard(_ action: NextLearningAction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: sourceLabel(action.source), color: MATheme.ai)
            Text(actionTitle(action.action))
                .font(MATheme.heading())
                .foregroundStyle(MATheme.sumi)
            Text(action.explanationES)
                .font(MATheme.body(15, weight: .regular))
                .foregroundStyle(MATheme.sumi)
            Text(action.evidenceReasonES)
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, MATheme.sideMargin)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("kaiwa.plan.next")
    }

    private func sourceLabel(_ source: LearningRecommendationSource) -> String {
        switch source {
        case .model:
            "PLAN · GPT-5.6-SOL"
        case .deterministicPolicy:
            "PLAN · RESPALDO LOCAL"
        case .cachedFixture:
            "PLAN · REPLAY CONTROLADO"
        }
    }

    private func actionTitle(_ action: LearningActionKind) -> String {
        switch action {
        case .repeatLesson:
            "Repetir la misma respuesta"
        case .reduceScaffold:
            "Quitar un poco de ayuda"
        case .isolateSegment:
            "Aislar un segmento"
        case .advance:
            "Avanzar al siguiente objetivo"
        case .abstain:
            "Mantener el plan local"
        }
    }
}

private struct LocalCaptureDisclosure: View {
    let receipt: CaptureReceipt

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: receipt.speechPresenceDetected ? "waveform" : "waveform.slash")
                .foregroundStyle(MATheme.ai)
            Text(receipt.speechPresenceDetected
                 ? "Hubo señal de voz. El audio crudo ya fue descartado."
                 : "No hubo señal suficiente para una estimación. Tú decides si completaste la frase.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProductAudioErrorBanner: View {
    let error: ProductAudioFailure
    @Environment(\.openURL) private var openURL
    @Environment(\.maInterfaceLanguage) private var language

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(MATheme.ai)
            Text(error.message(in: language))
                .font(MATheme.caption(.medium))
                .foregroundStyle(MATheme.sumi)
            Spacer(minLength: 4)
            if error == .microphoneDenied {
                Button(language.text(english: "Settings", spanish: "Ajustes")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(MATheme.caption(.semibold))
            }
        }
        .padding(12)
        .background(MATheme.mist, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct KaiwaAssessmentButtonStyle: ButtonStyle {
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(MATheme.body(15, weight: .semibold))
            .foregroundStyle(filled ? .white : MATheme.sumi)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .background(filled ? MATheme.ai : .white, in: Capsule())
            .overlay(Capsule().stroke(filled ? MATheme.ai : MATheme.hairline))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

#Preview("Kaiwa Loop · local") {
    KaiwaLoopView(feature: KaiwaLoopFeature())
}
