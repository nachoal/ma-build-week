import Foundation

/// Which speaker holds the conversational floor. A backchannel (はい) is an
/// overlay on `.tutorSpeaking`, never a phase of its own.
enum PracticePhase: Equatable, Sendable {
    case setup
    /// First-minute coached ladder: the learner replies with shrinking
    /// scaffold before ever meeting natural speed.
    case coached
    case firstSuccess
    case controlsIntro
    case tutorSpeaking
    case floorYielded
    case proof
}

/// Provenance is explicit: fixture animation can drive the same timeline as
/// real rendered audio without becoming evidence that audio was heard.
enum TimelineBeatSource: String, Codable, Equatable, Sendable {
    case fixtureSimulation
    case renderedAudio
}

/// One beat on the tutor timeline. Amplitude drives ink geometry only.
struct TimelineBeat: Codable, Equatable, Sendable, Identifiable {
    let id: Int
    let start: Double
    let duration: Double
    let amplitude: Double
    let source: TimelineBeatSource

    var end: Double { start + duration }
}

/// A clipped repair-window slice. Only `.renderedAudio` fragments may support
/// a claim about audio the learner actually heard.
struct RepairFragment: Equatable, Sendable, Identifiable {
    let id: Int
    let start: Double
    let duration: Double
    let amplitude: Double
    let source: TimelineBeatSource
}

struct TutorLine: Codable, Equatable, Sendable {
    let japanese: String
    let romaji: String
    let spanish: String
}

enum ScaffoldLevel: String, Codable, Equatable, Sendable {
    case full
    case rhythmOnly
    case none

    var spanishDescription: String {
        switch self {
        case .full: "Con la frase completa a la vista"
        case .rhythmOnly: "Solo con el ritmo"
        case .none: "Sin ninguna ayuda"
        }
    }
}

/// Learner-understandable evidence only: completion, onset latency, scaffold,
/// rescue count. Deliberately no model-confidence field.
enum AttemptProvenance: Equatable, Sendable {
    case fixtureSample
    case selfReported
    case measured
}

struct AttemptRecord: Equatable, Sendable, Identifiable {
    let id: Int
    let scaffold: ScaffoldLevel
    let onsetLatency: Double
    let rescueCount: Int
    let completed: Bool
    let provenance: AttemptProvenance
}

struct BackchannelAcknowledgement: Equatable, Sendable {
    let at: Double
}

struct PracticeState: Equatable, Sendable {
    var phase: PracticePhase = .setup
    var fixtureTime: Double = 0
    var tutorLine: TutorLine?
    var tutorOutputActive = false
    var timelineBeats: [TimelineBeat] = []

    /// Coached first-minute ladder. The learner marks each attempt manually
    /// and then self-assesses it — the fixture never claims to have heard or
    /// judged anything. `coachedAttempts` records only self-reported successes.
    var coachedScaffold: ScaffoldLevel = .full
    var coachedAttempts: [ScaffoldLevel] = []
    /// True between "Ya dije mi respuesta" and the learner's own verdict.
    var coachedAwaitingAssessment = false
    var coachedRoundRetries = 0
    var coachedTotalRetries = 0

    /// Overlay only: non-nil while a はい acknowledgement is visually decaying.
    var backchannel: BackchannelAcknowledgement?
    var backchannelCount = 0
    /// Fixture times of every acknowledged はい, for timeline ring markers.
    var backchannelMarks: [Double] = []

    /// A short-lived transaction token for cancel → freeze. This is cleared
    /// on resume so a stale cancellation can never reopen an old repair.
    var pendingYieldAt: Double?
    /// Historical evidence retained for the final proof.
    var yieldedAt: Double?
    var repairWindow: [RepairFragment] = []
    var selectedFragmentIndex: Int?

    var repairTraceHighlightCount = 0

    var attempts: [AttemptRecord] = []

    /// Permanent fixture chrome. There is no state in which this UI may claim
    /// to be live.
    var sourceBadge: String {
        switch phase {
        case .setup, .coached, .firstSuccess, .controlsIntro, .proof: "PROTOTYPE / PROTOTIPO"
        case .tutorSpeaking, .floorYielded: "REPLAY · NOT LIVE / NO EN VIVO"
        }
    }

    var selectedFragment: RepairFragment? {
        guard let index = selectedFragmentIndex, repairWindow.indices.contains(index) else { return nil }
        return repairWindow[index]
    }

    /// Gate for exact-heard claims. The silent fixture deliberately returns
    /// false even though it renders a useful visual timeline.
    var hasRenderedAudioRepairEvidence: Bool {
        !repairWindow.isEmpty
            && repairWindow.allSatisfy { $0.source == .renderedAudio }
    }
}
