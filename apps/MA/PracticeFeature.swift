import Foundation
import Observation

/// Presentation owner. Maps user intents onto explicit fixture events and
/// plays deterministic scripts on a continuous clock. No audio, no network.
@MainActor
@Observable
final class PracticeFeature {
    private(set) var state = PracticeState()

    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var decayTask: Task<Void, Never>?

    func send(_ intent: PracticeIntent) {
        switch intent {
        case .beginCoachedPractice:
            guard state.phase == .setup else { return }
            apply(.coachedRoundStarted(.full))

        case .markCoachedAttempt:
            guard state.phase == .coached, !state.coachedAwaitingAssessment else { return }
            apply(.coachedAttemptMarked(state.coachedScaffold))

        case .assessCoachedSuccess:
            guard state.phase == .coached, state.coachedAwaitingAssessment else { return }
            let current = state.coachedScaffold
            apply(.coachedAttemptSucceeded(current))
            if let next = PracticeReducer.nextScaffold(after: current) {
                apply(.coachedRoundStarted(next))
            } else {
                apply(.firstExchangeCompleted)
            }

        case .assessCoachedRetry:
            guard state.phase == .coached, state.coachedAwaitingAssessment else { return }
            apply(.coachedAttemptRetried(state.coachedScaffold))

        case .acknowledgeFirstSuccess:
            guard state.phase == .firstSuccess else { return }
            apply(.controlsIntroStarted)

        case .startListening:
            // Product intent cannot bypass the beginner ladder. Previews and
            // replay adapters advance deterministic events through `replay`.
            guard state.phase == .controlsIntro else { return }
            apply(RestaurantForOneFixture.listeningStageEvents)

        case .sayHai:
            guard state.phase == .tutorSpeaking else { return }
            if state.timelineBeats.count < RestaurantForOneFixture.tutorBeats.count {
                apply(RestaurantForOneFixture.haiStageEvents)
            } else {
                // Further acknowledgements are new learner events, not a
                // reason to replay the fixture stage and duplicate its beats.
                let lastBeat = state.timelineBeats.last
                let marker = lastBeat.map { $0.start + min(0.4, $0.duration * 0.5) }
                    ?? state.fixtureTime
                apply(.backchannelDetected(at: marker))
            }
            scheduleBackchannelDecay()

        case .saySumimasen:
            guard state.phase == .tutorSpeaking else { return }
            cancelPlayback()
            let yieldTime = max(RestaurantForOneFixture.yieldAt, state.fixtureTime)
            apply(RestaurantForOneFixture.yieldedStageEvents(at: yieldTime))

        case .highlightRepairTrace:
            apply(.repairTraceHighlighted)

        case .resume:
            guard state.phase == .floorYielded else { return }
            apply(.resumed)
            play(script: RestaurantForOneFixture.resumeScript, baseTime: state.fixtureTime)

        case .restart:
            cancelPlayback()
            decayTask?.cancel()
            state = PracticeState()
        }
    }

    /// Replays a fixture event log synchronously. Used by previews so every
    /// preview state comes from reduced events, never hand-assembled state.
    func replay(_ events: [PracticeEvent]) {
        var replayed = PracticeState()
        for event in events {
            replayed = PracticeReducer.reduce(replayed, event)
        }
        state = replayed
    }

    private func apply(_ event: PracticeEvent) {
        state = PracticeReducer.reduce(state, event)
    }

    private func apply(_ events: [PracticeEvent]) {
        for event in events {
            apply(event)
        }
    }

    private func play(script: [ScheduledFixtureEvent], baseTime: Double) {
        cancelPlayback()
        playbackTask = Task { [weak self] in
            let clock = ContinuousClock()
            var elapsed = 0.0
            for scheduled in script {
                let delay = scheduled.offset - elapsed
                if delay > 0 {
                    try? await clock.sleep(for: .seconds(delay))
                }
                if Task.isCancelled { return }
                elapsed = max(elapsed, scheduled.offset)
                guard let self else { return }
                self.apply(.fixtureTimeAdvanced(baseTime + scheduled.offset))
                self.apply(scheduled.event)
                if case .backchannelDetected = scheduled.event {
                    self.scheduleBackchannelDecay()
                }
            }
        }
    }

    private func scheduleBackchannelDecay() {
        decayTask?.cancel()
        decayTask = Task { [weak self] in
            // Long enough for a learner (and a live demo audience) to read the
            // continuity state after the 0.9-second wake finishes drawing.
            try? await ContinuousClock().sleep(for: .seconds(3.0))
            if Task.isCancelled { return }
            self?.apply(.backchannelDecayed)
        }
    }

    private func cancelPlayback() {
        playbackTask?.cancel()
        playbackTask = nil
    }
}
