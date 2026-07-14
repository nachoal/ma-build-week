import Testing
@testable import MA

@Suite("Proof shows learner facts, never model confidence")
struct ProofFactsTests {
    private func proofState() -> PracticeState {
        var s = PracticeState()
        for event in RestaurantForOneFixture.heroEventLog {
            s = PracticeReducer.reduce(s, event)
        }
        return s
    }

    @Test("Two attempts with the fixture's exact evidence")
    func attemptFacts() {
        let s = proofState()
        #expect(s.attempts.count == 2)
        let one = s.attempts[0]
        let two = s.attempts[1]

        #expect(one.scaffold == .full)
        #expect(one.onsetLatency == 3.8)
        #expect(one.rescueCount == 1)
        #expect(one.completed)

        #expect(two.scaffold == .rhythmOnly)
        #expect(two.onsetLatency == 1.2)
        #expect(two.rescueCount == 0)
        #expect(two.completed)
    }

    @Test("The delta the learner sees is 2.6 seconds less hesitation")
    func onsetDelta() {
        let s = proofState()
        let delta = s.attempts[0].onsetLatency - s.attempts[1].onsetLatency
        #expect(abs(delta - 2.6) < 0.0001)
    }

    @Test("Scaffold visibly decreased between attempts")
    func scaffoldDecreased() {
        let s = proofState()
        #expect(s.attempts[0].scaffold == .full)
        #expect(s.attempts[1].scaffold == .rhythmOnly)
    }

    @Test("Evidence dimensions are learner-understandable Spanish")
    func scaffoldDescriptions() {
        #expect(ScaffoldLevel.full.spanishDescription == "Con la frase completa a la vista")
        #expect(ScaffoldLevel.rhythmOnly.spanishDescription == "Solo con el ritmo")
        #expect(ScaffoldLevel.none.spanishDescription == "Sin ninguna ayuda")
    }
}
