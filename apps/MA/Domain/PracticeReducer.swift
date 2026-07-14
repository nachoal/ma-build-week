import Foundation

/// Pure state transitions. No side effects, no clocks, no randomness.
enum PracticeReducer {
    static func reduce(_ state: PracticeState, _ event: PracticeEvent) -> PracticeState {
        var s = state
        switch event {
        case .fixtureTimeAdvanced(let t):
            s.fixtureTime = max(s.fixtureTime, t)

        case .coachedRoundStarted(let scaffold):
            // The ladder starts from setup at full scaffold; later rounds only
            // advance to strictly less help after a self-reported success.
            switch s.phase {
            case .setup:
                guard scaffold == .full else { return state }
            case .coached:
                guard !s.coachedAwaitingAssessment,
                      let nextScaffold = Self.nextScaffold(after: s.coachedScaffold),
                      scaffold == nextScaffold,
                      s.coachedAttempts.last == s.coachedScaffold
                else { return state }
            default:
                return state
            }
            s.phase = .coached
            s.coachedScaffold = scaffold
            s.coachedRoundRetries = 0

        case .coachedAttemptMarked(let scaffold):
            guard s.phase == .coached,
                  scaffold == s.coachedScaffold,
                  !s.coachedAwaitingAssessment,
                  s.coachedAttempts.last != scaffold
            else { return state }
            s.coachedAwaitingAssessment = true

        case .coachedAttemptSucceeded(let scaffold):
            guard s.phase == .coached,
                  s.coachedAwaitingAssessment,
                  scaffold == s.coachedScaffold
            else { return state }
            s.coachedAwaitingAssessment = false
            s.coachedAttempts.append(scaffold)

        case .coachedAttemptRetried(let scaffold):
            guard s.phase == .coached,
                  s.coachedAwaitingAssessment,
                  scaffold == s.coachedScaffold
            else { return state }
            s.coachedAwaitingAssessment = false
            s.coachedRoundRetries += 1
            s.coachedTotalRetries += 1

        case .firstExchangeCompleted:
            guard s.phase == .coached,
                  !s.coachedAwaitingAssessment,
                  s.coachedAttempts == [.full, .rhythmOnly, .none]
            else { return state }
            s.phase = .firstSuccess

        case .controlsIntroStarted:
            guard s.phase == .firstSuccess else { return state }
            s.phase = .controlsIntro

        case .tutorOutputStarted(let line):
            guard s.phase == .controlsIntro || s.phase == .tutorSpeaking
            else { return state }
            s.phase = .tutorSpeaking
            s.tutorLine = line
            s.tutorOutputActive = true

        case .tutorTranscriptDelta(let line):
            guard s.phase == .tutorSpeaking else { return state }
            s.tutorLine = line

        case .timelineBeatAdvanced(let beat):
            guard s.phase == .tutorSpeaking, s.tutorOutputActive else { return state }
            // Replay adapters may retry delivery; a timeline beat identity is
            // append-only and idempotent so SwiftUI never receives duplicate IDs.
            guard !s.timelineBeats.contains(where: { $0.id == beat.id }) else { return state }
            s.timelineBeats.append(beat)

        case .backchannelDetected(let at):
            // Invariant: a はい never changes phase and never touches tutor
            // output. It only raises the overlay.
            guard s.phase == .tutorSpeaking else { return state }
            s.backchannel = BackchannelAcknowledgement(at: at)
            s.backchannelCount += 1
            s.backchannelMarks.append(at)

        case .backchannelDecayed:
            s.backchannel = nil

        case .takeFloorDetected(let at):
            guard s.phase == .tutorSpeaking,
                  s.tutorOutputActive,
                  s.pendingYieldAt == nil
            else { return state }
            s.pendingYieldAt = at
            s.yieldedAt = at
            s.backchannel = nil

        case .tutorOutputCancelled:
            guard s.phase == .tutorSpeaking,
                  s.tutorOutputActive,
                  s.pendingYieldAt != nil
            else { return state }
            s.tutorOutputActive = false

        case .repairWindowFrozen:
            guard let yieldedAt = s.pendingYieldAt, !s.tutorOutputActive else { return state }
            s.repairWindow = freezeFragments(
                beats: s.timelineBeats, endingAt: yieldedAt, window: 4.0
            )
            s.selectedFragmentIndex = s.repairWindow.count >= 2
                ? s.repairWindow.count - 2
                : s.repairWindow.indices.last
            s.phase = .floorYielded

        case .repairTraceHighlighted:
            guard s.phase == .floorYielded else { return state }
            s.repairTraceHighlightCount += 1

        case .resumed:
            guard s.phase == .floorYielded else { return state }
            s.pendingYieldAt = nil
            s.phase = .tutorSpeaking
            s.tutorOutputActive = true

        case .attemptCompleted(let attempt):
            // Attempts close only while the resumed natural sequence is
            // running, after a real yield/repair cycle produced evidence.
            guard s.phase == .tutorSpeaking,
                  s.yieldedAt != nil,
                  attempt.completed,
                  attempt.onsetLatency.isFinite,
                  attempt.onsetLatency >= 0,
                  attempt.rescueCount >= 0,
                  s.attempts.count < 2,
                  !s.attempts.contains(where: { $0.id == attempt.id })
            else { return state }
            s.attempts.append(attempt)

        case .sessionEnded:
            // Proof requires the expected phase and both attempt records —
            // there is no path to the summary without its evidence.
            guard s.phase == .tutorSpeaking,
                  Self.isProofEligible(s.attempts)
            else { return state }
            s.phase = .proof
            s.tutorOutputActive = false
            s.pendingYieldAt = nil
            s.backchannel = nil
        }
        return s
    }

