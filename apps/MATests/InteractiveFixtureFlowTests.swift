import Testing
@testable import MA

@Suite("Interactive fixture flow")
@MainActor
struct InteractiveFixtureFlowTests {
    private func readyForNaturalMode() -> PracticeFeature {
        let feature = PracticeFeature()
        feature.replay(
            RestaurantForOneFixture.coachedLadderEvents + [.controlsIntroStarted]
        )
        return feature
    }

    @Test("The UI waits for explicit hai and sumimasen intents")
    func waitsForLearnerControls() {
        let feature = readyForNaturalMode()

        feature.send(.startListening)
        #expect(feature.state.phase == .tutorSpeaking)
        #expect(feature.state.tutorOutputActive)
        #expect(feature.state.timelineBeats.count == 4)
        #expect(feature.state.tutorLine == RestaurantForOneFixture.questionLine)
        #expect(feature.state.backchannel == nil)
        #expect(feature.state.yieldedAt == nil)

        feature.send(.sayHai)
        #expect(feature.state.phase == .tutorSpeaking)
        #expect(feature.state.tutorOutputActive)
        #expect(feature.state.backchannel != nil)
        #expect(feature.state.tutorLine == RestaurantForOneFixture.continuationLine)
        #expect(feature.state.timelineBeats == RestaurantForOneFixture.tutorBeats)
        #expect(feature.state.backchannelMarks == [RestaurantForOneFixture.backchannelAt])

        feature.send(.saySumimasen)
        #expect(feature.state.phase == .floorYielded)
        #expect(!feature.state.tutorOutputActive)
        #expect(feature.state.repairWindow.count == 4)
        #expect(feature.state.repairWindow.map(\.duration).reduce(0, +) == 4)
        #expect(!feature.state.hasRenderedAudioRepairEvidence)
    }

    @Test("Manual interactions reduce the same canonical stages as previews and tests")
    func manualUsesCanonicalStages() {
        let feature = readyForNaturalMode()
        var expected = feature.state

        feature.send(.startListening)
        for event in RestaurantForOneFixture.listeningStageEvents {
            expected = PracticeReducer.reduce(expected, event)
        }
        #expect(feature.state == expected)

        feature.send(.sayHai)
        for event in RestaurantForOneFixture.haiStageEvents {
            expected = PracticeReducer.reduce(expected, event)
        }
        #expect(feature.state == expected)

        feature.send(.saySumimasen)
        for event in RestaurantForOneFixture.yieldedStageEvents {
            expected = PracticeReducer.reduce(expected, event)
        }
        #expect(feature.state == expected)
    }

    @Test("Repeated hai acknowledges again without replaying timeline beats")
    func repeatedHaiIsIdempotentForTimeline() {
        let feature = readyForNaturalMode()
        feature.send(.startListening)
        feature.send(.sayHai)
        let beatsAfterFirstHai = feature.state.timelineBeats

        feature.send(.sayHai)

        #expect(feature.state.timelineBeats == beatsAfterFirstHai)
        #expect(Set(feature.state.timelineBeats.map(\.id)).count == beatsAfterFirstHai.count)
        #expect(feature.state.backchannelCount == 2)
        #expect(feature.state.tutorOutputActive)
        #expect(feature.state.phase == .tutorSpeaking)
    }

    @Test("A second pause freezes the latest resumed timeline, not the old window")
    func secondYieldUsesLatestRenderClock() {
        let feature = PracticeFeature()
        var events = RestaurantForOneFixture.throughYieldEvents
        events.append(.resumed)
        events.append(.tutorOutputStarted(RestaurantForOneFixture.repairLine))
        let resumedBeat = RestaurantForOneFixture.resumeBeats[0]
        events.append(.fixtureTimeAdvanced(resumedBeat.end))
        events.append(.timelineBeatAdvanced(resumedBeat))
        feature.replay(events)

        feature.send(.saySumimasen)

        #expect(feature.state.phase == .floorYielded)
        #expect(feature.state.yieldedAt == resumedBeat.end)
        #expect(feature.state.repairWindow.contains(where: { $0.id == resumedBeat.id }))
        #expect(!feature.state.tutorOutputActive)
    }
}
