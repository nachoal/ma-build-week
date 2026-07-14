import Testing
@testable import MA

@Suite("Backchannel is an overlay, never an interruption")
struct BackchannelContinuityTests {
    private func speakingState() -> PracticeState {
        var s = PracticeState()
        for event in RestaurantForOneFixture.naturalReadyEvents {
            s = PracticeReducer.reduce(s, event)
        }
        s = PracticeReducer.reduce(
            s, .tutorOutputStarted(RestaurantForOneFixture.questionLine)
        )
        for beat in RestaurantForOneFixture.tutorBeats.prefix(4) {
            s = PracticeReducer.reduce(s, .timelineBeatAdvanced(beat))
        }
        return s
    }

    @Test("はい never changes phase and never touches tutor output")
    func haiPreservesFloorAndOutput() {
        let before = speakingState()
        let after = PracticeReducer.reduce(before, .backchannelDetected(at: 4.4))

        #expect(after.phase == .tutorSpeaking)
        #expect(after.tutorOutputActive == before.tutorOutputActive)
        #expect(after.timelineBeats == before.timelineBeats)
        #expect(after.yieldedAt == nil)
        #expect(after.repairWindow.isEmpty)
        #expect(after.backchannel == BackchannelAcknowledgement(at: 4.4))
        #expect(after.backchannelCount == 1)
    }

    @Test("Tutor keeps rendering beats through the acknowledgement")
    func beatsContinueThroughOverlay() {
        var s = PracticeReducer.reduce(speakingState(), .backchannelDetected(at: 4.4))
        let nextBeat = RestaurantForOneFixture.tutorBeats[4]
        s = PracticeReducer.reduce(s, .timelineBeatAdvanced(nextBeat))
        #expect(s.timelineBeats.count == 5)
        #expect(s.phase == .tutorSpeaking)
    }

    @Test("Decay clears only the overlay; the mark and count survive")
    func decayClearsOverlayOnly() {
        var s = PracticeReducer.reduce(speakingState(), .backchannelDetected(at: 4.4))
        s = PracticeReducer.reduce(s, .backchannelDecayed)
        #expect(s.backchannel == nil)
        #expect(s.backchannelCount == 1)
        #expect(s.backchannelMarks == [4.4])
        #expect(s.phase == .tutorSpeaking)
    }

    @Test("A second はい stacks the count without any interruption")
    func repeatedHai() {
        var s = PracticeReducer.reduce(speakingState(), .backchannelDetected(at: 2.2))
        s = PracticeReducer.reduce(s, .backchannelDetected(at: 4.4))
        #expect(s.backchannelCount == 2)
        #expect(s.backchannelMarks == [2.2, 4.4])
        #expect(s.phase == .tutorSpeaking)
        #expect(s.tutorOutputActive)
    }
}
