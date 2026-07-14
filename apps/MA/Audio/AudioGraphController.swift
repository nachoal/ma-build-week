@preconcurrency import AVFAudio
import Foundation
import UIKit

/// The submission app's sole AVAudioSession/AVAudioEngine owner. Playback and
/// learner capture are intentionally mutually exclusive in the PARTIAL branch.
@MainActor
final class AudioGraphController: ProductAudioControlling {
    private let session: AVAudioSession
    private let center: NotificationCenter
    private let permission: any RecordPermissionProviding
    private let eventContinuation: AsyncStream<ProductAudioEvent>.Continuation

    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var notificationTokens: [NSObjectProtocol] = []
    private var playbackGeneration: UInt64 = 0
    private var playbackContinuation: CheckedContinuation<Void, Error>?
    private var captureGeneration: UInt64 = 0
    private var captureWorker: LearnerCaptureWorker?
    private var captureRequest: CaptureRequest?
    private var captureStartedAt: Date?
    private var captureTimeoutTask: Task<Void, Never>?
    private var inputTapInstalled = false

    init(
        session: AVAudioSession = .sharedInstance(),
        center: NotificationCenter = .default,
        permission: any RecordPermissionProviding = SystemRecordPermissionProvider()
    ) {
        self.session = session
        self.center = center
        self.permission = permission
        let pair = AsyncStream.makeStream(
            of: ProductAudioEvent.self,
            bufferingPolicy: .bufferingNewest(64)
        )
        events = pair.stream
        eventContinuation = pair.continuation
        observeLifecycle()
    }

    deinit {
        for token in notificationTokens {
            center.removeObserver(token)
        }
        eventContinuation.finish()
        captureTimeoutTask?.cancel()
    }

