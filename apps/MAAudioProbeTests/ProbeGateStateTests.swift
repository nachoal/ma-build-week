import Testing
@testable import MAAudioProbe

@Suite("MA audio probe gate")
struct ProbeGateStateTests {
    @Test("Live product binding starts locked")
    func liveProductBindingStartsLocked() {
        #expect(ProbeGateState.liveProductBindingUnlocked == false)
    }
}
