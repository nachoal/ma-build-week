import Foundation

/// Pure reducer for the labeled PARTIAL fallback. Invalid, stale, or
/// contradictory normalized events are ignored instead of fabricating proof.
enum KaiwaLoopReplayReducer {
    static func reduce(
        _ state: KaiwaLoopState,
        _ event: ConversationEvent
    ) -> KaiwaLoopState {
        guard event.isStructurallyValid,
              event.source == .labeledReplay,
              event.sessionID == KaiwaLoopReplayFixture.sessionID,
              event.sceneID == .restaurant,
              event.obligationID == KaiwaLoopState.obligationID,
              !event.supportsLiveClaim,
              !event.supportsExactHeardClaim else { return state }

        var next = state
        next.presentationSource = .labeledReplay

        switch event.payload {
        case .sessionConnecting, .sessionReady, .sessionWaiting:
            break

        case .sessionFailed:
            next.lastError = .hardwareUnavailable

        case .lessonStarted:
            guard next.phase == .setup else { return state }

        case .coachedRoundStarted(let scaffold):
            next = KaiwaLoopReducer.reduce(next, .beginCoached(scaffold))

        case .attemptCompleted(let attempt):
            guard attempt.provenance == .fixtureSimulation,
                  attempt.obligationID == KaiwaLoopState.obligationID,
                  attempt.selfReportedCompleted,
                  attempt.capturedDuration.isFinite,
                  attempt.capturedDuration >= 0,
                  attempt.estimatedVoiceOnset?.isFinite == true,
                  !next.attempts.contains(where: { $0.id == attempt.id }) else { return state }

            next = KaiwaLoopReducer.reduce(
                next,
                .recordAttempt(PracticeAttemptEvidence(replay: attempt))
            )

        case .firstExchangeCompleted:
            guard next.phase == .firstSuccess,
                  next.completedPreRepairAttempt?.provenance == .replayFixture else { return state }
            next = KaiwaLoopReducer.reduce(next, .confirmFirstExchange)

        case .controlsIntroduced:
            next = KaiwaLoopReducer.reduce(next, .introduceControls)

        case .tutorAudioScheduled:
            break

        case .tutorOutputStarted:
            guard next.phase == .controls else { return state }
            next = KaiwaLoopReducer.reduce(next, .beginNatural)
            next = KaiwaLoopReducer.reduce(next, .naturalPlaybackBegan)

        case .timelineBeatAdvanced(let beat):
            guard next.phase == .natural,
                  beat.source == .fixtureSimulation else { return state }

        case .localRepairRequested:
            guard next.phase == .natural,
                  !next.naturalStopRecorded else { return state }
            next = KaiwaLoopReducer.reduce(next, .requestRepair)

        case .tutorOutputCancelled:
            guard next.phase == .natural, next.naturalStopRecorded else { return state }
            next = KaiwaLoopReducer.reduce(next, .completeRepairStop)

        case .repairWindowFrozen(let selection):
            guard next.phase == .repair,
                  case .controlledSegment(let id, let obligationID) = selection,
                  id == next.repairSegment.id,
                  obligationID == KaiwaLoopState.obligationID else { return state }

        case .controlledSegmentPlayed(let id):
            guard next.phase == .repair, id == next.repairSegment.id else { return state }
            next = KaiwaLoopReducer.reduce(next, .completeControlledSegment)

        case .sceneResumeStarted(let obligationID):
            guard next.phase == .repair,
                  obligationID == KaiwaLoopState.obligationID else { return state }
            next = KaiwaLoopReducer.reduce(next, .beginResume)

        case .sceneResumed(let obligationID):
            guard next.phase == .resuming,
                  obligationID == KaiwaLoopState.obligationID,
                  next.naturalStopRecorded,
                  next.repairSegmentPlayed else { return state }
            next = KaiwaLoopReducer.reduce(next, .completeResume)

        case .learningActionReady(let action):
            guard next.phase == .proof,
                  next.completedPostRepairAttempt?.provenance == .replayFixture,
                  action.source == .cachedFixture,
                  action.model == "ma-kaiwa-replay-v1",
                  action.obligationID == KaiwaLoopState.obligationID,
                  action.action == .advance,
                  action.reason == .completedAfterRepair else { return state }
            next = KaiwaLoopReducer.reduce(next, .setLearningAction(action))

        case .sessionEnded:
            guard next.phase == .proof,
                  next.completedPreRepairAttempt?.provenance == .replayFixture,
                  next.completedPostRepairAttempt?.provenance == .replayFixture,
                  next.nextLearningAction?.source == .cachedFixture else { return state }
            next = KaiwaLoopReducer.reduce(next, .finishLesson)

        case .tutorTranscriptDelta,
             .learnerSpeechStarted,
             .learnerPartialTranscript,
             .backchannelDetected,
             .takeFloorDetected:
            // The selected PARTIAL fallback contains none of these. In
            // particular, it cannot replay unproven overlap classification.
            return state
        }
        return next
    }

    static func replay(_ events: [ConversationEvent]) -> KaiwaLoopState {
        events.reduce(into: KaiwaLoopState()) { state, event in
            state = reduce(state, event)
        }
    }
}