    func play(_ prompt: BundledPrompt) async throws {
        if case .capturing = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .requestingPermission = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .playing = state {
            await stop(.replacement)
        }

        let file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: AudioAssetCatalog.url(for: prompt))
        } catch let error as ProductAudioFailure {
            setState(.failed(error))
            throw error
        } catch {
            setState(.failed(.invalidAudioFormat))
            throw ProductAudioFailure.invalidAudioFormat
        }
        guard file.length > 0 else {
            setState(.failed(.invalidAudioFormat))
            throw ProductAudioFailure.invalidAudioFormat
        }

        do {
            try configureSession()
            let (engine, player) = try ensureGraph(format: file.processingFormat)
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            playbackGeneration &+= 1
            let generation = playbackGeneration
            setState(.playing(prompt))

            try await withCheckedThrowingContinuation { continuation in
                playbackContinuation = continuation
                player.scheduleFile(
                    file,
                    at: nil,
                    completionCallbackType: .dataPlayedBack
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.completePlayback(prompt: prompt, generation: generation)
                    }
                }
                player.play()
            }
        } catch let error as ProductAudioFailure {
            if error != .interrupted {
                setState(.failed(error))
            }
            throw error
        } catch {
            setState(.failed(.hardwareUnavailable))
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    func startCapture(_ request: CaptureRequest) async throws {
        if case .capturing = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .requestingPermission = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .playing = state {
            await stop(.replacement)
        }

        captureGeneration &+= 1
        let generation = captureGeneration
        setState(.requestingPermission)
        let granted = await permission.requestPermission()
        guard !Task.isCancelled,
              generation == captureGeneration,
              state == .requestingPermission else {
            throw ProductAudioFailure.interrupted
        }
        guard granted else {
            setState(.failed(.microphoneDenied))
            throw ProductAudioFailure.microphoneDenied
        }

        do {
            try configureSession()
            let captureFormat = sessionCaptureFormat()
            let (engine, _) = try ensureGraph(format: captureFormat)
            let input = engine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                throw ProductAudioFailure.invalidAudioFormat
            }

            if inputTapInstalled {
                input.removeTap(onBus: 0)
                inputTapInstalled = false
            }
            let worker = LearnerCaptureWorker()
            input.installTap(onBus: 0, bufferSize: 2_048, format: inputFormat) {
                buffer, _ in
                let frameCount = min(Int(buffer.frameLength), 8_192)
                guard frameCount > 0, let channels = buffer.floatChannelData else { return }
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
                worker.enqueue(samples: mono, sampleRate: buffer.format.sampleRate)
            }
            inputTapInstalled = true
            captureWorker = worker
            captureRequest = request
            captureStartedAt = Date()

            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            setState(.capturing(request))
            scheduleCaptureTimeout(for: request)
        } catch let error as ProductAudioFailure {
            removeInputTap()
            captureWorker = nil
            captureRequest = nil
            captureStartedAt = nil
            deactivateGraphWhenIdle()
            setState(.failed(error))
            throw error
        } catch {
            removeInputTap()
            captureWorker = nil
            captureRequest = nil
            captureStartedAt = nil
            deactivateGraphWhenIdle()
            setState(.failed(.hardwareUnavailable))
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    func finishCapture(
        _ disposition: CaptureDisposition
    ) async throws -> CaptureReceipt? {
        guard let request = captureRequest,
              let startedAt = captureStartedAt,
              let worker = captureWorker else {
            return nil
        }

        captureTimeoutTask?.cancel()
        captureTimeoutTask = nil
        removeInputTap()
        let snapshot = worker.snapshot()
        captureWorker = nil
        captureRequest = nil
        captureStartedAt = nil
        deactivateGraphWhenIdle()

        let receipt = CaptureReceipt(
            id: request.id,
            request: request,
            startedAt: startedAt,
            endedAt: Date(),
            capturedDuration: snapshot.duration,
            estimatedVoiceOnset: snapshot.speechPresence
                ? snapshot.estimatedVoiceOnset
                : nil,
            speechPresenceDetected: snapshot.speechPresence,
            sampleRate: snapshot.sampleRate,
            disposition: disposition,
            rawAudioRetained: false
        )
        setState(.idle)
        eventContinuation.yield(.captureFinished(receipt))
        return receipt
    }

    func stop(_ reason: AudioStopReason) async {
        playbackGeneration &+= 1
        captureGeneration &+= 1
        player?.stop()
        if let continuation = playbackContinuation {
            playbackContinuation = nil
            continuation.resume(throwing: ProductAudioFailure.interrupted)
        }
        if captureRequest != nil {
            _ = try? await finishCapture(reason == .lifecycle ? .lifecycle : .cancelled)
        } else if case .playing = state {
            setState(.idle)
        } else if case .requestingPermission = state {
            setState(.idle)
        }
        deactivateGraphWhenIdle()
    }

    func handleLifecycle(_ event: AudioLifecycleEvent) async {
        await stop(.lifecycle)
        teardownGraph()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        eventContinuation.yield(.lifecycleStopped(event))
    }

    private func setState(_ newState: ProductAudioState) {
        state = newState
        eventContinuation.yield(.stateChanged(newState))
    }

    private func configureSession() throws {
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.01)
            try session.setActive(true)
        } catch {
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    private func ensureGraph(
        format: AVAudioFormat
    ) throws -> (AVAudioEngine, AVAudioPlayerNode) {
        if let engine, let player {
            return (engine, player)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw ProductAudioFailure.invalidAudioFormat
        }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        _ = engine.inputNode
        _ = engine.outputNode
        self.engine = engine
        self.player = player
        return (engine, player)
    }

    private func sessionCaptureFormat() -> AVAudioFormat {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: max(1, session.sampleRate),
            channels: AVAudioChannelCount(max(1, session.inputNumberOfChannels)),
            interleaved: false
        ) ?? AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    }

    private func completePlayback(prompt: BundledPrompt, generation: UInt64) {
        guard generation == playbackGeneration,
              case .playing(prompt) = state,
              let continuation = playbackContinuation else { return }
        playbackContinuation = nil
        deactivateGraphWhenIdle()
        setState(.idle)
        eventContinuation.yield(.playbackFinished(prompt))
        continuation.resume()
    }

    private func removeInputTap() {
        guard inputTapInstalled, let engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        inputTapInstalled = false
    }

    private func scheduleCaptureTimeout(for request: CaptureRequest) {
        captureTimeoutTask?.cancel()
        captureTimeoutTask = Task { [weak self] in
            try? await ContinuousClock().sleep(for: request.maximumDuration)
            guard !Task.isCancelled,
                  let self,
                  self.captureRequest?.id == request.id else { return }
            _ = try? await self.finishCapture(.timeLimit)
        }
    }

    private func teardownGraph() {
        removeInputTap()
        player?.stop()
        engine?.stop()
        engine = nil
        player = nil
    }

    private func deactivateGraphWhenIdle() {
        engine?.stop()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    nonisolated static func shouldTearDownForRouteChange(
        _ reason: AVAudioSession.RouteChangeReason
    ) -> Bool {
        switch reason {
        case .categoryChange, .override:
            false
        case .unknown, .newDeviceAvailable, .oldDeviceUnavailable,
             .wakeFromSleep, .noSuitableRouteForCategory,
             .routeConfigurationChange:
            true
        @unknown default:
            true
        }
    }

    private func observeLifecycle() {
        notificationTokens = [
            center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(.enteredBackground)
                }
            },
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: session,
                queue: nil
            ) { [weak self] notification in
                guard let raw = (notification.userInfo?[AVAudioSessionInterruptionTypeKey]
                    as? NSNumber)?.uintValue,
                      raw == AVAudioSession.InterruptionType.began.rawValue else { return }
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(.interruptionBegan)
                }
            },
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: session,
                queue: nil
            ) { [weak self] notification in
                let rawReason = (notification.userInfo?[AVAudioSessionRouteChangeReasonKey]
                    as? NSNumber)?.uintValue
                let reason = rawReason.flatMap(AVAudioSession.RouteChangeReason.init(rawValue:))
                    ?? .unknown
                guard Self.shouldTearDownForRouteChange(reason) else { return }
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(.routeChanged)
                }
            },
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: session,
                queue: nil
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.handleLifecycle(.mediaServicesReset)
                }
            },
        ]
    }
}

