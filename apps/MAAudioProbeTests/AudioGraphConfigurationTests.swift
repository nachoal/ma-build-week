import Testing
@testable import MAAudioProbe

@Suite("Audio graph configuration")
struct AudioGraphConfigurationTests {
    @Test("Configuration hashing is deterministic and sensitive to topology")
    func deterministicHash() throws {
        let baseline = configuration(inputVoiceProcessingEnabled: true)
        let repeated = configuration(inputVoiceProcessingEnabled: true)
        let bypassedTopology = configuration(inputVoiceProcessingEnabled: false)

        let baselineHash = try baseline.configurationHash()

        #expect(baselineHash.count == 64)
        #expect(baselineHash == (try repeated.configurationHash()))
        #expect(baselineHash != (try bypassedTopology.configurationHash()))
    }

    private func configuration(
        inputVoiceProcessingEnabled: Bool
    ) -> AudioGraphConfiguration {
        AudioGraphConfiguration(
            schemaVersion: 1,
            audioDeviceOwner: "AudioGraphController",
            transport: "websocket",
            mediaLibrary: "AVFAudio.AVAudioEngine/VoiceProcessingIO",
            model: "gpt-realtime-2.1",
            vadType: "server_vad",
            createResponse: false,
            interruptResponse: false,
            category: "playAndRecord",
            mode: "voiceChat",
            options: ["defaultToSpeaker"],
            inputRouteTypes: ["BuiltInMic"],
            outputRouteTypes: ["Speaker"],
            sessionSampleRate: 48_000,
            inputChannelCount: 1,
            outputChannelCount: 2,
            ioBufferDuration: 0.01,
            inputLatency: 0.01,
            outputLatency: 0.01,
            playerPresentationLatency: 0.02,
            inputNodeSampleRate: 48_000,
            inputNodeChannelCount: 1,
            mixerSampleRate: 48_000,
            mixerChannelCount: 2,
            playbackSampleRate: 24_000,
            playbackChannelCount: 1,
            inputVoiceProcessingEnabled: inputVoiceProcessingEnabled,
            outputVoiceProcessingEnabled: true,
            inputVoiceProcessingBypassed: false,
            inputVoiceProcessingMuted: false
        )
    }
}