    /// Scaffold removal order for the coached ladder: full → rhythm → nothing.
    static func nextScaffold(after scaffold: ScaffoldLevel) -> ScaffoldLevel? {
        switch scaffold {
        case .full: .rhythmOnly
        case .rhythmOnly: ScaffoldLevel.none
        case .none: nil
        }
    }

    /// This target's proof is a deterministic sample, so eligibility is
    /// intentionally narrow. A future measured presentation gets its own
    /// provenance-aware contract instead of silently reusing sample data.
    static func isProofEligible(_ attempts: [AttemptRecord]) -> Bool {
        guard attempts.count == 2 else { return false }
        let first = attempts[0]
        let second = attempts[1]
        return first.id != second.id
            && first.scaffold == .full
            && second.scaffold == .rhythmOnly
            && first.completed && second.completed
            && first.provenance == .fixtureSample
            && second.provenance == .fixtureSample
            && first.onsetLatency.isFinite && second.onsetLatency.isFinite
            && first.onsetLatency >= 0 && second.onsetLatency >= 0
            && first.rescueCount >= 0 && second.rescueCount >= 0
    }

    /// The exact-window rule from todo.md Experiment D, applied to fixture
    /// data: the window ends at the last provenance-tagged timeline sample
    /// (never later than the yield decision) and excludes future samples.
    static func freezeFragments(
        beats: [TimelineBeat],
        endingAt yieldTime: Double,
        window: Double
    ) -> [RepairFragment] {
        guard let timelineEnd = beats.map(\.end).max() else { return [] }
        let end = min(yieldTime, timelineEnd)
        let start = end - window
        var fragments: [RepairFragment] = []
        for beat in beats {
            let clippedStart = max(beat.start, start)
            let clippedEnd = min(beat.end, end)
            guard clippedEnd > clippedStart else { continue }
            fragments.append(
                RepairFragment(
                    id: beat.id,
                    start: clippedStart,
                    duration: clippedEnd - clippedStart,
                    amplitude: beat.amplitude,
                    source: beat.source
                )
            )
        }
        return fragments
    }
}
