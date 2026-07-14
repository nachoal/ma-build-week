import Foundation
import Testing
@testable import MA

@Suite("Offline Kaiwa Loop product flow")
@MainActor
struct KaiwaLoopFeatureTests {
    @Test("Real service events drive the first minute, repair, resume, and proof")
    func completeHeroFlow() async throws {
        let audio = FakeProductAudioController()
        let feature = KaiwaLoopFeature(audio: audio)

        feature.send(.playModel)
        #expect(await eventually { audio.playedPrompts == [.hitoriDesu] })

        feature.send(.beginCoachedPractice)
        for scaffold in [ScaffoldLevel.full, .rhythmOnly, .none] {
            #expect(feature.state.scaffold == scaffold)
            feature.send(.startAttempt)
            #expect(await eventually { feature.state.isCapturing })
            feature.send(.finishAttempt)
            #expect(await eventually { feature.state.awaitingSelfAssessment })
            #expect(feature.state.pendingReceipt?.rawAudioRetained == false)
            feature.send(.assessSuccess)
        }

        #expect(feature.state.phase == .firstSuccess)
        #expect(feature.state.successfulScaffolds == [.full, .rhythmOnly, .none])
        #expect(feature.state.attempts.count == 3)
        #expect(feature.state.completedPreRepairAttempt != nil)

        feature.send(.acknowledgeFirstSuccess)
        feature.send(.pauseForRepair)
        #expect(feature.state.phase == .controls)
        feature.send(.startNatural)
        #expect(await eventually { audio.playedPrompts.contains(.tutorTurn) })
        #expect(feature.state.phase == .natural)
        #expect(await eventually { feature.state.canPauseNaturalAudio })

        feature.send(.pauseForRepair)
        #expect(await eventually { feature.state.phase == .repair })
        #expect(audio.stopReasons.contains(.explicitRepair))
        #expect(!feature.state.repairSegment.isExactRenderedWindow)
        #expect(feature.state.repairSegment.sourceBadge == "REPLAY · DEMOSTRACIÓN")

        feature.send(.resumeScene)
        #expect(feature.state.phase == .repair)

        feature.send(.playRepairSegment)
        #expect(await eventually { audio.playedPrompts.contains(.repairBeat) })
        #expect(await eventually { feature.state.repairSegmentPlayed })
        feature.send(.resumeScene)
        #expect(await eventually { feature.state.phase == .retry })
        #expect(audio.playedPrompts.contains(.tutorResume))

        feature.send(.startAttempt)
        #expect(await eventually { feature.state.isCapturing })
        feature.send(.finishAttempt)
        #expect(await eventually { feature.state.awaitingSelfAssessment })
        feature.send(.assessSuccess)

        #expect(feature.state.phase == .proof)
        let first = try #require(feature.state.completedPreRepairAttempt)
        let second = try #require(feature.state.completedPostRepairAttempt)
        #expect(first.obligationID == second.obligationID)
        #expect(first.scaffold == .none)
        #expect(second.scaffold == .none)
        #expect(first.selfReportedCompleted)
        #expect(second.selfReportedCompleted)
        #expect(first.repairCount == 0)
        #expect(second.repairCount == 1)
        #expect(!first.rawAudioRetained)
        #expect(!second.rawAudioRetained)
        #expect(feature.state.learningReport?.isValidForPlannerTransport == true)
        #expect(feature.state.nextLearningAction?.source == .deterministicPolicy)
        #expect(feature.state.nextLearningAction?.action == .advance)
    }

    @Test("Microphone denial stays recoverable and cannot fabricate an attempt")
    func microphoneDenied() async {
        let audio = FakeProductAudioController()
        audio.startCaptureFailure = .microphoneDenied
        let feature = KaiwaLoopFeature(audio: audio)

        feature.send(.beginCoachedPractice)
        feature.send(.startAttempt)

        #expect(await eventually { feature.state.lastError == .microphoneDenied })
        #expect(feature.state.phase == .coached)
        #expect(feature.state.attempts.isEmpty)
        #expect(feature.state.pendingReceipt == nil)
        #expect(!feature.state.awaitingSelfAssessment)
    }

    @Test("A local time-limit receipt still requires explicit self-assessment")
    func timeLimitRequiresSelfAssessment() async {
        let audio = FakeProductAudioController()
        let feature = KaiwaLoopFeature(audio: audio)
        feature.send(.beginCoachedPractice)
        feature.send(.startAttempt)
        #expect(await eventually { feature.state.isCapturing })

        audio.finishAutomatically(disposition: .timeLimit)

        #expect(await eventually { feature.state.awaitingSelfAssessment })
        #expect(feature.state.successfulScaffolds.isEmpty)
        #expect(feature.state.attempts.isEmpty)
        feature.send(.assessSuccess)
        #expect(feature.state.successfulScaffolds == [.full])
    }

    @Test("A planner response arriving after restart cannot mutate the new scene")
    func stalePlannerResponseIsIgnored() async throws {
        let audio = FakeProductAudioController()
        let planner = SuspendedLearningPlanner()
        let feature = KaiwaLoopFeature(audio: audio, learningPlanner: planner)

        await driveToProof(feature: feature, audio: audio)

        #expect(feature.state.phase == .proof)
        #expect(feature.state.nextLearningAction?.source == .deterministicPolicy)
        #expect(feature.state.plannerIsRefreshing)

        var requestedReport: LearningReport?
        for _ in 0..<200 where requestedReport == nil {
            requestedReport = await planner.currentReport()
            await Task.yield()
        }
        let report = try #require(requestedReport)
        let modelAction = DeterministicPedagogyPolicy().make(
            report: report,
            action: .advance,
            reason: .completedAfterRepair,
            source: .model,
            model: "gpt-5.6-sol"
        )

        feature.send(.restart)
        await planner.resolve(modelAction)
        for _ in 0..<20 { await Task.yield() }

        #expect(feature.state.phase == .setup)
        #expect(feature.state.learningReport == nil)
        #expect(feature.state.nextLearningAction == nil)
        #expect(!feature.state.plannerIsRefreshing)
    }

