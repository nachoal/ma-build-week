import Testing
@testable import MA

@Suite("Fixture states are always labeled, never presented as live")
struct ReplayLabelTests {
    @Test("Setup and proof carry the PROTOTIPO badge")
    func prototypeBadge() {
        var s = PracticeState()
        #expect(s.sourceBadge == "PROTOTIPO")

        for event in RestaurantForOneFixture.heroEventLog {
            s = PracticeReducer.reduce(s, event)
        }
        #expect(s.phase == .proof)
        #expect(s.sourceBadge == "PROTOTIPO")
    }

    @Test("Visual-sequence phases carry the explicit REPLAY · NO EN VIVO badge")
    func replayBadge() {
        var s = PracticeState()
        for event in RestaurantForOneFixture.throughYieldEvents {
            s = PracticeReducer.reduce(s, event)
        }
        #expect(s.phase == .floorYielded)
        #expect(s.sourceBadge == "REPLAY · NO EN VIVO")
    }

    @Test("No reachable phase ever claims to be live")
    func noLiveClaimAnywhere() {
        var s = PracticeState()
        var badges: Set<String> = [s.sourceBadge]
        for event in RestaurantForOneFixture.heroEventLog {
            s = PracticeReducer.reduce(s, event)
            badges.insert(s.sourceBadge)
        }
        #expect(badges == ["PROTOTIPO", "REPLAY · NO EN VIVO"])
        for badge in badges {
            let claimsLive = badge.contains("EN VIVO") && !badge.contains("NO EN VIVO")
            #expect(!claimsLive)
        }
    }
}
