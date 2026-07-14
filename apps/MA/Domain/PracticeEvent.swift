import Foundation

/// Normalized fixture events. Names mirror the ConversationEvent model in
/// todo.md §9 so the eventual ReplayAdapter can emit the same stream.
enum PracticeEvent: Equatable, Sendable {
    case fixtureTimeAdvanced(Double)
    /// First-minute coached ladder (todo.md §3, first 60 seconds).
    case coachedRoundStarted(ScaffoldLevel)
    /// The learner marked their own attempt as spoken — no capture happened.
    case coachedAttemptMarked(ScaffoldLevel)
    /// Self-assessment: the learner's own verdict, never the app's.
    case coachedAttemptSucceeded(ScaffoldLevel)
    case coachedAttemptRetried(ScaffoldLevel)
    case firstExchangeCompleted
    case controlsIntroStarted
    case tutorOutputStarted(TutorLine)
    case tutorTranscriptDelta(TutorLine)
    /// Advances visual/rendered timeline state with explicit beat provenance.
    case timelineBeatAdvanced(TimelineBeat)
    case backchannelDetected(at: Double)
    case backchannelDecayed
    case takeFloorDetected(at: Double)
    case tutorOutputCancelled
    case repairWindowFrozen
    case repairTraceHighlighted
    case resumed
    case attemptCompleted(AttemptRecord)
    case sessionEnded
}

/// User intents. The feature maps these onto explicit fixture events; views
/// never mutate state directly.
enum PracticeIntent: Equatable, Sendable {
    case beginCoachedPractice
    case markCoachedAttempt
    case assessCoachedSuccess
    case assessCoachedRetry
    case acknowledgeFirstSuccess
    case startListening
    case sayHai
    case saySumimasen
    case highlightRepairTrace
    case resume
    case restart
}
