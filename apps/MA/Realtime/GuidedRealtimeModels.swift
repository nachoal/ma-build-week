import Foundation

struct GuidedRealtimeClientSecret: Sendable, Equatable {
    let value: String
    let expiresAt: Int
    let expectedConfigurationHash: String
}

enum GuidedRealtimeError: Error, LocalizedError, Equatable, Sendable {
    case missingCredential
    case unauthorized
    case rateLimited
    case serviceUnavailable
    case invalidBrokerResponse
    case invalidClientSecret
    case connectionFailed
    case configurationMismatch
    case disconnected
    case invalidAudio
    case noSpeech
    case providerRejected
    case invalidReview
    case responseTimedOut
    case responseIncomplete
    case playbackUnavailable

    var errorDescription: String? {
        message(in: .english)
    }

    func message(in language: MAInterfaceLanguage) -> String {
        switch self {
        case .missingCredential:
            language.text(
                english: "This build does not have private access to speaking-turn review.",
                spanish: "Esta compilación no tiene acceso privado a la revisión de voz."
            )
        case .unauthorized:
            language.text(
                english: "MA’s private session expired. Reinstall this build.",
                spanish: "La sesión privada de MA venció. Reinstala esta compilación."
            )
        case .rateLimited:
            language.text(
                english: "MA needs a short pause before reviewing another attempt.",
                spanish: "MA necesita una pausa breve antes de revisar otro intento."
            )
        case .serviceUnavailable, .connectionFailed, .disconnected:
            language.text(
                english: "I could not connect the speaking-turn review. You can record again.",
                spanish: "No pude conectar la revisión de voz. Puedes grabar de nuevo."
            )
        case .invalidBrokerResponse, .invalidClientSecret, .configurationMismatch:
            language.text(
                english: "The voice session did not pass its security check.",
                spanish: "La sesión de voz no pasó la verificación de seguridad."
            )
        case .invalidAudio, .noSpeech:
            language.text(
                english: "I could not hear enough speech. Move closer to the iPhone and try again.",
                spanish: "No pude oír suficiente voz. Acércate al iPhone e inténtalo otra vez."
            )
        case .providerRejected, .invalidReview, .responseIncomplete:
            language.text(
                english: "I could not review this attempt with enough certainty. Record it again.",
                spanish: "No pude revisar este intento con suficiente certeza. Grábalo de nuevo."
            )
        case .responseTimedOut:
            language.text(
                english: "The review took too long. Record a new attempt.",
                spanish: "La revisión tardó demasiado. Graba un intento nuevo."
            )
        case .playbackUnavailable:
            language.text(
                english: "The review is visible, but its audio could not play.",
                spanish: "La revisión está visible, pero su audio no pudo reproducirse."
            )
        }
    }
}

enum GuidedAttemptContext: String, Codable, Equatable, Sendable {
    case taughtPhrase
    case restaurantTurn
}

struct GuidedAttemptRequest: Equatable, Sendable, Identifiable {
    static let targetPhraseID = "restaurant.party-size.hitori-desu"

    let id: UUID
    let context: GuidedAttemptContext
    let attemptNumber: Int
    let targetPhraseID: String
    let feedbackLanguage: MAInterfaceLanguage

    init(
        id: UUID = UUID(),
        context: GuidedAttemptContext,
        attemptNumber: Int,
        targetPhraseID: String = Self.targetPhraseID,
        feedbackLanguage: MAInterfaceLanguage = .defaultLanguage
    ) {
        self.id = id
        self.context = context
        self.attemptNumber = attemptNumber
        self.targetPhraseID = targetPhraseID
        self.feedbackLanguage = feedbackLanguage
    }
}

enum GuidedTargetMatch: String, Codable, CaseIterable, Equatable, Sendable {
    case matched
    case close
    case different
    case unclear
}

enum GuidedReviewEvidenceCode: String, Codable, CaseIterable, Equatable, Sendable {
    case fullTargetInTranscript = "full_target_in_transcript"
    case partialTargetInTranscript = "partial_target_in_transcript"
    case speechTurnCompleted = "speech_turn_completed"
    case audioUnclear = "audio_unclear"
}

enum GuidedRetryFocusCode: String, Codable, CaseIterable, Equatable, Sendable {
    case useWithWaiter = "use_with_waiter"
    case completeTarget = "complete_target"
    case useVisiblePhrase = "use_visible_phrase"
    case moveCloser = "move_closer"
}

