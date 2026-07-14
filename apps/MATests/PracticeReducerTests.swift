import Testing
@testable import MA

@Suite("Reducer transitions")
struct PracticeReducerTests {
    private let line = RestaurantForOneFixture.questionLine

    private func controlsIntroState() -> PracticeState {
        var s = PracticeState()
        for event in RestaurantForOneFixture.naturalReadyEvents {
            s = PracticeReducer.reduce(s, event)
        }
        return s
    }

    private func speakingBeforeYield() -> PracticeState {
        PracticeReducer.reduce(controlsIntroState(), .tutorOutputStarted(line))
    }

    @Test("Tutor output requires the controls introduction")
    func outputCannotBypassCoaching() {
        let setup = PracticeState()
        #expect(PracticeReducer.reduce(setup, .tutorOutputStarted(line)) == setup)
        let s = PracticeReducer.reduce(controlsIntroState(), .tutorOutputStarted(line))
        #expect(s.phase == .tutorSpeaking)
        #expect(s.tutorOutputActive)
        #expect(s.tutorLine == line)
    }

    @Test("Beats append only while tutor output is active")
    func beatsRequireActiveOutput() {
        var s = speakingBeforeYield()
        let beat = TimelineBeat(
            id: 0, start: 0, duration: 1, amplitude: 0.5, source: .renderedAudio
        )
        s = PracticeReducer.reduce(s, .timelineBeatAdvanced(beat))
        #expect(s.timelineBeats == [beat])

        // After cancellation nothing more renders.
        s = PracticeReducer.reduce(s, .takeFloorDetected(at: 1.0))
        s = PracticeReducer.reduce(s, .tutorOutputCancelled)
        let late = TimelineBeat(
            id: 9, start: 1, duration: 1, amplitude: 0.5, source: .renderedAudio
        )
        let after = PracticeReducer.reduce(s, .timelineBeatAdvanced(late))
        #expect(after.timelineBeats == [beat])
    }

    @Test("Timeline beat delivery is idempotent by identity")
    func duplicateTimelineBeatIsIgnored() {
        var s = speakingBeforeYield()
        let beat = TimelineBeat(
            id: 7, start: 0, duration: 1, amplitude: 0.8, source: .renderedAudio
        )
        s = PracticeReducer.reduce(s, .timelineBeatAdvanced(beat))
        s = PracticeReducer.reduce(s, .timelineBeatAdvanced(beat))

        #expect(s.timelineBeats == [beat])
    }

