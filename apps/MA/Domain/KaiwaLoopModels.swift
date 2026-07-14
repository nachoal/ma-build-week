import Foundation

enum KaiwaLoopPhase: Equatable, Sendable {
    case setup
    case coached
    case firstSuccess
    case controls
    case natural
    case repair
    case resuming
    case retry
    case proof
}

struct PracticeAttemptEvidence: Equatable, Sendable, Identifiable {
    let id: UUID
    let obligationID: String
    let scaffold: ScaffoldLevel
    let attemptNumber: Int
    let capturedDuration: TimeInterval
    let estimatedVoiceOnset: TimeInterval?
    let speechPresenceDetected: Bool
    let selfReportedCompleted: Bool
    let repairCount: Int
    let rawAudioRetained: Bool

    init(receipt: CaptureReceipt, selfReportedCompleted: Bool, repairCount: Int) {
        id = receipt.id
        obligationID = receipt.request.obligationID
        scaffold = receipt.request.scaffold
        attemptNumber = receipt.request.attemptNumber
        capturedDuration = receipt.capturedDuration
        estimatedVoiceOnset = receipt.estimatedVoiceOnset
        speechPresenceDetected = receipt.speechPresenceDetected
        self.selfReportedCompleted = selfReportedCompleted
        self.repairCount = repairCount
        rawAudioRetained = receipt.rawAudioRetained
    }
}

struct ControlledSegment: Codable, Equatable, Sendable, Identifiable {
    enum Provenance: String, Codable, Sendable {
        case bundledControlledSegment
    }

    let id: String
    let obligationID: String
    let prompt: BundledPrompt
    let provenance: Provenance
    let japanese: String
    let romaji: String
    let spanish: String
    let teachingCue: String

    static let restaurantRepair = ControlledSegment(
        id: "restaurant.arrival.kochira-e-dozo",
        obligationID: KaiwaLoopState.obligationID,
        prompt: .repairBeat,
        provenance: .bundledControlledSegment,
        japanese: RestaurantForOneFixture.repairLine.japanese,
        romaji: RestaurantForOneFixture.repairLine.romaji,
        spanish: RestaurantForOneFixture.repairLine.spanish,
        teachingCue: RestaurantForOneFixture.repairCue
    )

    var sourceBadge: String { PracticeCapabilities.gate0Partial.repairBadge }
    var isExactRenderedWindow: Bool { false }
}

struct KaiwaLoopState: Equatable, Sendable {
    static let obligationID = "restaurant.party-size.one"

    var phase: KaiwaLoopPhase = .setup
    var scaffold: ScaffoldLevel = .full
    var successfulScaffolds: [ScaffoldLevel] = []
    var attempts: [PracticeAttemptEvidence] = []
    var pendingReceipt: CaptureReceipt?
    var awaitingSelfAssessment = false
    var audioState: ProductAudioState = .idle
    var lastError: ProductAudioFailure?
    var playedPrompts: Set<BundledPrompt> = []
    var repairCount = 0
    var naturalTutorFinished = false
    var naturalPlaybackStarted = false
    var naturalStopRecorded = false
    var repairSegmentPlayed = false
    var resumePlaybackCompleted = false
    var plannerStatusText: String?

    let capabilities = PracticeCapabilities.gate0Partial
    let repairSegment = ControlledSegment.restaurantRepair

    var sourceBadge: String {
        switch phase {
        case .repair:
            capabilities.repairBadge
        default:
            capabilities.tutorBadge
        }
    }

    var isCapturing: Bool {
        if case .capturing = audioState { true } else { false }
    }

    var isPlaying: Bool {
        if case .playing = audioState { true } else { false }
    }

    var isRequestingPermission: Bool {
        if case .requestingPermission = audioState { true } else { false }
    }

    var canPauseNaturalAudio: Bool {
        naturalPlaybackStarted && audioState == .playing(.tutorTurn)
    }

    var canResumeAfterRepair: Bool {
        naturalStopRecorded && repairSegmentPlayed
    }

    var completedPreRepairAttempt: PracticeAttemptEvidence? {
        attempts.last {
            $0.obligationID == Self.obligationID
                && $0.scaffold == .none
                && $0.selfReportedCompleted
                && $0.repairCount == 0
        }
    }

    var completedPostRepairAttempt: PracticeAttemptEvidence? {
        attempts.last {
            $0.obligationID == Self.obligationID
                && $0.scaffold == .none
                && $0.selfReportedCompleted
                && $0.repairCount > 0
        }
    }
}

enum KaiwaLoopIntent: Equatable, Sendable {
    case playModel
    case beginCoachedPractice
    case startAttempt
    case finishAttempt
    case assessSuccess
    case assessRetry
    case acknowledgeFirstSuccess
    case startNatural
    case pauseForRepair
    case playRepairSegment
    case resumeScene
    case restart
}
