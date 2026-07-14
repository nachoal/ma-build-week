import Testing
@testable import MA

@Suite("Voice-ink geometry is deterministic")
struct VoiceInkDeterminismTests {
    @Test("Identical timestamps produce identical speaking geometry")
    func speakingDeterminism() {
        let a = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.speakingLayers(), time: 2.5, breathing: true
        )
        let b = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.speakingLayers(), time: 2.5, breathing: true
        )
        #expect(a == b)
    }

    @Test("Breathing modulation is a pure function of time")
    func breathingPure() {
        #expect(
            VoiceInkGeometry.breathingScale(at: 1.23, breathing: true)
                == VoiceInkGeometry.breathingScale(at: 1.23, breathing: true)
        )
        #expect(VoiceInkGeometry.breathingScale(at: 0.9, breathing: true) != 1.0)
    }

    @Test("Reduce Motion freezes breathing at the rest pose for any time")
    func reduceMotionStatic() {
        let t0 = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.speakingLayers(), time: 0, breathing: false
        )
        let t99 = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.speakingLayers(), time: 99.7, breathing: false
        )
        #expect(t0 == t99)
        #expect(VoiceInkGeometry.breathingScale(at: 42, breathing: false) == 1.0)
    }

    @Test("The はい wake reveal is deterministic and clamped")
    func wakeRevealDeterministic() {
        #expect(VoiceInkGeometry.wakeReveal(elapsedSinceBackchannel: 0.45, reduceMotion: false) == 0.5)
        #expect(VoiceInkGeometry.wakeReveal(elapsedSinceBackchannel: -1, reduceMotion: false) == 0)
        #expect(VoiceInkGeometry.wakeReveal(elapsedSinceBackchannel: 30, reduceMotion: false) == 1)
        let a = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.wakeLayers(reveal: 0.5), time: 0, breathing: false
        )
        let b = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.wakeLayers(reveal: 0.5), time: 0, breathing: false
        )
        #expect(a == b)
    }

    @Test("Reduce Motion shows the completed wake immediately")
    func reduceMotionWakeComplete() {
        #expect(VoiceInkGeometry.wakeReveal(elapsedSinceBackchannel: 0.01, reduceMotion: true) == 1.0)
    }

    @Test("Yield geometry is static and stable")
    func yieldDeterminism() {
        let a = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.yieldLayers(), time: 0, breathing: false
        )
        let b = VoiceInkGeometry.fingerprint(
            layers: VoiceInkGeometry.yieldLayers(), time: 5, breathing: false
        )
        #expect(a == b)
    }
}