    /// Post-repair state: the only place attempts may close.
    private func resumedAfterRepair() -> PracticeState {
        var s = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            s = PracticeReducer.reduce(s, event)
        }
        return PracticeReducer.reduce(s, .resumed)
    }

    @Test("Attempt completion is idempotent across a paused resume script")
    func duplicateAttemptIsIgnored() {
        var s = resumedAfterRepair()
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptOne))
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptOne))

        #expect(s.attempts == [RestaurantForOneFixture.attemptOne])
    }

    @Test("Attempts require the resumed phase after a real yield")
    func attemptsRequireYieldEvidence() {
        // No yield happened: speaking alone cannot record attempts.
        let speakingOnly = speakingBeforeYield()
        let blocked = PracticeReducer.reduce(
            speakingOnly, .attemptCompleted(RestaurantForOneFixture.attemptOne)
        )
        #expect(blocked.attempts.isEmpty)

        // During the repair card itself no attempt may close either.
        var yielded = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            yielded = PracticeReducer.reduce(yielded, event)
        }
        let blockedInRepair = PracticeReducer.reduce(
            yielded, .attemptCompleted(RestaurantForOneFixture.attemptOne)
        )
        #expect(blockedInRepair.attempts.isEmpty)

        let incomplete = AttemptRecord(
            id: 99, scaffold: .none, onsetLatency: 0.8,
            rescueCount: 0, completed: false, provenance: .fixtureSample
        )
        let resumed = PracticeReducer.reduce(yielded, .resumed)
        #expect(PracticeReducer.reduce(resumed, .attemptCompleted(incomplete)) == resumed)
    }

    @Test("Yield sequence reaches floorYielded and resume returns to speaking")
    func yieldAndResume() {
        var s = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            s = PracticeReducer.reduce(s, event)
        }
        #expect(s.phase == .floorYielded)
        #expect(!s.tutorOutputActive)

        let resumed = PracticeReducer.reduce(s, .resumed)
        #expect(resumed.phase == .tutorSpeaking)
        #expect(resumed.tutorOutputActive)
        #expect(resumed.pendingYieldAt == nil)
        #expect(resumed.yieldedAt == RestaurantForOneFixture.yieldAt)
    }

    @Test("An old yield token cannot cancel or freeze output after resume")
    func staleYieldCannotReopenRepair() {
        var s = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            s = PracticeReducer.reduce(s, event)
        }
        s = PracticeReducer.reduce(s, .resumed)
        let resumed = s

        s = PracticeReducer.reduce(s, .tutorOutputCancelled)
        s = PracticeReducer.reduce(s, .repairWindowFrozen)

        #expect(s == resumed)
        #expect(s.phase == .tutorSpeaking)
        #expect(s.tutorOutputActive)
    }

    @Test("Proof requires the expected phase and both attempt records")
    func sessionEndGuard() {
        // Setup and evidence-less speaking never reach proof.
        #expect(PracticeReducer.reduce(PracticeState(), .sessionEnded).phase == .setup)
        let speakingOnly = speakingBeforeYield()
        #expect(PracticeReducer.reduce(speakingOnly, .sessionEnded).phase == .tutorSpeaking)

        // One attempt is not enough evidence.
        var s = resumedAfterRepair()
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptOne))
        #expect(PracticeReducer.reduce(s, .sessionEnded).phase == .tutorSpeaking)

        // Both attempts recorded in the resumed phase: proof unlocks.
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptTwo))
        let proof = PracticeReducer.reduce(s, .sessionEnded)
        #expect(proof.phase == .proof)
        #expect(!proof.tutorOutputActive)
        #expect(proof.pendingYieldAt == nil)
        #expect(proof.backchannel == nil)

        // The repair card itself can never jump to proof.
        var yielded = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            yielded = PracticeReducer.reduce(yielded, event)
        }
        #expect(PracticeReducer.reduce(yielded, .sessionEnded).phase == .floorYielded)
    }

    @Test("Proof eligibility rejects malformed or wrongly sourced attempts")
    func malformedProofEvidenceIsRejected() {
        let one = RestaurantForOneFixture.attemptOne
        let two = RestaurantForOneFixture.attemptTwo
        #expect(PracticeReducer.isProofEligible([one, two]))
        #expect(!PracticeReducer.isProofEligible([two, one]))

        let sameScaffold = AttemptRecord(
            id: 2, scaffold: .full, onsetLatency: 1.2,
            rescueCount: 0, completed: true, provenance: .fixtureSample
        )
        #expect(!PracticeReducer.isProofEligible([one, sameScaffold]))

        let nanLatency = AttemptRecord(
            id: 2, scaffold: .rhythmOnly, onsetLatency: .nan,
            rescueCount: 0, completed: true, provenance: .fixtureSample
        )
        #expect(!PracticeReducer.isProofEligible([one, nanLatency]))

        let negativeRescues = AttemptRecord(
            id: 2, scaffold: .rhythmOnly, onsetLatency: 1.2,
            rescueCount: -1, completed: true, provenance: .fixtureSample
        )
        #expect(!PracticeReducer.isProofEligible([one, negativeRescues]))

        let measured = AttemptRecord(
            id: 2, scaffold: .rhythmOnly, onsetLatency: 1.2,
            rescueCount: 0, completed: true, provenance: .measured
        )
        #expect(!PracticeReducer.isProofEligible([one, measured]))
    }

    @Test("A third sample attempt cannot leak into the two-row proof")
    func thirdAttemptIsRejected() {
        var s = resumedAfterRepair()
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptOne))
        s = PracticeReducer.reduce(s, .attemptCompleted(RestaurantForOneFixture.attemptTwo))
        let third = AttemptRecord(
            id: 3, scaffold: .none, onsetLatency: 0.6,
            rescueCount: 0, completed: true, provenance: .fixtureSample
        )
        s = PracticeReducer.reduce(s, .attemptCompleted(third))
        #expect(s.attempts == [
            RestaurantForOneFixture.attemptOne,
            RestaurantForOneFixture.attemptTwo,
        ])
    }

    @Test("Invalid events are no-ops")
    func invalidEventsIgnored() {
        let setup = PracticeState()
        #expect(PracticeReducer.reduce(setup, .backchannelDetected(at: 1)) == setup)
        #expect(PracticeReducer.reduce(setup, .takeFloorDetected(at: 1)) == setup)
        #expect(PracticeReducer.reduce(setup, .repairWindowFrozen) == setup)
        #expect(PracticeReducer.reduce(setup, .resumed) == setup)
        #expect(PracticeReducer.reduce(setup, .repairTraceHighlighted) == setup)
    }

    @Test("Fixture time is monotonic")
    func monotonicTime() {
        var s = PracticeReducer.reduce(PracticeState(), .fixtureTimeAdvanced(5))
        s = PracticeReducer.reduce(s, .fixtureTimeAdvanced(3))
        #expect(s.fixtureTime == 5)
    }
}
