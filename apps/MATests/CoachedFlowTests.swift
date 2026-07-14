import Testing
@testable import MA

@Suite("First-minute coached ladder with self-assessment")
struct CoachedFlowTests {
    @Test("The ladder runs full → rhythm → memory → first success")
    func ladderStageOrder() {
        var s = PracticeState()
        var phases: [PracticePhase] = [s.phase]
        for event in RestaurantForOneFixture.coachedLadderEvents {
            s = PracticeReducer.reduce(s, event)
            if phases.last != s.phase { phases.append(s.phase) }
        }
        #expect(phases == [.setup, .coached, .firstSuccess])
        #expect(s.coachedAttempts == [.full, .rhythmOnly, .none])
        #expect(s.coachedTotalRetries == 0)

        s = PracticeReducer.reduce(s, .controlsIntroStarted)
        #expect(s.phase == .controlsIntro)

        s = PracticeReducer.reduce(
            s, .tutorOutputStarted(RestaurantForOneFixture.questionLine)
        )
        #expect(s.phase == .tutorSpeaking)
    }

    @Test("The ladder cannot start anywhere but full scaffold from setup")
    func ladderStartGuards() {
        let setup = PracticeState()
        #expect(PracticeReducer.reduce(setup, .coachedRoundStarted(.rhythmOnly)) == setup)
        #expect(PracticeReducer.reduce(setup, .coachedRoundStarted(.none)) == setup)
    }

    @Test("Marking an attempt only opens the self-assessment — no progress yet")
    func markingOpensAssessmentOnly() {
        var s = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))

        #expect(s.coachedAwaitingAssessment)
        #expect(s.coachedAttempts.isEmpty)
        // While awaiting, nothing else moves: no re-mark, no round advance.
        #expect(PracticeReducer.reduce(s, .coachedAttemptMarked(.full)) == s)
        #expect(PracticeReducer.reduce(s, .coachedRoundStarted(.rhythmOnly)) == s)
        #expect(PracticeReducer.reduce(s, .firstExchangeCompleted) == s)
    }

    @Test("«Me salió» records the success and enables the next rung")
    func successAdvancesScaffold() {
        var s = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptSucceeded(.full))

        #expect(!s.coachedAwaitingAssessment)
        #expect(s.coachedAttempts == [.full])

        s = PracticeReducer.reduce(s, .coachedRoundStarted(.rhythmOnly))
        #expect(s.coachedScaffold == .rhythmOnly)
    }

    @Test("«Necesito otra vez» stays on the same scaffold and counts the retry")
    func retryStaysOnSameScaffold() {
        var s = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptRetried(.full))

        #expect(!s.coachedAwaitingAssessment)
        #expect(s.coachedAttempts.isEmpty)
        #expect(s.coachedScaffold == .full)
        #expect(s.coachedRoundRetries == 1)
        #expect(s.coachedTotalRetries == 1)
        // A retry does NOT unlock the next rung.
        #expect(PracticeReducer.reduce(s, .coachedRoundStarted(.rhythmOnly)) == s)
        // The learner can mark again on the same rung.
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))
        #expect(s.coachedAwaitingAssessment)
    }

    @Test("Assessment verdicts require an open assessment and matching scaffold")
    func assessmentGuards() {
        var s = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        // No verdict without marking first.
        #expect(PracticeReducer.reduce(s, .coachedAttemptSucceeded(.full)) == s)
        #expect(PracticeReducer.reduce(s, .coachedAttemptRetried(.full)) == s)

        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))
        // Wrong scaffold verdicts are no-ops.
        #expect(PracticeReducer.reduce(s, .coachedAttemptSucceeded(.rhythmOnly)) == s)
        #expect(PracticeReducer.reduce(s, .coachedAttemptRetried(.none)) == s)
    }

    @Test("First success requires exactly three self-reported successes in order")
    func firstSuccessRequiresThreeSuccesses() {
        var s = PracticeReducer.reduce(PracticeState(), .coachedRoundStarted(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.full))
        s = PracticeReducer.reduce(s, .coachedAttemptSucceeded(.full))
        #expect(PracticeReducer.reduce(s, .firstExchangeCompleted) == s)

        s = PracticeReducer.reduce(s, .coachedRoundStarted(.rhythmOnly))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.rhythmOnly))
        s = PracticeReducer.reduce(s, .coachedAttemptSucceeded(.rhythmOnly))
        #expect(PracticeReducer.reduce(s, .firstExchangeCompleted) == s)

        s = PracticeReducer.reduce(s, .coachedRoundStarted(.none))
        s = PracticeReducer.reduce(s, .coachedAttemptMarked(.none))
        s = PracticeReducer.reduce(s, .coachedAttemptSucceeded(.none))
        s = PracticeReducer.reduce(s, .firstExchangeCompleted)
        #expect(s.phase == .firstSuccess)
    }

    @Test("Controls intro is reachable only from first success")
    func controlsIntroGuard() {
        let setup = PracticeState()
        #expect(PracticeReducer.reduce(setup, .controlsIntroStarted) == setup)
        let coached = PracticeReducer.reduce(setup, .coachedRoundStarted(.full))
        #expect(PracticeReducer.reduce(coached, .controlsIntroStarted) == coached)
    }

    @Test("Coached phases stay labeled bilingual prototype — never replay, never live")
    func coachedBadges() {
        var s = PracticeState()
        for event in RestaurantForOneFixture.coachedLadderEvents + [.controlsIntroStarted] {
            s = PracticeReducer.reduce(s, event)
            #expect(s.sourceBadge == "PROTOTYPE / PROTOTIPO")
        }
    }

    @Test("Intent flow: mark, retry once, succeed, through the ladder")
    @MainActor
    func intentFlow() {
        let feature = PracticeFeature()
        feature.send(.beginCoachedPractice)
        #expect(feature.state.phase == .coached)
        #expect(feature.state.coachedScaffold == .full)

        // Success requires the learner's verdict, not the mark alone.
        feature.send(.markCoachedAttempt)
        #expect(feature.state.coachedAwaitingAssessment)
        feature.send(.assessCoachedRetry)
        #expect(feature.state.coachedScaffold == .full)
        #expect(feature.state.coachedRoundRetries == 1)

        feature.send(.markCoachedAttempt)
        feature.send(.assessCoachedSuccess)
        #expect(feature.state.coachedScaffold == .rhythmOnly)
        #expect(feature.state.coachedRoundRetries == 0)

        feature.send(.markCoachedAttempt)
        feature.send(.assessCoachedSuccess)
        #expect(feature.state.coachedScaffold == ScaffoldLevel.none)

        feature.send(.markCoachedAttempt)
        feature.send(.assessCoachedSuccess)
        #expect(feature.state.phase == .firstSuccess)

        // Invalid intents at this point are ignored.
        feature.send(.markCoachedAttempt)
        feature.send(.assessCoachedSuccess)
        #expect(feature.state.phase == .firstSuccess)

        feature.send(.acknowledgeFirstSuccess)
        #expect(feature.state.phase == .controlsIntro)

        feature.send(.startListening)
        #expect(feature.state.phase == .tutorSpeaking)
        #expect(feature.state.timelineBeats.count == 4)
    }

    @Test("A fresh feature cannot bypass the coached ladder")
    @MainActor
    func directNaturalModeIsBlocked() {
        let feature = PracticeFeature()
        feature.send(.startListening)
        #expect(feature.state.phase == .setup)
    }
}
