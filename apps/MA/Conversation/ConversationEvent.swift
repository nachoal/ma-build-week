import Foundation

enum ConversationEventSource: String, Codable, Equatable, Sendable {
    case labeledReplay
    case bundledLocalProduct
    case realtimeProvider
    case measuredDeviceTopology
}

enum ConversationEvidenceProvenance: String, Codable, Equatable, Sendable {
    case fixtureSimulation
    case bundledAudio
    case learnerSelfReport
    case providerEvent
    case renderedAudioMeasured
}

struct ConversationEventEvidence: Codable, Equatable, Sendable {
    let provenance: ConversationEvidenceProvenance
    let isSanitized: Bool
    let retainsRawProviderPayload: Bool
    let retainsRawAudio: Bool

    static func replay(
        _ provenance: ConversationEvidenceProvenance = .fixtureSimulation
    ) -> ConversationEventEvidence {
        ConversationEventEvidence(
            provenance: provenance,
            isSanitized: true,
            retainsRawProviderPayload: false,
            retainsRawAudio: false
        )
    }
}

struct ConversationAttemptEvidence: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let obligationID: String
    let scaffold: ScaffoldLevel
    let attemptNumber: Int
    let capturedDuration: TimeInterval
    let estimatedVoiceOnset: TimeInterval?
    let speechPresenceDetected: Bool
    let selfReportedCompleted: Bool
    let repairCount: Int
    let provenance: ConversationEvidenceProvenance
}

enum ConversationRepairSelection: Codable, Equatable, Sendable {
    case controlledSegment(id: String, obligationID: String)
    case renderedWindow(beats: [TimelineBeat])
}

enum ConversationEventPayload: Codable, Equatable, Sendable {
    case sessionConnecting
    case sessionReady
    case sessionWaiting
    case sessionFailed(String)

    // Learning-loop events needed for a complete deterministic hero replay.
    case lessonStarted
    case coachedRoundStarted(ScaffoldLevel)
    case firstExchangeCompleted
    case controlsIntroduced

    // Normalized conversation events from todo.md section 9.
    case tutorOutputStarted(TutorLine)
    case tutorAudioScheduled(BundledPrompt)
    case timelineBeatAdvanced(TimelineBeat)
    case tutorTranscriptDelta(TutorLine)
    case learnerSpeechStarted
    case learnerPartialTranscript(String)
    case backchannelDetected(atNanoseconds: UInt64)
    case takeFloorDetected(atNanoseconds: UInt64)
    case localRepairRequested
    case tutorOutputCancelled
    case repairWindowFrozen(ConversationRepairSelection)
    case controlledSegmentPlayed(String)
    case sceneResumeStarted(obligationID: String)
    case sceneResumed(obligationID: String)
    case attemptCompleted(ConversationAttemptEvidence)
    case learningActionReady(NextLearningAction)
    case sessionEnded
}

/// Provider-neutral envelope. Monotonic time is relative to the session and
/// every correlation ID is sanitized before it reaches product state.
struct ConversationEvent: Codable, Equatable, Sendable, Identifiable {
    let schemaVersion: Int
    let sequence: Int
    let monotonicNanoseconds: UInt64
    let sessionID: UUID
    let sceneID: SceneID
    let obligationID: String
    let correlationID: String
    let source: ConversationEventSource
    let evidence: ConversationEventEvidence
    let payload: ConversationEventPayload

    var id: String { "\(sessionID.uuidString):\(sequence)" }

    var supportsLiveClaim: Bool {
        guard evidence.isSanitized,
              !evidence.retainsRawProviderPayload,
              !evidence.retainsRawAudio else { return false }
        return source == .realtimeProvider || source == .measuredDeviceTopology
    }

    var supportsExactHeardClaim: Bool {
        source == .measuredDeviceTopology
            && evidence.provenance == .renderedAudioMeasured
            && evidence.isSanitized
            && !evidence.retainsRawAudio
    }

    var isStructurallyValid: Bool {
        schemaVersion == 1
            && sequence >= 0
            && !obligationID.isEmpty
            && obligationID.count <= 96
            && !correlationID.isEmpty
            && correlationID.count <= 96
            && evidence.isSanitized
            && !evidence.retainsRawProviderPayload
            && !evidence.retainsRawAudio
            && (source != .labeledReplay || (!supportsLiveClaim && !supportsExactHeardClaim))
    }
}