struct LearnerCaptureSnapshot: Sendable {
    let duration: TimeInterval
    let estimatedVoiceOnset: TimeInterval?
    let speechPresence: Bool
    let sampleRate: Double
}

/// Audio callbacks do one bounded mono copy, then this serial worker computes
/// aggregate timing/presence. It never retains PCM after a packet is reduced.
final class LearnerCaptureWorker: @unchecked Sendable {
    private let queue = DispatchQueue(
        label: "com.ia.ma.learner-capture",
        qos: .userInitiated
    )
    private var totalFrames: Int64 = 0
    private var firstVoiceFrame: Int64?
    private var voicedPacketCount = 0
    private var sampleRate: Double = 0

    func enqueue(samples: [Float], sampleRate: Double) {
        guard !samples.isEmpty, samples.count <= 8_192,
              sampleRate.isFinite, sampleRate > 0 else { return }
        queue.async { [self] in
            if self.sampleRate == 0 {
                self.sampleRate = sampleRate
            }
            guard abs(self.sampleRate - sampleRate) < 0.5 else { return }
            var energy: Double = 0
            for sample in samples where sample.isFinite {
                let value = Double(sample)
                energy += value * value
            }
            let rms = sqrt(energy / Double(samples.count))
            if rms >= 0.025 {
                if firstVoiceFrame == nil {
                    firstVoiceFrame = totalFrames
                }
                voicedPacketCount += 1
            }
            totalFrames += Int64(samples.count)
        }
    }

    func snapshot() -> LearnerCaptureSnapshot {
        queue.sync {
            let rate = sampleRate
            let presence = voicedPacketCount >= 2
            return LearnerCaptureSnapshot(
                duration: rate > 0 ? Double(totalFrames) / rate : 0,
                estimatedVoiceOnset: presence
                    ? firstVoiceFrame.map { Double($0) / rate }
                    : nil,
                speechPresence: presence,
                sampleRate: rate
            )
        }
    }
}