struct GuidedAttemptReview: Equatable, Sendable, Identifiable {
    let attemptID: UUID
    let targetPhraseID: String
    let targetMatch: GuidedTargetMatch
    let heardJapanese: String?
    let evidenceCode: GuidedReviewEvidenceCode
    let retryFocusCode: GuidedRetryFocusCode

    var id: UUID { attemptID }

    var positiveEN: String { Self.canonicalPositiveEN(for: targetMatch) }
    var positiveES: String { Self.canonicalPositiveES(for: targetMatch) }
    var correctionEN: String? { Self.canonicalCorrectionEN(for: targetMatch) }
    var correctionES: String? { Self.canonicalCorrectionES(for: targetMatch) }
    var retryFocusEN: String? { Self.canonicalRetryFocusEN(for: retryFocusCode) }
    var retryFocusES: String? { Self.canonicalRetryFocusES(for: retryFocusCode) }

    init(
        attemptID: UUID,
        targetPhraseID: String,
        targetMatch: GuidedTargetMatch,
        heardJapanese: String?,
        evidenceCode: GuidedReviewEvidenceCode,
        retryFocusCode: GuidedRetryFocusCode
    ) {
        self.attemptID = attemptID
        self.targetPhraseID = targetPhraseID
        self.targetMatch = targetMatch
        self.heardJapanese = heardJapanese
        self.evidenceCode = evidenceCode
        self.retryFocusCode = retryFocusCode
    }

    func positive(in language: MAInterfaceLanguage) -> String {
        language == .english ? positiveEN : positiveES
    }

    func correction(in language: MAInterfaceLanguage) -> String? {
        language == .english ? correctionEN : correctionES
    }

    func retryFocus(in language: MAInterfaceLanguage) -> String? {
        language == .english ? retryFocusEN : retryFocusES
    }

    static func validated(
        arguments: String,
        attemptID: UUID,
        approximateTranscript: String?
    ) throws -> GuidedAttemptReview {
        guard let data = arguments.data(using: .utf8),
              !data.isEmpty,
              data.count <= 4_096,
              let value = try? JSONSerialization.jsonObject(with: data),
              let object = value as? [String: Any],
              Set(object.keys) == Set([
                  "target_phrase_id",
                  "assessment",
                  "evidence_code",
                  "retry_focus_code",
              ]),
              object["target_phrase_id"] as? String == GuidedAttemptRequest.targetPhraseID,
              let rawMatch = object["assessment"] as? String,
              let match = GuidedTargetMatch(rawValue: rawMatch),
              let rawEvidence = object["evidence_code"] as? String,
              let evidenceCode = GuidedReviewEvidenceCode(rawValue: rawEvidence),
              let rawFocus = object["retry_focus_code"] as? String,
              let retryFocusCode = GuidedRetryFocusCode(rawValue: rawFocus)
        else {
            throw GuidedRealtimeError.invalidReview
        }

        guard let expectedCodes = Self.expectedCodes[match],
              expectedCodes.evidence == evidenceCode,
              expectedCodes.focus == retryFocusCode else {
            return unclear(attemptID: attemptID)
        }
        if match == .unclear {
            return unclear(attemptID: attemptID)
        }

        guard let transcript = boundedTranscript(approximateTranscript) else {
            return unclear(attemptID: attemptID)
        }
        let transcriptEvidence = transcriptEvidence(in: transcript)
        let isGrounded = switch match {
        case .matched:
            transcriptEvidence == .full
        case .close:
            transcriptEvidence == .full || transcriptEvidence == .partial
        case .different:
            transcriptEvidence == .none
        case .unclear:
            false
        }
        guard isGrounded else { return unclear(attemptID: attemptID) }

        return GuidedAttemptReview(
            attemptID: attemptID,
            targetPhraseID: GuidedAttemptRequest.targetPhraseID,
            targetMatch: match,
            heardJapanese: transcript,
            evidenceCode: evidenceCode,
            retryFocusCode: retryFocusCode
        )
    }

    static func unclear(attemptID: UUID) -> GuidedAttemptReview {
        GuidedAttemptReview(
            attemptID: attemptID,
            targetPhraseID: GuidedAttemptRequest.targetPhraseID,
            targetMatch: .unclear,
            heardJapanese: nil,
            evidenceCode: .audioUnclear,
            retryFocusCode: .moveCloser
        )
    }

    func functionOutput() throws -> String {
        let object: [String: Any] = [
            "accepted": true,
            "target_phrase_id": targetPhraseID,
            "assessment": targetMatch.rawValue,
            "evidence_code": evidenceCode.rawValue,
            "retry_focus_code": retryFocusCode.rawValue,
        ]
        let data = try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        guard let value = String(data: data, encoding: .utf8), value.count <= 512 else {
            throw GuidedRealtimeError.invalidReview
        }
        return value
    }

