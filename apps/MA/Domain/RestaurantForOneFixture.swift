import Foundation

struct ScheduledFixtureEvent: Equatable, Sendable {
    /// Seconds from the start of the script segment.
    let offset: Double
    let event: PracticeEvent
}

/// The single deterministic scene for the hackathon slice. Every value here is
/// fixture data — nothing is recorded from a microphone or a provider.
/// Japanese lines still require native-speaker review before public use.
enum RestaurantForOneFixture {
    // MARK: Scene copy (matches docs/design/paper-ui-handoff.md)

    static let sceneKicker = "ESCENA 1 · LLEGAR AL RESTAURANTE"
    static let goal = "Pide una mesa para uno."
    static let goalSubtitle = "Hoy solo necesitas una frase. Apréndela antes de entrar."

    static let phraseJapanese = "一人です"
    static let phraseRomaji = "hitori desu"
    static let phraseSpanish = "Una persona · voy solo."
    static let rhythmBeats = ["hi", "to", "ri", "de", "su"]
    static let scaffoldNote = "Andamio completo. Se retira cuando tú confirmas que te salió."

    static let questionLine = TutorLine(
        japanese: "何名様ですか",
        romaji: "nan-mei-sama desu ka",
        spanish: "¿Cuántas personas?"
    )
    static let continuationLine = TutorLine(
        japanese: "お一人様ですね。ご案内します",
        romaji: "o-hitori-sama desu ne · go-annai shimasu",
        spanish: "Una persona, ¿verdad? Te acompaño."
    )
    static let repairLine = TutorLine(
        japanese: "こちらへどうぞ",
        romaji: "kochira e dōzo",
        spanish: "«Por aquí, por favor.»"
    )
    static let repairCue = "Te está invitando a seguirle. Es un gesto amable, no una pregunta."
    static let nextObjective = "Pedir mesa para dos"

    // MARK: Deterministic envelope

    /// One-second beats; the amplitudes place the loudest beat third inside
    /// the frozen four-second window, matching the Paper repair layout.
    static let beatAmplitudes: [Double] = [0.35, 0.55, 0.75, 1.0, 0.5, 0.65, 1.0, 0.6]

    static var tutorBeats: [TimelineBeat] {
        beatAmplitudes.enumerated().map { index, amplitude in
            TimelineBeat(
                id: index, start: Double(index), duration: 1.0,
                amplitude: amplitude, source: .fixtureSimulation
            )
        }
    }

    /// Falls inside the third of the four strokes visible in the timeline.
    static let backchannelAt = 6.4
    static let yieldAt = 8.4

    // MARK: Canonical staged fixture

    /// The complete first-minute coached ladder: for each rung the learner
    /// marks their attempt, then self-assesses it as a success. Only three
    /// self-reported successes reach first success.
    static let coachedLadderEvents: [PracticeEvent] = [
        .coachedRoundStarted(.full),
        .coachedAttemptMarked(.full),
        .coachedAttemptSucceeded(.full),
        .coachedRoundStarted(.rhythmOnly),
        .coachedAttemptMarked(.rhythmOnly),
        .coachedAttemptSucceeded(.rhythmOnly),
        .coachedRoundStarted(.none),
        .coachedAttemptMarked(.none),
        .coachedAttemptSucceeded(.none),
        .firstExchangeCompleted,
    ]

    /// Canonical prefix required before any natural-sequence event can start.
    static var naturalReadyEvents: [PracticeEvent] {
        coachedLadderEvents + [.controlsIntroStarted]
    }

    /// Screen 02. Manual UI, previews, and tests all reduce this exact array.
    static var listeningStageEvents: [PracticeEvent] {
        var events: [PracticeEvent] = [.tutorOutputStarted(questionLine)]
        for beat in tutorBeats.prefix(4) {
            events.append(.fixtureTimeAdvanced(beat.end))
            events.append(.timelineBeatAdvanced(beat))
        }
        return events
    }

    /// Screen 03. The tutor line advances and the learner's stitch is emitted
    /// without touching output state or the simulated timeline.
    static var haiStageEvents: [PracticeEvent] {
        var events: [PracticeEvent] = [.tutorTranscriptDelta(continuationLine)]
        for beat in tutorBeats.dropFirst(4) {
            if beat.start <= backchannelAt, backchannelAt < beat.end {
                events.append(.backchannelDetected(at: backchannelAt))
            }
            events.append(.fixtureTimeAdvanced(beat.end))
            events.append(.timelineBeatAdvanced(beat))
        }
        return events
    }

    /// Screen 04. A fresh take-floor token authorizes exactly one cancel/freeze
    /// transaction.
    static var yieldedStageEvents: [PracticeEvent] {
        yieldedStageEvents(at: yieldAt)
    }

    /// The first hero pause uses `yieldAt`; later learner pauses use the latest
    /// fixture-render clock so "últimos 4 segundos" never points backward.
    static func yieldedStageEvents(at time: Double) -> [PracticeEvent] {
        [
            .fixtureTimeAdvanced(time),
            .takeFloorDetected(at: time),
            .tutorOutputCancelled,
            .repairWindowFrozen,
        ]
    }

    static var throughYieldEvents: [PracticeEvent] {
        naturalReadyEvents + listeningStageEvents + haiStageEvents + yieldedStageEvents
    }

    static let attemptOne = AttemptRecord(
        id: 1, scaffold: .full, onsetLatency: 3.8, rescueCount: 1,
        completed: true, provenance: .fixtureSample
    )
    static let attemptTwo = AttemptRecord(
        id: 2, scaffold: .rhythmOnly, onsetLatency: 1.2, rescueCount: 0,
        completed: true, provenance: .fixtureSample
    )

    /// After the learner resumes: the tutor finishes the beat, both attempts
    /// close, and the scene ends into proof.
    static var resumeBeats: [TimelineBeat] {
        [
            TimelineBeat(
                id: 100, start: yieldAt + 0.4, duration: 1.0,
                amplitude: 0.7, source: .fixtureSimulation
            ),
            TimelineBeat(
                id: 101, start: yieldAt + 1.4, duration: 1.0,
                amplitude: 0.9, source: .fixtureSimulation
            ),
        ]
    }

    static var resumeScript: [ScheduledFixtureEvent] {
        var script: [ScheduledFixtureEvent] = [
            ScheduledFixtureEvent(offset: 0.0, event: .tutorOutputStarted(repairLine))
        ]
        for beat in resumeBeats {
            script.append(
                ScheduledFixtureEvent(
                    offset: beat.end - yieldAt,
                    event: .timelineBeatAdvanced(beat)
                )
            )
        }
        script.append(ScheduledFixtureEvent(offset: 2.6, event: .attemptCompleted(attemptOne)))
        script.append(ScheduledFixtureEvent(offset: 3.0, event: .attemptCompleted(attemptTwo)))
        script.append(ScheduledFixtureEvent(offset: 3.4, event: .sessionEnded))
        return script
    }

    static var proofStageEvents: [PracticeEvent] {
        var events: [PracticeEvent] = [.resumed]
        for scheduled in resumeScript {
            events.append(.fixtureTimeAdvanced(yieldAt + scheduled.offset))
            events.append(scheduled.event)
        }
        return events
    }

    /// The full hero flow as one flat, ordered event log. It includes the
    /// self-assessed beginner ladder before the natural visual simulation so
    /// proof copy can never claim practice that the canonical replay skipped.
    static var heroEventLog: [PracticeEvent] {
        throughYieldEvents + proofStageEvents
    }
}
