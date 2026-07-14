@preconcurrency import AVFAudio
import Foundation

enum AudioGraphControllerError: LocalizedError, Equatable {
    case alreadyRunning
    case microphoneDenied
    case invalidHardwareFormat
    case voiceProcessingUnavailable
    case graphStartFailed
    case graphNotRunning
    case invalidProviderAudio

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            "The audio probe is already running."
        case .microphoneDenied:
            "Microphone access is required. Enable it in Settings."
        case .invalidHardwareFormat:
            "The active audio route has an unsupported format."
        case .voiceProcessingUnavailable:
            "Voice processing could not be enabled on this route."
        case .graphStartFailed:
            "The audio graph could not start."
        case .graphNotRunning:
            "Start the live probe first."
        case .invalidProviderAudio:
            "The tutor audio chunk was invalid."
        }
    }
}

struct AudioGraphRuntimeSnapshot: Sendable, Equatable {
    let configuration: AudioGraphConfiguration
    let configurationHash: String
}

@MainActor
final class AudioGraphController {
    typealias InputSink = AudioCallbackWorker.InputSink

    private let session: AVAudioSession
    private let diagnostics: ProbeDiagnostics
    private let evidenceStore: AudioGraphEvidenceStore

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var playbackFormat: AVAudioFormat?
    private var callbackWorker: AudioCallbackWorker?
    private var notificationTokens: [NSObjectProtocol] = []
    private var nextScheduledPlayerFrame: Int64 = 0
    private(set) var isRunning = false

    init(
        session: AVAudioSession = .sharedInstance(),
        diagnostics: ProbeDiagnostics,
        evidenceStore: AudioGraphEvidenceStore
    ) {
        self.session = session
        self.diagnostics = diagnostics
        self.evidenceStore = evidenceStore
    }