    private func driveToProof(
        feature: KaiwaLoopFeature,
        audio: FakeProductAudioController
    ) async {
        feature.send(.beginCoachedPractice)
        for _ in 0..<3 {
            feature.send(.startAttempt)
            #expect(await eventually { feature.state.isCapturing })
            feature.send(.finishAttempt)
            #expect(await eventually { feature.state.awaitingSelfAssessment })
            feature.send(.assessSuccess)
        }
        feature.send(.acknowledgeFirstSuccess)
        feature.send(.startNatural)
        #expect(await eventually { feature.state.canPauseNaturalAudio })
        feature.send(.pauseForRepair)
        #expect(await eventually { feature.state.phase == .repair })
        feature.send(.playRepairSegment)
        #expect(await eventually { feature.state.repairSegmentPlayed })
        feature.send(.resumeScene)
        #expect(await eventually { feature.state.phase == .retry })
        feature.send(.startAttempt)
        #expect(await eventually { feature.state.isCapturing })
        feature.send(.finishAttempt)
        #expect(await eventually { feature.state.awaitingSelfAssessment })
        feature.send(.assessSuccess)
        #expect(feature.state.phase == .proof)
        #expect(audio.playedPrompts.contains(.tutorResume))
    }

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

private actor SuspendedLearningPlanner: LearningPlanning {
    private var report: LearningReport?
    private var continuation: CheckedContinuation<NextLearningAction, Never>?

    func nextAction(for report: LearningReport) async -> NextLearningAction {
        self.report = report
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func currentReport() -> LearningReport? { report }

    func resolve(_ action: NextLearningAction) {
        let pending = continuation
        continuation = nil
        pending?.resume(returning: action)
    }
}

@MainActor
private final class FakeProductAudioController: ProductAudioControlling {
    private let continuation: AsyncStream<ProductAudioEvent>.Continuation
    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle
    private(set) var playedPrompts: [BundledPrompt] = []
    private(set) var stopReasons: [AudioStopReason] = []
    var startCaptureFailure: ProductAudioFailure?
    private var activeRequest: CaptureRequest?
    private var heldPlaybackContinuation: CheckedContinuation<Void, Error>?

    init() {
        let pair = AsyncStream.makeStream(
            of: ProductAudioEvent.self,
            bufferingPolicy: .bufferingNewest(32)
        )
        events = pair.stream
        continuation = pair.continuation
    }

    func play(_ prompt: BundledPrompt) async throws {
        state = .playing(prompt)
        continuation.yield(.stateChanged(state))
        playedPrompts.append(prompt)
        if prompt == .tutorTurn {
            try await withCheckedThrowingContinuation { continuation in
                heldPlaybackContinuation = continuation
            }
            return
        }
        state = .idle
        continuation.yield(.stateChanged(state))
        continuation.yield(.playbackFinished(prompt))
    }

    func startCapture(_ request: CaptureRequest) async throws {
        if let startCaptureFailure {
            state = .failed(startCaptureFailure)
            continuation.yield(.stateChanged(state))
            throw startCaptureFailure
        }
        activeRequest = request
        state = .capturing(request)
        continuation.yield(.stateChanged(state))
    }

    func finishCapture(
        _ disposition: CaptureDisposition
    ) async throws -> CaptureReceipt? {
        guard let request = activeRequest else { return nil }
        activeRequest = nil
        let receipt = makeReceipt(request: request, disposition: disposition)
        state = .idle
        continuation.yield(.stateChanged(state))
        continuation.yield(.captureFinished(receipt))
        return receipt
    }

    func stop(_ reason: AudioStopReason) async {
        stopReasons.append(reason)
        if let heldPlaybackContinuation {
            self.heldPlaybackContinuation = nil
            heldPlaybackContinuation.resume(throwing: ProductAudioFailure.interrupted)
        }
        activeRequest = nil
        state = .idle
        continuation.yield(.stateChanged(state))
    }

    func handleLifecycle(_ event: AudioLifecycleEvent) async {
        await stop(.lifecycle)
        continuation.yield(.lifecycleStopped(event))
    }

    func finishAutomatically(disposition: CaptureDisposition) {
        guard let request = activeRequest else { return }
        activeRequest = nil
        let receipt = makeReceipt(request: request, disposition: disposition)
        state = .idle
        continuation.yield(.stateChanged(state))
        continuation.yield(.captureFinished(receipt))
    }

    private func makeReceipt(
        request: CaptureRequest,
        disposition: CaptureDisposition
    ) -> CaptureReceipt {
        let onset = max(0.2, 1.4 - Double(request.attemptNumber) * 0.2)
        return CaptureReceipt(
            id: request.id,
            request: request,
            startedAt: Date(timeIntervalSince1970: Double(request.attemptNumber)),
            endedAt: Date(timeIntervalSince1970: Double(request.attemptNumber) + 2),
            capturedDuration: 2,
            estimatedVoiceOnset: onset,
            speechPresenceDetected: true,
            sampleRate: 48_000,
            disposition: disposition,
            rawAudioRetained: false
        )
    }
}