    private enum TranscriptEvidence {
        case full
        case partial
        case none
    }

    private static let expectedCodes: [
        GuidedTargetMatch: (evidence: GuidedReviewEvidenceCode, focus: GuidedRetryFocusCode)
    ] = [
        .matched: (.fullTargetInTranscript, .useWithWaiter),
        .close: (.partialTargetInTranscript, .completeTarget),
        .different: (.speechTurnCompleted, .useVisiblePhrase),
        .unclear: (.audioUnclear, .moveCloser),
    ]

    private static func boundedTranscript(_ value: String?) -> String? {
        guard let value else { return nil }
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty,
              result.count <= 96,
              result.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value != 0x7F })
        else { return nil }
        return result
    }

    private static func transcriptEvidence(in transcript: String) -> TranscriptEvidence {
        let key = comparisonKey(transcript)
        guard !key.isEmpty else { return .none }
        if key.contains("ひとりです") || key.contains("hitoridesu") {
            return .full
        }
        if key.contains("ひとり") || key.contains("hitori") {
            return .partial
        }
        return .none
    }

    private static func comparisonKey(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "一人", with: "ひとり")
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || (0x3040...0x30FF).contains($0.value) }
            .map(String.init)
            .joined()
    }

    private static func canonicalPositiveEN(for match: GuidedTargetMatch) -> String {
        switch match {
        case .matched: "MA’s transcription contains the complete restaurant answer."
        case .close: "MA’s transcription caught part of the target phrase."
        case .different: "You completed the speaking turn."
        case .unclear: "You completed a speaking turn."
        }
    }

    private static func canonicalPositiveES(for match: GuidedTargetMatch) -> String {
        switch match {
        case .matched: "La transcripción de MA contiene la respuesta completa."
        case .close: "La transcripción de MA captó parte de la frase."
        case .different: "Completaste un turno de voz."
        case .unclear: "Completaste un turno de voz."
        }
    }

    private static func canonicalCorrectionEN(for match: GuidedTargetMatch) -> String? {
        switch match {
        case .matched: nil
        case .close: "The complete answer was not verified."
        case .different: "MA’s transcription did not contain the restaurant answer."
        case .unclear: "The audio was not clear enough to verify the words."
        }
    }

    private static func canonicalCorrectionES(for match: GuidedTargetMatch) -> String? {
        switch match {
        case .matched: nil
        case .close: "No se pudo verificar la respuesta completa."
        case .different: "La transcripción de MA no contenía la respuesta del restaurante."
        case .unclear: "El audio no fue suficientemente claro para verificar las palabras."
        }
    }

    private static func canonicalRetryFocusEN(for focus: GuidedRetryFocusCode) -> String? {
        switch focus {
        case .useWithWaiter: "Keep the same short answer for the waiter."
        case .completeTarget: "Say hi-to-ri de-su once, at an even pace."
        case .useVisiblePhrase: "Use the visible phrase once: hi-to-ri de-su."
        case .moveCloser: "Move closer to the iPhone and say hitori desu once, without rushing."
        }
    }

    private static func canonicalRetryFocusES(for focus: GuidedRetryFocusCode) -> String? {
        switch focus {
        case .useWithWaiter: "Mantén la misma respuesta corta para el mesero."
        case .completeTarget: "Di hi-to-ri de-su una vez, a un ritmo parejo."
        case .useVisiblePhrase: "Usa una vez la frase visible: hi-to-ri de-su."
        case .moveCloser: "Acércate al iPhone y di hitori desu una vez, sin prisa."
        }
    }
}

struct GuidedRealtimeReviewResult: Equatable, Sendable {
    let request: GuidedAttemptRequest
    let review: GuidedAttemptReview
    /// Separate ASR guidance, not an exact record of what the voice model heard.
    let approximateTranscript: String?
}

struct GuidedRealtimeSpokenFeedback: Equatable, Sendable {
    let transcript: String?
    let pcm16Data: Data
}

struct GuidedRealtimeTutorTurn: Equatable, Sendable {
    let transcript: String?
    let pcm16Data: Data
}

protocol GuidedRealtimeProviding: Sendable {
    func connect() async throws
    func reviewAttempt(
        _ request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws -> GuidedRealtimeReviewResult
    func requestSpokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) async throws -> GuidedRealtimeSpokenFeedback
    func requestRestaurantTurn() async throws -> GuidedRealtimeTutorTurn
    func disconnect() async
}
