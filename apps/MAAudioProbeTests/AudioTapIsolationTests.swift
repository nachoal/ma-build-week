@preconcurrency import AVFAudio
import Foundation
import Testing
@testable import MAAudioProbe

@Suite("AVFAudio callback isolation")
struct AudioTapIsolationTests {
    @Test("Input and mixer taps run safely away from the main actor")
    func callbacksAreNonisolated() async {
        let worker = AudioCallbackWorker(
            inputSink: { _ in },
            evidenceStore: AudioGraphEvidenceStore(),
            diagnostics: ProbeDiagnostics()
        )
        let inputTap = AudioGraphController.makeInputTap(worker: worker)
        let mixerTap = AudioGraphController.makeMixerTap(worker: worker)

        await withCheckedContinuation { continuation in
            DispatchQueue(label: "com.ia.ma.tests.probe-audio-taps").async {
                let format = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: 48_000,
                    channels: 1,
                    interleaved: false
                )!
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 960)!
                buffer.frameLength = 960
                buffer.floatChannelData?[0].update(
                    repeating: 0.1,
                    count: Int(buffer.frameLength)
                )
                let time = AVAudioTime(sampleTime: 0, atRate: 48_000)
                inputTap(buffer, time)
                mixerTap(buffer, time)
                continuation.resume()
            }
        }
    }

    @Test("Self-induced route configuration does not stop the probe")
    func routePolicy() {
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.categoryChange))
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.override))
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.routeConfigurationChange))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.newDeviceAvailable))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.oldDeviceUnavailable))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.unknown))
    }
}
