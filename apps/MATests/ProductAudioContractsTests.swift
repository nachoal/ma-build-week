@preconcurrency import AVFAudio
import Foundation
import Testing
@testable import MA

@Suite("Gate 0 PARTIAL product audio contracts")
struct ProductAudioContractsTests {
    @Test("Capability cuts cannot be upgraded at runtime")
    func frozenCapabilities() {
        let capabilities = PracticeCapabilities.gate0Partial

        #expect(capabilities.tutorSource == .bundledLocal)
        #expect(capabilities.repairSource == .controlledLabeledSegment)
        #expect(capabilities.allowsProviderFreeLearnerCapture)
        #expect(!capabilities.allowsLiveRealtime)
        #expect(!capabilities.allowsOverlapFloorPolicy)
        #expect(!capabilities.allowsExactRenderedWindowReplay)
        #expect(capabilities.allowsPostLessonPlanner)
        #expect(capabilities.tutorBadge == "LOCAL · AUDIO INCLUIDO")
        #expect(capabilities.repairBadge == "REPLAY · DEMOSTRACIÓN")
    }

    @Test("All four bundled prompts have one honest provenance label")
    func promptManifestAndLabels() {
        #expect(BundledPrompt.allCases.count == 4)
        #expect(Set(AudioAssetCatalog.assets.map(\.prompt)) == Set(BundledPrompt.allCases))
        #expect(BundledPrompt.repairBeat.provenanceLabel == "REPLAY · DEMOSTRACIÓN")
        for prompt in BundledPrompt.allCases where prompt != .repairBeat {
            #expect(prompt.provenanceLabel == "LOCAL · AUDIO INCLUIDO")
        }
    }

    @Test("All bundled prompts resolve, decode, and match the frozen manifest")
    func allAssetsResolveAndDecode() throws {
        for prompt in BundledPrompt.allCases {
            let frames = try AudioAssetCatalog.validate(prompt)
            #expect(frames > 0)
        }
    }

