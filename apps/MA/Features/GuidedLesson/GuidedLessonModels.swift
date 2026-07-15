import Foundation

enum GuidedModelStep: Equatable, Sendable {
    case ready
    case playing
    case completed
}

enum GuidedAttemptFailure: Equatable, Sendable {
    case microphoneDenied
    case noSpeech
    case realtime(GuidedRealtimeError)
    case reviewUnavailable
    case interrupted

    func message(in language: MAInterfaceLanguage) -> String {
        switch self {
        case .microphoneDenied:
            language.text(
                english: "Enable the microphone in Settings, then return to record your attempt.",
                spanish: "Activa el micrófono en Ajustes y vuelve para grabar tu intento."
            )
        case .noSpeech:
            language.text(
                english: "I could not hear enough voice. Move closer to the iPhone and say it once more.",
                spanish: "No pude oír suficiente voz. Acércate al iPhone y dilo una vez más."
            )
        case .realtime(let error):
            error.message(in: language)
        case .reviewUnavailable:
            language.text(
                english: "I could not review this attempt. Your progress did not change; you can record it again.",
                spanish: "No pude revisar este intento. Tu avance no cambió; puedes grabarlo de nuevo."
            )
        case .interrupted:
            language.text(
                english: "The recording was interrupted. Start a new attempt when you are ready.",
                spanish: "La grabación se interrumpió. Cuando estés listo, empieza un intento nuevo."
            )
        }
    }

    var diagnosticCode: String {
        switch self {
        case .microphoneDenied: "microphone_denied"
        case .noSpeech: "no_speech"
        case .realtime(let error): error.diagnosticCode
        case .reviewUnavailable: "review_unavailable"
        case .interrupted: "interrupted"
        }
    }

    var isRealtimeFailure: Bool {
        if case .realtime = self { true } else { false }
    }

    var message: String { message(in: .spanish) }
}

enum GuidedAttemptStep: Equatable, Sendable {
    case ready
    case checkingReviewConnection
    case requestingPermission
    case recording(attemptID: UUID)
    case reviewing(attemptID: UUID)
    case feedback(GuidedRealtimeReviewResult)
    case recoverableError(GuidedAttemptFailure)
}

enum GuidedFeedbackTransition: Equatable, Sendable {
    case retrying
    case continuing
}

enum GuidedTutorTurnStep: Equatable, Sendable {
    case ready
    case preparing
    case speaking
    case responseReady
    case recoverableError
}

enum GuidedLessonPhase: Equatable, Sendable {
    case orientation
    case model(GuidedModelStep)
    case attempt(context: GuidedAttemptContext, step: GuidedAttemptStep)
    case situationBrief
    case tutorTurn(GuidedTutorTurnStep)
    case complete
}

struct GuidedLessonState: Equatable, Sendable {
    var phase: GuidedLessonPhase = .orientation
    var audioState: ProductAudioState = .idle
    var attemptCount = 0
    var reviewedAttempts: [GuidedAttemptFact] = []
    var answerSupportVisible = true
    var spokenFeedbackUnavailable = false
    var spokenFeedbackPreparing = false
    var spokenFeedbackCompleted = false
    var feedbackTransition: GuidedFeedbackTransition?
    var connectionPreparing = false
    var connectionReady = false
    var connectionFailure: GuidedRealtimeError?
    var learningReport: GuidedLearningReport?
    var plannerStep: GuidedPlannerStep?

    let targetJapanese = RestaurantForOneFixture.phraseJapanese
    let targetRomaji = RestaurantForOneFixture.phraseRomaji
    let targetSpanish = "Una persona · voy solo."
    let targetEnglish = "One person · I’m dining alone."
    let waiterJapanese = "何名様ですか？"
    let waiterRomaji = "nan-mei-sama desu ka"
    let waiterSpanish = "¿Cuántas personas?"
    let waiterEnglish = "How many people?"

    var isBusy: Bool {
        if feedbackTransition != nil { return true }
        return switch phase {
        case .model(.playing),
             .attempt(_, .checkingReviewConnection),
             .attempt(_, .requestingPermission),
             .attempt(_, .reviewing),
             .tutorTurn(.preparing),
             .tutorTurn(.speaking):
            true
        default:
            false
        }
    }

    var isRecording: Bool {
        if case .attempt(_, .recording) = phase { true } else { false }
    }

    func sourceBadge(in language: MAInterfaceLanguage) -> String {
        language.text(
            english: "GPT REALTIME · GUIDED",
            spanish: "GPT REALTIME · GUIADO"
        )
    }

    var sourceBadge: String { sourceBadge(in: .spanish) }
}

enum GuidedLessonIntent: Equatable, Sendable {
    case showPhrase
    case playModel
    case retryRealtimeConnection
    case beginAttempt
    case finishAttempt
    case retryAttempt
    case continueWithFeedback
    case playWaiterTurn
    case requestNextPlan
    case restart
}
