import Testing
@testable import MA

@Suite("Repair-window freeze with explicit provenance")
struct RepairWindowTests {
    private let beats = RestaurantForOneFixture.tutorBeats

    @Test("Yield freezes exactly four fragments totalling four seconds")
    func fourFragmentsFourSeconds() {
        let fragments = PracticeReducer.freezeFragments(
            beats: beats, endingAt: RestaurantForOneFixture.yieldAt, window: 4.0
        )
        #expect(fragments.count == 4)
        let total = fragments.map(\.duration).reduce(0, +)
        #expect(abs(total - 4.0) < 0.001)
    }

    @Test("The window ends at the last timeline sample, not the yield decision")
    func windowEndsAtTimelineSample() {
        let fragments = PracticeReducer.freezeFragments(beats: beats, endingAt: 8.4, window: 4.0)
        let end = fragments.map { $0.start + $0.duration }.max()
        let timelineEnd = beats.map(\.end).max()
        #expect(end == timelineEnd)
        #expect(end == 8.0)
    }

    @Test("Fragments preserve their source beats and provenance")
    func fragmentsWithinTimelineRanges() {
        let fragments = PracticeReducer.freezeFragments(beats: beats, endingAt: 8.4, window: 4.0)
        for fragment in fragments {
            let source = beats.first { $0.id == fragment.id }
            #expect(source != nil)
            if let source {
                #expect(fragment.start >= source.start)
                #expect(fragment.start + fragment.duration <= source.end)
                #expect(fragment.amplitude == source.amplitude)
                #expect(fragment.source == source.source)
            }
        }
    }

    @Test("A future beat is excluded even if the yield is later")
    func futureBeatExcluded() {
        // Only the first five fixture beats advanced; yielding at 8.4 must not
        // invent samples from beats 5–7.
        let partial = Array(beats.prefix(5))
        let fragments = PracticeReducer.freezeFragments(beats: partial, endingAt: 8.4, window: 4.0)
        let end = fragments.map { $0.start + $0.duration }.max()
        #expect(end == 5.0)
        #expect(fragments.allSatisfy { $0.id < 5 })
    }

    @Test("The chosen micro-lesson fragment is inside the frozen window")
    func selectedFragmentValid() {
        var s = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            s = PracticeReducer.reduce(s, event)
        }
        #expect(s.phase == .floorYielded)
        #expect(s.selectedFragmentIndex == s.repairWindow.count - 2)
        #expect(s.selectedFragment != nil)
        #expect(!s.hasRenderedAudioRepairEvidence)
    }

    @Test("No beats at all freezes an empty window instead of crashing")
    func emptyBeats() {
        let fragments = PracticeReducer.freezeFragments(beats: [], endingAt: 8.4, window: 4.0)
        #expect(fragments.isEmpty)
    }

    @Test("Only rendered-audio provenance satisfies the evidence gate")
    func renderedAudioEvidenceGate() {
        var state = PracticeState()
        state.repairWindow = [
            RepairFragment(
                id: 1, start: 0, duration: 1, amplitude: 0.5,
                source: .renderedAudio
            ),
        ]
        #expect(state.hasRenderedAudioRepairEvidence)

        state.repairWindow.append(
            RepairFragment(
                id: 2, start: 1, duration: 1, amplitude: 0.5,
                source: .fixtureSimulation
            )
        )
        #expect(!state.hasRenderedAudioRepairEvidence)
    }
}
