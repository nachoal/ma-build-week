@preconcurrency import AVFAudio
import Foundation
import OSLog
import UIKit

/// The submission app's sole AVAudioSession/AVAudioEngine owner. Playback and
/// learner capture are intentionally mutually exclusive in the PARTIAL branch.
@MainActor
final class AudioGraphController: NSObject, ProductAudioControlling,
    GuidedLessonAudioControlling, AVAudioPlayerDelegate {
    private enum PlaybackKind: Equatable {
        case bundled(BundledPrompt)
        case realtime
    }

    private let session: AVAudioSession
    private let center: NotificationCenter
    private let permission: any RecordPermissionProviding
    private let eventContinuation: AsyncStream<ProductAudioEvent>.Continuation
    private let logger = Logger(subsystem: "com.ia.ma", category: "ProductAudio")

    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle

    private var engine: AVAudioEngine?
    private var playbackPlayer: AVAudioPlayer?
    private var playbackKind: PlaybackKind?
    private var notificationTokens: [NSObjectProtocol] = []
    private var playbackGeneration: UInt64 = 0
    private var playbackContinuation: CheckedContinuation<Void, Error>?
    private var playbackTimeoutTask: Task<Void, Never>?
    private var captureGeneration: UInt64 = 0
    private var captureWorker: LearnerCaptureWorker?
    private var realtimeCaptureWorker: RealtimeCaptureWorker?
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
        super.init()
        observeLifecycle()
    }

    deinit {
        for token in notificationTokens {
            center.removeObserver(token)
        }
        eventContinuation.finish()
        playbackTimeoutTask?.cancel()
        captureTimeoutTask?.cancel()
    }

    func play(_ prompt: BundledPrompt) async throws {
        if case .capturing = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .requestingPermission = state {
            throw ProductAudioFailure.captureInProgress
        }
        if isPlaybackActive {
            await stop(.replacement)
        }

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(contentsOf: AudioAssetCatalog.url(for: prompt))
        } catch let error as ProductAudioFailure {
            setState(.failed(error))
            throw error
        } catch {
            setState(.failed(.invalidAudioFormat))
            throw ProductAudioFailure.invalidAudioFormat
        }
        guard player.duration > 0 else {
            setState(.failed(.invalidAudioFormat))
            throw ProductAudioFailure.invalidAudioFormat
        }

        playbackGeneration &+= 1
        let generation = playbackGeneration
        do {
            try configurePlaybackSession()
            player.delegate = self
            player.numberOfLoops = 0
            player.volume = 1
            guard player.prepareToPlay() else {
                throw ProductAudioFailure.hardwareUnavailable
            }

            playbackPlayer = player
            playbackKind = .bundled(prompt)
            setState(.playing(prompt))
            logger.notice("Starting bundled prompt \(prompt.rawValue, privacy: .public)")

            try await withCheckedThrowingContinuation { continuation in
                playbackContinuation = continuation
                guard player.play() else {
                    playbackContinuation = nil
                    playbackPlayer = nil
                    playbackKind = nil
                    setState(.failed(.hardwareUnavailable))
                    try? session.setActive(false, options: [.notifyOthersOnDeactivation])
                    continuation.resume(throwing: ProductAudioFailure.hardwareUnavailable)
                    return
                }
                schedulePlaybackTimeout(duration: player.duration, generation: generation)
            }
        } catch let error as ProductAudioFailure {
            cleanupPlaybackAttempt(player: player, generation: generation, error: error)
            throw error
        } catch {
            cleanupPlaybackAttempt(
                player: player,
                generation: generation,
                error: .hardwareUnavailable
            )
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    func playRealtimePCM16(_ data: Data) async throws {
        if case .capturing = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .requestingPermission = state {
            throw ProductAudioFailure.captureInProgress
        }
        if isPlaybackActive {
            await stop(.replacement)
        }
        guard !data.isEmpty,
              data.count <= 1_200_000,
              data.count.isMultiple(of: MemoryLayout<Int16>.size) else {
            throw ProductAudioFailure.invalidProviderAudio
        }

        let player: AVAudioPlayer
        do {
            player = try AVAudioPlayer(data: Self.waveData(fromPCM16: data))
        } catch {
            setState(.failed(.invalidProviderAudio))
            throw ProductAudioFailure.invalidProviderAudio
        }
        guard player.duration > 0 else {
            setState(.failed(.invalidProviderAudio))
            throw ProductAudioFailure.invalidProviderAudio
        }

        playbackGeneration &+= 1
        let generation = playbackGeneration
        do {
            try configurePlaybackSession()
            player.delegate = self
            player.numberOfLoops = 0
            player.volume = 1
            guard player.prepareToPlay() else {
                throw ProductAudioFailure.hardwareUnavailable
            }

            playbackPlayer = player
            playbackKind = .realtime
            setState(.playingRealtime)
            logger.notice("Starting bounded Realtime tutor response")

            try await withCheckedThrowingContinuation { continuation in
                playbackContinuation = continuation
                guard player.play() else {
                    playbackContinuation = nil
                    playbackPlayer = nil
                    playbackKind = nil
                    setState(.failed(.hardwareUnavailable))
                    try? session.setActive(false, options: [.notifyOthersOnDeactivation])
                    continuation.resume(throwing: ProductAudioFailure.hardwareUnavailable)
                    return
                }
                schedulePlaybackTimeout(duration: player.duration, generation: generation)
            }
        } catch let error as ProductAudioFailure {
            cleanupPlaybackAttempt(player: player, generation: generation, error: error)
            throw error
        } catch {
            cleanupPlaybackAttempt(
                player: player,
                generation: generation,
                error: .hardwareUnavailable
            )
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    func startCapture(_ request: CaptureRequest) async throws {
        try await beginCapture(request, retainingRealtimePCM: false)
    }

    func startRealtimeCapture(_ request: CaptureRequest) async throws {
        try await beginCapture(request, retainingRealtimePCM: true)
    }

    private func beginCapture(
        _ request: CaptureRequest,
        retainingRealtimePCM: Bool
    ) async throws {
        if case .capturing = state {
            throw ProductAudioFailure.captureInProgress
        }
        if case .requestingPermission = state {
            throw ProductAudioFailure.captureInProgress
        }
        if isPlaybackActive {
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
            try configureCaptureSession()
            let engine = try ensureCaptureGraph()
            let input = engine.inputNode
            let inputFormat = input.outputFormat(forBus: 0)
            guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
                throw ProductAudioFailure.invalidAudioFormat
            }

            if inputTapInstalled {
                input.removeTap(onBus: 0)
                inputTapInstalled = false
            }
            if retainingRealtimePCM {
                let worker = RealtimeCaptureWorker()
                input.installTap(
                    onBus: 0,
                    bufferSize: 2_048,
                    format: inputFormat,
                    block: Self.makeRealtimeCaptureTap(worker: worker)
                )
                realtimeCaptureWorker = worker
                captureWorker = nil
            } else {
                let worker = LearnerCaptureWorker()
                input.installTap(
                    onBus: 0,
                    bufferSize: 2_048,
                    format: inputFormat,
                    block: Self.makeCaptureTap(worker: worker)
                )
                captureWorker = worker
                realtimeCaptureWorker = nil
            }
            inputTapInstalled = true
            captureRequest = request
            captureStartedAt = Date()

            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            setState(.capturing(request))
            if !retainingRealtimePCM {
                scheduleCaptureTimeout(for: request)
            }
        } catch let error as ProductAudioFailure {
            removeInputTap()
            captureWorker = nil
            realtimeCaptureWorker = nil
            captureRequest = nil
            captureStartedAt = nil
            deactivateGraphWhenIdle()
            setState(.failed(error))
            throw error
        } catch {
            removeInputTap()
            captureWorker = nil
            realtimeCaptureWorker = nil
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

    func finishRealtimeCapture(
        _ disposition: CaptureDisposition
    ) async throws -> RealtimeCapturePayload? {
        guard let request = captureRequest,
              let startedAt = captureStartedAt,
              let worker = realtimeCaptureWorker else {
            return nil
        }

        captureTimeoutTask?.cancel()
        captureTimeoutTask = nil
        removeInputTap()
        let snapshot = worker.finishSnapshot()
        realtimeCaptureWorker = nil
        captureWorker = nil
        captureRequest = nil
        captureStartedAt = nil
        deactivateGraphWhenIdle()

        guard !snapshot.overflowed else {
            setState(.failed(.invalidAudioFormat))
            throw ProductAudioFailure.invalidAudioFormat
        }
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
            sampleRate: snapshot.sourceSampleRate,
            disposition: disposition,
            rawAudioRetained: false
        )
        setState(.idle)
        eventContinuation.yield(.captureFinished(receipt))
        return RealtimeCapturePayload(
            receipt: receipt,
            pcm16Data: snapshot.pcm16Data
        )
    }

    func stop(_ reason: AudioStopReason) async {
        playbackGeneration &+= 1
        captureGeneration &+= 1
        playbackTimeoutTask?.cancel()
        playbackTimeoutTask = nil
        playbackPlayer?.stop()
        playbackPlayer?.delegate = nil
        playbackPlayer = nil
        playbackKind = nil
        if let continuation = playbackContinuation {
            playbackContinuation = nil
            continuation.resume(throwing: ProductAudioFailure.interrupted)
        }
        if realtimeCaptureWorker != nil {
            _ = try? await finishRealtimeCapture(
                reason == .lifecycle ? .lifecycle : .cancelled
            )
        } else if captureRequest != nil {
            _ = try? await finishCapture(
                reason == .lifecycle ? .lifecycle : .cancelled
            )
        } else if isPlaybackActive {
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

    private var isPlaybackActive: Bool {
        switch state {
        case .playing, .playingRealtime:
            true
        default:
            false
        }
    }

    private func playbackStateMatches(_ kind: PlaybackKind) -> Bool {
        switch (kind, state) {
        case (.bundled(let prompt), .playing(let activePrompt)):
            prompt == activePrompt
        case (.realtime, .playingRealtime):
            true
        default:
            false
        }
    }

    private func configurePlaybackSession() throws {
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    private func configureCaptureSession() throws {
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setPreferredSampleRate(48_000)
            try session.setPreferredIOBufferDuration(0.01)
            try session.setActive(true)
        } catch {
            throw ProductAudioFailure.hardwareUnavailable
        }
    }

    private func ensureCaptureGraph() throws -> AVAudioEngine {
        if let engine { return engine }
        let engine = AVAudioEngine()
        let input = engine.inputNode
        _ = engine.outputNode
        do {
            try input.setVoiceProcessingEnabled(true)
        } catch {
            throw ProductAudioFailure.hardwareUnavailable
        }
        guard input.isVoiceProcessingEnabled,
              !input.isVoiceProcessingBypassed,
              !input.isVoiceProcessingInputMuted else {
            throw ProductAudioFailure.hardwareUnavailable
        }
        self.engine = engine
        return engine
    }

    private func cleanupPlaybackAttempt(
        player: AVAudioPlayer,
        generation: UInt64,
        error: ProductAudioFailure
    ) {
        guard generation == playbackGeneration else { return }
        if let current = playbackPlayer, current !== player { return }
        playbackTimeoutTask?.cancel()
        playbackTimeoutTask = nil
        if playbackPlayer === player {
            playbackPlayer?.delegate = nil
            playbackPlayer = nil
        }
        playbackKind = nil
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        if error != .interrupted {
            setState(.failed(error))
        }
    }

    private func completePlayback(playerID: ObjectIdentifier, successfully: Bool) {
        guard Self.playbackCallbackMatches(
                  activePlayer: playbackPlayer,
                  callbackPlayerID: playerID
              ),
              let kind = playbackKind,
              playbackStateMatches(kind),
              let continuation = playbackContinuation else { return }
        playbackTimeoutTask?.cancel()
        playbackTimeoutTask = nil
        playbackContinuation = nil
        playbackPlayer?.delegate = nil
        playbackPlayer = nil
        playbackKind = nil
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        logger.notice("Audio playback finished, success=\(successfully)")
        if successfully {
            setState(.idle)
            if case .bundled(let prompt) = kind {
                eventContinuation.yield(.playbackFinished(prompt))
            }
            continuation.resume()
        } else {
            setState(.failed(.hardwareUnavailable))
            continuation.resume(throwing: ProductAudioFailure.hardwareUnavailable)
        }
    }

    private func schedulePlaybackTimeout(duration: TimeInterval, generation: UInt64) {
        playbackTimeoutTask?.cancel()
        let timeoutMilliseconds = Int64(
            max(2, duration + session.outputLatency + 1.5) * 1_000
        )
        playbackTimeoutTask = Task { [weak self] in
            try? await ContinuousClock().sleep(for: .milliseconds(timeoutMilliseconds))
            guard !Task.isCancelled,
                  let self,
                  generation == playbackGeneration,
                  playbackContinuation != nil,
                  let player = playbackPlayer else { return }
            logger.error("Audio playback completion timed out")
            let playerID = ObjectIdentifier(player)
            player.stop()
            completePlayback(playerID: playerID, successfully: false)
        }
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
            if self.realtimeCaptureWorker != nil {
                _ = try? await self.finishRealtimeCapture(.timeLimit)
            } else {
                _ = try? await self.finishCapture(.timeLimit)
            }
        }
    }

    private func teardownGraph() {
        removeInputTap()
        engine?.stop()
        engine = nil
    }

    private func deactivateGraphWhenIdle() {
        engine?.stop()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        let playerID = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            self?.completePlayback(playerID: playerID, successfully: flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: (any Error)?
    ) {
        let playerID = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self,
                  Self.playbackCallbackMatches(
                      activePlayer: self.playbackPlayer,
                      callbackPlayerID: playerID
                  ) else { return }
            self.playbackPlayer?.stop()
            self.completePlayback(playerID: playerID, successfully: false)
        }
    }

    nonisolated static func playbackCallbackMatches(
        activePlayer: AVAudioPlayer?,
        callbackPlayerID: ObjectIdentifier
    ) -> Bool {
        guard let activePlayer else { return false }
        return ObjectIdentifier(activePlayer) == callbackPlayerID
    }

    nonisolated static func shouldTearDownForRouteChange(
        _ reason: AVAudioSession.RouteChangeReason
    ) -> Bool {
        switch reason {
        // These can be emitted by this controller's own category, preferred-I/O,
        // and speaker configuration while the physical ports remain unchanged.
        case .categoryChange, .override, .routeConfigurationChange:
            false
        case .unknown, .newDeviceAvailable, .oldDeviceUnavailable,
             .wakeFromSleep, .noSuitableRouteForCategory:
            true
        @unknown default:
            true
        }
    }

    /// AVFAudio invokes input taps on its realtime messenger queue. Constructing
    /// the callback inside this nonisolated function prevents it from inheriting
    /// `AudioGraphController`'s main-actor executor requirement.
    nonisolated static func makeCaptureTap(
        worker: LearnerCaptureWorker
    ) -> @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void {
        { @Sendable buffer, _ in
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
    }

    nonisolated static func makeRealtimeCaptureTap(
        worker: RealtimeCaptureWorker
    ) -> @Sendable (AVAudioPCMBuffer, AVAudioTime) -> Void {
        { @Sendable buffer, _ in
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
    }

    nonisolated static func waveData(fromPCM16 pcm16: Data) -> Data {
        var data = Data()
        data.reserveCapacity(44 + pcm16.count)
        data.append(contentsOf: Data("RIFF".utf8))
        appendLittleEndian(UInt32(36 + pcm16.count), to: &data)
        data.append(contentsOf: Data("WAVEfmt ".utf8))
        appendLittleEndian(UInt32(16), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt16(1), to: &data)
        appendLittleEndian(UInt32(24_000), to: &data)
        appendLittleEndian(UInt32(48_000), to: &data)
        appendLittleEndian(UInt16(2), to: &data)
        appendLittleEndian(UInt16(16), to: &data)
        data.append(contentsOf: Data("data".utf8))
        appendLittleEndian(UInt32(pcm16.count), to: &data)
        data.append(pcm16)
        return data
    }

    nonisolated private static func appendLittleEndian<T: FixedWidthInteger>(
        _ value: T,
        to data: inout Data
    ) {
        var littleEndian = value.littleEndian
        withUnsafeBytes(of: &littleEndian) { bytes in
            data.append(contentsOf: bytes)
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