    func start(inputSink: @escaping InputSink) async throws -> AudioGraphRuntimeSnapshot {
        guard !isRunning else { throw AudioGraphControllerError.alreadyRunning }
        guard await requestMicrophonePermission() else {
            throw AudioGraphControllerError.microphoneDenied
        }

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker]
            )
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.01)
            try session.setActive(true)

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let input = engine.inputNode
            _ = engine.outputNode

            try input.setVoiceProcessingEnabled(true)
            input.isVoiceProcessingBypassed = false
            input.isVoiceProcessingInputMuted = false
            guard input.isVoiceProcessingEnabled,
                  engine.outputNode.isVoiceProcessingEnabled,
                  !input.isVoiceProcessingBypassed,
                  !input.isVoiceProcessingInputMuted else {
                throw AudioGraphControllerError.voiceProcessingUnavailable
            }

            guard let playbackFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 24_000,
                channels: 1,
                interleaved: false
            ) else {
                throw AudioGraphControllerError.invalidHardwareFormat
            }
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: playbackFormat)

            let inputFormat = input.outputFormat(forBus: 0)
            let mixerFormat = engine.mainMixerNode.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0,
                  inputFormat.channelCount > 0,
                  mixerFormat.sampleRate > 0,
                  mixerFormat.channelCount > 0 else {
                throw AudioGraphControllerError.invalidHardwareFormat
            }

            try await evidenceStore.configureMixer(sampleRate: mixerFormat.sampleRate)
            let worker = AudioCallbackWorker(
                inputSink: inputSink,
                evidenceStore: evidenceStore,
                diagnostics: diagnostics
            )
            installInputTap(on: input, format: inputFormat, worker: worker)
            installMixerTap(on: engine.mainMixerNode, format: mixerFormat, worker: worker)

            self.engine = engine
            self.player = player
            self.playbackFormat = playbackFormat
            self.callbackWorker = worker
            observeLifecycle(engine: engine)

            engine.prepare()
            try engine.start()
            isRunning = true

            let configuration = makeConfiguration(
                input: input,
                output: engine.outputNode,
                inputFormat: inputFormat,
                mixerFormat: mixerFormat,
                playbackFormat: playbackFormat
            )
            let hash = try configuration.configurationHash()
            await diagnostics.record(
                .configuration,
                details: [
                    "category": configuration.category,
                    "graph_hash": hash,
                    "graph_owner": configuration.audioDeviceOwner,
                    "input_latency_ms": Self.milliseconds(configuration.inputLatency),
                    "input_node_channels": String(configuration.inputNodeChannelCount),
                    "input_node_rate": String(Int(configuration.inputNodeSampleRate)),
                    "input_routes": configuration.inputRouteTypes.joined(separator: ","),
                    "input_vp": String(configuration.inputVoiceProcessingEnabled),
                    "input_vp_bypassed": String(configuration.inputVoiceProcessingBypassed),
                    "input_vp_muted": String(configuration.inputVoiceProcessingMuted),
                    "io_buffer_ms": Self.milliseconds(configuration.ioBufferDuration),
                    "media_library": configuration.mediaLibrary,
                    "mixer_channels": String(configuration.mixerChannelCount),
                    "transport": "websocket",
                    "mixer_rate": String(Int(mixerFormat.sampleRate)),
                    "mode": configuration.mode,
                    "model": configuration.model,
                    "options": configuration.options.joined(separator: ","),
                    "output_latency_ms": Self.milliseconds(configuration.outputLatency),
                    "output_routes": configuration.outputRouteTypes.joined(separator: ","),
                    "output_vp": String(configuration.outputVoiceProcessingEnabled),
                    "playback_channels": String(configuration.playbackChannelCount),
                    "playback_rate": String(Int(configuration.playbackSampleRate)),
                    "session_input_channels": String(configuration.inputChannelCount),
                    "session_output_channels": String(configuration.outputChannelCount),
                    "session_rate": String(Int(configuration.sessionSampleRate)),
                ]
            )
            return AudioGraphRuntimeSnapshot(
                configuration: configuration,
                configurationHash: hash
            )
        } catch let error as AudioGraphControllerError {
            await teardown()
            throw error
        } catch {
            await teardown()
            throw AudioGraphControllerError.graphStartFailed
        }
    }

    func schedule(_ chunk: RealtimeOutputAudioChunk) async throws {
        guard isRunning, let player, let playbackFormat else {
            throw AudioGraphControllerError.graphNotRunning
        }
        guard let eventID = chunk.eventID, !eventID.isEmpty,
              let responseID = chunk.responseID, !responseID.isEmpty,
              let itemID = chunk.itemID, !itemID.isEmpty,
              let outputIndex = chunk.outputIndex, outputIndex >= 0,
              let contentIndex = chunk.contentIndex, contentIndex >= 0,
              !chunk.pcm16Data.isEmpty,
              chunk.pcm16Data.count <= 48_000,
              chunk.pcm16Data.count.isMultiple(of: MemoryLayout<Int16>.size) else {
            throw AudioGraphControllerError.invalidProviderAudio
        }

        let frameCount = chunk.pcm16Data.count / MemoryLayout<Int16>.size
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: playbackFormat,
                  frameCapacity: AVAudioFrameCount(frameCount)
              ),
              let channel = buffer.int16ChannelData?[0] else {
            throw AudioGraphControllerError.invalidProviderAudio
        }
        buffer.frameLength = AVAudioFrameCount(frameCount)
        chunk.pcm16Data.withUnsafeBytes { source in
            guard let baseAddress = source.baseAddress else { return }
            channel.update(
                from: baseAddress.assumingMemoryBound(to: Int16.self),
                count: frameCount
            )
        }

        let playerStartFrame = max(
            nextScheduledPlayerFrame,
            currentPlayerFrame(player)
        )
        try await evidenceStore.schedule(
            itemID: itemID,
            contentIndex: contentIndex,
            frameCount: Int64(frameCount),
            playerStartFrame: playerStartFrame
        )
        nextScheduledPlayerFrame = playerStartFrame + Int64(frameCount)
        player.scheduleBuffer(
            buffer,
            completionCallbackType: .dataConsumed,
            completionHandler: { _ in }
        )
        if !player.isPlaying {
            player.play()
        }
        await diagnostics.record(
            .playbackScheduled,
            details: [
                "frames": String(frameCount),
                "event_id": eventID,
                "response_id": responseID,
                "item_id": itemID,
                "output_index": String(outputIndex),
                "content_index": String(contentIndex),
            ]
        )
    }

    func localStop() async throws -> AudioGraphStopEvidence {
        guard isRunning, let player else {
            throw AudioGraphControllerError.graphNotRunning
        }
        let renderedFrame = currentPlayerFrame(player)
        player.stop()
        let evidence = try await evidenceStore.stop(playerRenderedFrame: renderedFrame)
        nextScheduledPlayerFrame = 0
        await diagnostics.record(
            .playbackStopped,
            details: [
                "epoch": String(evidence.epoch),
                "rendered_frame": String(evidence.playerRenderedFrame),
                "truncate_ms": evidence.truncationTarget.map {
                    String($0.audioEndMilliseconds)
                } ?? "none",
                "window": evidence.renderedWindow == nil ? "unavailable" : "available",
            ]
        )
        return evidence
    }

    func teardown() async {
        removeLifecycleObservers()
        if let engine {
            engine.inputNode.removeTap(onBus: 0)
            engine.mainMixerNode.removeTap(onBus: 0)
            player?.stop()
            engine.stop()
            if engine.inputNode.isVoiceProcessingEnabled {
                try? engine.inputNode.setVoiceProcessingEnabled(false)
            }
        }
        engine = nil
        player = nil
        playbackFormat = nil
        callbackWorker = nil
        nextScheduledPlayerFrame = 0
        isRunning = false
        await evidenceStore.resetForLifecycle()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        await diagnostics.record(.lifecycle, details: ["state": "audio_stopped"])
    }

    private func requestMicrophonePermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private func installInputTap(
        on input: AVAudioInputNode,
        format: AVAudioFormat,
        worker: AudioCallbackWorker
    ) {
        input.installTap(onBus: 0, bufferSize: 4_800, format: format) { buffer, when in
            let frameCount = min(Int(buffer.frameLength), 19_200)
            guard frameCount > 0,
                  let channels = buffer.floatChannelData else { return }
            let channelCount = max(1, Int(buffer.format.channelCount))
            var mono = [Float](repeating: 0, count: frameCount)
            if channelCount == 1 {
                mono.withUnsafeMutableBufferPointer { destination in
                    destination.baseAddress?.update(from: channels[0], count: frameCount)
                }
            } else {
                for frame in 0..<frameCount {
                    var sum: Float = 0
                    for channel in 0..<channelCount {
                        sum += channels[channel][frame]
                    }
                    mono[frame] = sum / Float(channelCount)
                }
            }
            worker.enqueueInput(
                CapturedFloatFrame(
                    samples: mono,
                    sampleRate: buffer.format.sampleRate,
                    timing: Self.timing(from: when, fallbackRate: buffer.format.sampleRate)
                )
            )
        }
    }

    private func installMixerTap(
        on mixer: AVAudioMixerNode,
        format: AVAudioFormat,
        worker: AudioCallbackWorker
    ) {
        mixer.installTap(onBus: 0, bufferSize: 4_800, format: format) { buffer, when in
            let frameCount = min(Int(buffer.frameLength), 19_200)
            guard frameCount > 0,
                  let channels = buffer.floatChannelData else { return }
            let channelCount = max(1, Int(buffer.format.channelCount))
            var mono = [Float](repeating: 0, count: frameCount)
            for frame in 0..<frameCount {
                var sum: Float = 0
                for channel in 0..<channelCount {
                    sum += channels[channel][frame]
                }
                mono[frame] = sum / Float(channelCount)
            }
            worker.enqueueRendered(
                mono,
                timing: Self.timing(from: when, fallbackRate: buffer.format.sampleRate)
            )
        }
    }

    nonisolated private static func timing(
        from time: AVAudioTime,
        fallbackRate: Double
    ) -> AudioTapTiming {
        AudioTapTiming(
            sampleTime: time.isSampleTimeValid ? time.sampleTime : nil,
            hostTime: time.isHostTimeValid ? time.hostTime : nil,
            sampleRate: time.isSampleTimeValid ? time.sampleRate : fallbackRate
        )
    }

    nonisolated private static func milliseconds(_ seconds: TimeInterval) -> String {
        String(format: "%.3f", seconds * 1_000)
    }

    private func currentPlayerFrame(_ player: AVAudioPlayerNode) -> Int64 {
        guard player.isPlaying,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return 0
        }
        return max(0, playerTime.sampleTime)
    }

    private func makeConfiguration(
        input: AVAudioInputNode,
        output: AVAudioOutputNode,
        inputFormat: AVAudioFormat,
        mixerFormat: AVAudioFormat,
        playbackFormat: AVAudioFormat
    ) -> AudioGraphConfiguration {
        AudioGraphConfiguration(
            schemaVersion: 1,
            audioDeviceOwner: "AudioGraphController",
            transport: "websocket",
            mediaLibrary: "AVFAudio.AVAudioEngine/VoiceProcessingIO",
            model: ProbeConfiguration.realtimeModel,
            vadType: "server_vad",
            createResponse: false,
            interruptResponse: false,
            category: session.category.rawValue,
            mode: session.mode.rawValue,
            options: ["defaultToSpeaker"],
            inputRouteTypes: session.currentRoute.inputs.map { $0.portType.rawValue },
            outputRouteTypes: session.currentRoute.outputs.map { $0.portType.rawValue },
            sessionSampleRate: session.sampleRate,
            inputChannelCount: session.inputNumberOfChannels,
            outputChannelCount: session.outputNumberOfChannels,
            ioBufferDuration: session.ioBufferDuration,
            inputLatency: session.inputLatency,
            outputLatency: session.outputLatency,
            inputNodeSampleRate: inputFormat.sampleRate,
            inputNodeChannelCount: Int(inputFormat.channelCount),
            mixerSampleRate: mixerFormat.sampleRate,
            mixerChannelCount: Int(mixerFormat.channelCount),
            playbackSampleRate: playbackFormat.sampleRate,
            playbackChannelCount: Int(playbackFormat.channelCount),
            inputVoiceProcessingEnabled: input.isVoiceProcessingEnabled,
            outputVoiceProcessingEnabled: output.isVoiceProcessingEnabled,
            inputVoiceProcessingBypassed: input.isVoiceProcessingBypassed,
            inputVoiceProcessingMuted: input.isVoiceProcessingInputMuted
        )
    }

    private func observeLifecycle(engine: AVAudioEngine) {
        let center = NotificationCenter.default
        notificationTokens = [
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: nil
            ) { [weak self] notification in
                let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey]
                    .flatMap { $0 as? NSNumber }?.stringValue ?? "unknown"
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(kind: .routeChanged, reason: reason)
                }
            },
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: nil
            ) { [weak self] notification in
                let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey]
                    .flatMap { $0 as? NSNumber }?.stringValue ?? "unknown"
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(kind: .interrupted, reason: type)
                }
            },
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: session,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(kind: .error, reason: "media_reset")
                }
            },
            center.addObserver(
                forName: .AVAudioEngineConfigurationChange,
                object: engine,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(kind: .error, reason: "engine_configuration")
                }
            },
        ]
    }

    private func handleLifecycle(kind: ProbeDiagnosticKind, reason: String) async {
        guard isRunning else { return }
        await diagnostics.record(kind, details: ["reason": reason])
        await teardown()
    }

    private func removeLifecycleObservers() {
        let center = NotificationCenter.default
        notificationTokens.forEach(center.removeObserver)
        notificationTokens.removeAll()
    }
}