    @Test("Bundled speech is normalized for a phone speaker without clipping")
    func bundledSpeechLoudness() throws {
        for prompt in BundledPrompt.allCases {
            let file = try AVAudioFile(forReading: AudioAssetCatalog.url(for: prompt))
            let buffer = try #require(
                AVAudioPCMBuffer(
                    pcmFormat: file.processingFormat,
                    frameCapacity: AVAudioFrameCount(file.length)
                )
            )
            try file.read(into: buffer)
            let samples = try #require(buffer.floatChannelData?[0])
            let frameCount = Int(buffer.frameLength)
            let power = (0..<frameCount).reduce(Float.zero) { partial, index in
                partial + samples[index] * samples[index]
            }
            let rms = sqrt(power / Float(max(1, frameCount)))
            let peak = (0..<frameCount).reduce(Float.zero) { partial, index in
                max(partial, abs(samples[index]))
            }
            let rmsDB = 20 * log10(max(rms, .leastNonzeroMagnitude))
            let peakDB = 20 * log10(max(peak, .leastNonzeroMagnitude))

            #expect(rmsDB > -22, "\(prompt.rawValue) is too quiet at \(rmsDB) dBFS")
            #expect(peakDB > -6, "\(prompt.rawValue) has insufficient headroom use")
            #expect(peakDB < -0.5, "\(prompt.rawValue) risks clipping at \(peakDB) dBFS")
        }
    }

    @Test("Capture receipts cannot retain raw audio or imply completion")
    func receiptIsAggregateOnly() {
        let request = CaptureRequest(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            obligationID: "restaurant.party-size.one",
            scaffold: .none,
            attemptNumber: 1
        )
        let receipt = CaptureReceipt(
            id: request.id,
            request: request,
            startedAt: Date(timeIntervalSince1970: 10),
            endedAt: Date(timeIntervalSince1970: 12),
            capturedDuration: 2,
            estimatedVoiceOnset: 0.4,
            speechPresenceDetected: true,
            sampleRate: 48_000,
            disposition: .completed,
            rawAudioRetained: false
        )

        #expect(receipt.speechPresenceDetected)
        #expect(receipt.estimatedVoiceOnset == 0.4)
        #expect(!receipt.rawAudioRetained)
        // There is deliberately no completion/transcript/score field.
    }

    @Test("Capture worker reduces PCM to bounded timing and presence metadata")
    func captureWorkerAggregatesWithoutRetention() {
        let worker = LearnerCaptureWorker()
        worker.enqueue(samples: [Float](repeating: 0, count: 480), sampleRate: 48_000)
        worker.enqueue(samples: [Float](repeating: 0.1, count: 480), sampleRate: 48_000)
        worker.enqueue(samples: [Float](repeating: 0.1, count: 480), sampleRate: 48_000)

        let snapshot = worker.snapshot()
        #expect(abs(snapshot.duration - 0.03) < 0.0001)
        #expect(snapshot.speechPresence)
        #expect(snapshot.estimatedVoiceOnset == 0.01)
        #expect(snapshot.sampleRate == 48_000)
    }

    @Test("Capture tap callback is safe on AVFAudio's non-main queue")
    func captureTapIsNonisolated() async {
        let worker = LearnerCaptureWorker()
        let tap = AudioGraphController.makeCaptureTap(worker: worker)

        await withCheckedContinuation { continuation in
            DispatchQueue(label: "com.ia.ma.tests.audio-tap").async {
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
                tap(buffer, AVAudioTime(sampleTime: 0, atRate: 48_000))
                tap(buffer, AVAudioTime(sampleTime: 960, atRate: 48_000))
                continuation.resume()
            }
        }

        let snapshot = worker.snapshot()
        #expect(abs(snapshot.duration - 0.04) < 0.0001)
        #expect(snapshot.speechPresence)
        #expect(snapshot.estimatedVoiceOnset == 0)
    }

    @Test("Playback delegate callbacks are safe on AVFAudio's non-main queue")
    @MainActor
    func playbackDelegateIsNonisolated() async throws {
        let controller = AudioGraphController(permission: DeniedRecordPermission())
        let audioData = try Data(contentsOf: AudioAssetCatalog.url(for: .hitoriDesu))

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue(label: "com.ia.ma.tests.playback-delegate").async {
                let player = try! AVAudioPlayer(data: audioData)
                controller.audioPlayerDidFinishPlaying(player, successfully: true)
                controller.audioPlayerDecodeErrorDidOccur(player, error: nil)
                continuation.resume()
            }
        }
    }

    @Test("Controller permission denial is recoverable before hardware starts")
    @MainActor
    func controllerPermissionDenial() async {
        let controller = AudioGraphController(permission: DeniedRecordPermission())
        let request = CaptureRequest(
            obligationID: KaiwaLoopState.obligationID,
            scaffold: .full,
            attemptNumber: 1
        )

        await #expect(throws: ProductAudioFailure.microphoneDenied) {
            try await controller.startCapture(request)
        }
        #expect(controller.state == .failed(.microphoneDenied))
        let receipt = try? await controller.finishCapture(.completed)
        #expect(receipt == nil)
        await controller.stop(.restart)
        #expect(controller.state == .failed(.microphoneDenied))
    }

    @Test("Delayed permission cannot resurrect capture after exit or admit a second start")
    @MainActor
    func delayedPermissionIsRevoked() async {
        let permission = DelayedRecordPermission()
        let controller = AudioGraphController(permission: permission)
        let first = CaptureRequest(
            obligationID: KaiwaLoopState.obligationID,
            scaffold: .full,
            attemptNumber: 1
        )
        let second = CaptureRequest(
            obligationID: KaiwaLoopState.obligationID,
            scaffold: .full,
            attemptNumber: 2
        )
        let startTask = Task { try await controller.startCapture(first) }
        #expect(await eventually { controller.state == .requestingPermission })

        await #expect(throws: ProductAudioFailure.captureInProgress) {
            try await controller.startCapture(second)
        }
        await controller.stop(.exit)
        #expect(controller.state == .idle)
        permission.resolve(true)
        await #expect(throws: ProductAudioFailure.interrupted) {
            try await startTask.value
        }
        #expect(controller.state == .idle)
    }

    @Test("Only port-loss or external device route changes tear down the graph")
    @MainActor
    func routeChangePolicy() {
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.categoryChange))
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.override))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.newDeviceAvailable))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.oldDeviceUnavailable))
        #expect(!AudioGraphController.shouldTearDownForRouteChange(.routeConfigurationChange))
        #expect(AudioGraphController.shouldTearDownForRouteChange(.unknown))
    }

    @MainActor
    private func eventually(
        _ condition: @escaping @MainActor () -> Bool
    ) async -> Bool {
        for _ in 0..<200 {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }
}

private struct DeniedRecordPermission: RecordPermissionProviding {
    func requestPermission() async -> Bool { false }
}

@MainActor
private final class DelayedRecordPermission: RecordPermissionProviding, @unchecked Sendable {
    private var continuation: CheckedContinuation<Bool, Never>?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func resolve(_ granted: Bool) {
        let continuation = continuation
        self.continuation = nil
        continuation?.resume(returning: granted)
    }
}
