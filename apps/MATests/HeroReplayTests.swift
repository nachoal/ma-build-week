import Testing
@testable import MA

@Suite("Full hero replay")
struct HeroReplayTests {
    private func replayHero() -> PracticeState {
        var s = PracticeState()
        for event in RestaurantForOneFixture.heroEventLog {
            s = PracticeReducer.reduce(s, event)
        }
        return s
    }

    @Test("The complete fixture log lands in proof with full evidence")
    func heroPathCompletes() {
        let s = replayHero()
        #expect(s.phase == .proof)
        #expect(s.attempts.count == 2)
        #expect(s.repairWindow.count == 4)
        #expect(s.coachedAttempts == [.full, .rhythmOnly, .none])
        #expect(!s.hasRenderedAudioRepairEvidence)
        #expect(s.backchannelCount == 1)
        #expect(s.backchannelMarks == [RestaurantForOneFixture.backchannelAt])
        #expect(s.yieldedAt == RestaurantForOneFixture.yieldAt)
    }

    @Test("Replay is deterministic: two runs produce identical state")
    func replayIsDeterministic() {
        #expect(replayHero() == replayHero())
    }

    @Test("Every phase of the hero path is reachable in order")
    func phasesInOrder() {
        var s = PracticeState()
        var seen: [PracticePhase] = [s.phase]
        for event in RestaurantForOneFixture.heroEventLog {
            s = PracticeReducer.reduce(s, event)
            if seen.last != s.phase {
                seen.append(s.phase)
            }
        }
        #expect(seen == [
            .setup, .coached, .firstSuccess, .controlsIntro,
            .tutorSpeaking, .floorYielded, .tutorSpeaking, .proof,
        ])
    }

    @Test("Timeline beats stay monotonic after resume")
    func beatTimelineIsMonotonic() {
        let beats = replayHero().timelineBeats
        for pair in zip(beats, beats.dropFirst()) {
            #expect(pair.1.start >= pair.0.end)
        }
    }
}
