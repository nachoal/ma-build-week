import SwiftUI
import UIKit

struct KaiwaLoopView: View {
    let feature: KaiwaLoopFeature
    var onExit: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ChromeBar(badge: feature.state.sourceBadge, onExit: onExit)
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
                        ? "Escuchando…" : "Escuchar el modelo",
                    systemImage: state.audioState == .playing(.hitoriDesu)
                        ? "waveform" : "speaker.wave.2"
                )
                .font(MATheme.body(16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(MATheme.ai, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(state.isCapturing)
            .accessibilityIdentifier("kaiwa.audio.modelo")
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
                Label("Escuchar el modelo", systemImage: "speaker.wave.2")
                    .font(MATheme.caption(.semibold))
                    .foregroundStyle(MATheme.ai)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .disabled(state.isCapturing)
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
                        .symbolEffect(.pulse, options: .repeating, isActive: state.isPlaying)
                    MicroCapsLabel(text: BundledPrompt.tutorTurn.provenanceLabel, color: MATheme.ai)
                }
                .frame(maxWidth: .infinity)
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
                        .frame(height: 50)
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

                Spacer(minLength: 16)
                VStack(spacing: 10) {
                    if let plannerStatus = state.plannerStatusText {
                        Text(plannerStatus)
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

    private func evidenceCard(
        _ title: String,
        attempt: PracticeAttemptEvidence
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MicroCapsLabel(text: title, color: MATheme.ai)
            Label("Completado según tú", systemImage: "checkmark.circle.fill")
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
            Text("Siguiente objetivo provisional: repetir una vez más sin texto. El plan nunca puede inventar evidencia ni saltarse una obligación incompleta.")
                .font(MATheme.caption())
                .foregroundStyle(MATheme.stone)
        }
        .padding(.horizontal, MATheme.sideMargin)
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

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(MATheme.ai)
            Text(error.localizedDescription)
                .font(MATheme.caption(.medium))
                .foregroundStyle(MATheme.sumi)
            Spacer(minLength: 4)
            if error == .microphoneDenied {
                Button("Ajustes") {
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
