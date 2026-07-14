import Foundation

/// Sanitized fallback for the selected Gate 0 PARTIAL product branch. It
/// replays explicit local repair—not the legacy overlap simulation—and every
/// learner measurement is visibly fixture data.
enum KaiwaLoopReplayFixture {
    static let sessionID = UUID(uuidString: "A14A0000-0000-4000-8000-000000000001")!
    static let reportID = UUID(uuidString: "A14A0000-0000-4000-8000-000000000002")!

    static let configuration = ConversationSessionConfiguration(
        sessionID: sessionID,
        sceneID: .restaurant,
        obligationID: KaiwaLoopState.obligationID,
        maximumBufferedEvents: ReplayConversationScript.maximumEventCount
    )

    static let attemptFull = attempt(
        uuid: "A14A1000-0000-4000-8000-000000000001",
        scaffold: .full,
        number: 1,
        duration: 3.4,
        onset: 1.8,
        repairCount: 0
    )
    static let attemptRhythm = attempt(
        uuid: "A14A1000-0000-4000-8000-000000000002",
        scaffold: .rhythmOnly,
        number: 2,
        duration: 3.0,
        onset: 1.5,
        repairCount: 0
    )
    static let attemptBeforeRepair = attempt(
        uuid: "A14A1000-0000-4000-8000-000000000003",
        scaffold: .none,
        number: 3,
        duration: 3.2,
        onset: 2.2,
        repairCount: 0
    )
    static let attemptAfterRepair = attempt(
        uuid: "A14A1000-0000-4000-8000-000000000004",
        scaffold: .none,
        number: 4,
        duration: 2.4,
        onset: 1.0,
        repairCount: 1
    )

    static let cachedAction = NextLearningAction(
        schemaVersion: 1,
        reportID: reportID,
        model: "ma-kaiwa-replay-v1",
        source: .cachedFixture,
        action: .advance,
        reason: .completedAfterRepair,
        explanationES: "Ya puedes pasar al siguiente objetivo práctico.",
        evidenceReasonES: "Datos de demostración: la misma obligación se completó después de una reparación.",
        obligationID: KaiwaLoopState.obligationID
    )

    static let script: ReplayConversationScript = {
        var events: [ConversationEvent] = []
        func append(
            at milliseconds: UInt64,
            _ payload: ConversationEventPayload,
            provenance: ConversationEvidenceProvenance = .fixtureSimulation
        ) {
            let sequence = events.count
            events.append(
                ConversationEvent(
                    schemaVersion: 1,
                    sequence: sequence,
                    monotonicNanoseconds: milliseconds * 1_000_000,
                    sessionID: sessionID,
                    sceneID: .restaurant,
                    obligationID: KaiwaLoopState.obligationID,
                    correlationID: "kaiwa-partial-replay-\(sequence)",
                    source: .labeledReplay,
                    evidence: .replay(provenance),
                    payload: payload
                )
            )
        }

        append(at: 0, .sessionConnecting)
        append(at: 100, .sessionReady)
        append(at: 300, .lessonStarted)
        append(at: 650, .coachedRoundStarted(.full))
        append(at: 1_300, .attemptCompleted(attemptFull), provenance: .fixtureSimulation)
        append(at: 1_650, .coachedRoundStarted(.rhythmOnly))
        append(at: 2_300, .attemptCompleted(attemptRhythm))
        append(at: 2_650, .coachedRoundStarted(.none))
        append(at: 3_300, .attemptCompleted(attemptBeforeRepair))
        append(at: 3_700, .firstExchangeCompleted)
        append(at: 4_250, .controlsIntroduced)
        append(at: 4_800, .tutorAudioScheduled(.tutorTurn))
        append(at: 4_900, .tutorOutputStarted(RestaurantForOneFixture.continuationLine))
        for (index, beat) in RestaurantForOneFixture.tutorBeats.prefix(3).enumerated() {
            append(
                at: 5_300 + UInt64(index * 350),
                .timelineBeatAdvanced(beat),
                provenance: .fixtureSimulation
            )
        }
        append(at: 6_500, .localRepairRequested)
        append(at: 6_600, .tutorOutputCancelled)
        append(
            at: 6_800,
            .repairWindowFrozen(
                .controlledSegment(
                    id: ControlledSegment.restaurantRepair.id,
                    obligationID: KaiwaLoopState.obligationID
                )
            )
        )
        append(at: 7_400, .tutorAudioScheduled(.repairBeat))
        append(
            at: 7_900,
            .controlledSegmentPlayed(ControlledSegment.restaurantRepair.id)
        )
        append(
            at: 8_300,
            .sceneResumeStarted(obligationID: KaiwaLoopState.obligationID)
        )
        append(
            at: 8_800,
            .sceneResumed(obligationID: KaiwaLoopState.obligationID)
        )
        append(at: 9_300, .attemptCompleted(attemptAfterRepair))
        append(at: 9_700, .learningActionReady(cachedAction))
        append(at: 10_100, .sessionEnded)

        return try! ReplayConversationScript(configuration: configuration, events: events)
    }()

    private static func attempt(
        uuid: String,
        scaffold: ScaffoldLevel,
        number: Int,
        duration: TimeInterval,
        onset: TimeInterval,
        repairCount: Int
    ) -> ConversationAttemptEvidence {
        ConversationAttemptEvidence(
            id: UUID(uuidString: uuid)!,
            obligationID: KaiwaLoopState.obligationID,
            scaffold: scaffold,
            attemptNumber: number,
            capturedDuration: duration,
            estimatedVoiceOnset: onset,
            speechPresenceDetected: true,
            selfReportedCompleted: true,
            repairCount: repairCount,
            provenance: .fixtureSimulation
        )
    }
}
