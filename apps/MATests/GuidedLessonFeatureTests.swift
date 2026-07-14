import Foundation
import Testing
@testable import MA

@Suite("Zero-beginner guided lesson")
@MainActor
struct GuidedLessonFeatureTests {
    @Test("The model is an explicit gate and playback never starts recording")
    func explicitModelGate() async {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider()
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        feature.send(.beginAttempt)
        #expect(audio.captureRequests.isEmpty)
        #expect(feature.state.phase == .orientation)

        feature.send(.showPhrase)
        #expect(feature.state.phase == .model(.ready))
        feature.send(.beginAttempt)
        #expect(audio.captureRequests.isEmpty)

        feature.send(.playModel)
        feature.send(.playModel)
        #expect(await eventually { feature.state.phase == .model(.completed) })
        #expect(audio.playedPrompts == [.hitoriDesu])
        #expect(audio.captureRequests.isEmpty)

        feature.send(.beginAttempt)
        #expect(await eventually { feature.state.isRecording })
        #expect(audio.captureRequests.count == 1)
    }

    @Test("Every learner turn is reviewed before the lesson can progress")
    func reviewedTeachingLoop() async throws {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider(matches: [.close, .matched])
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.taughtPhrase, .feedback) = feature.state.phase { true }
            else { false }
        })
        #expect(feature.state.reviewedAttempts.count == 1)
        #expect(feature.state.reviewedAttempts.first?.targetMatch == .close)
        guard case .attempt(.taughtPhrase, .feedback(let first)) = feature.state.phase else {
            Issue.record("Expected visible first-attempt feedback")
            return
        }
        #expect(first.approximateTranscript == "一人です")
        #expect(first.review.positiveES == "La transcripción de MA captó parte de la frase.")
        #expect(first.review.retryFocusES == "Di hi-to-ri de-su una vez, a un ritmo parejo.")
        #expect(await eventually { audio.realtimePlaybackCount == 1 })
        #expect(await eventually { feature.state.spokenFeedbackCompleted })
        #expect(!feature.state.spokenFeedbackPreparing)
        #expect(!feature.state.spokenFeedbackUnavailable)

        feature.send(.continueWithFeedback)
        #expect(await eventually { feature.state.phase == .situationBrief })
        #expect(feature.state.waiterSpanish == "¿Cuántas personas?")
        #expect(feature.state.targetJapanese == "一人です")

        feature.send(.playWaiterTurn)
        #expect(await eventually { feature.state.phase == .tutorTurn(.responseReady) })
        #expect(await realtime.waiterRequestCount() == 1)
        #expect(!feature.state.isRecording)

        feature.send(.beginAttempt)
        #expect(await eventually { feature.state.isRecording })
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.restaurantTurn, .feedback) = feature.state.phase { true }
            else { false }
        })
        #expect(feature.state.reviewedAttempts.count == 2)
        #expect(feature.state.reviewedAttempts.last?.targetMatch == .matched)

        feature.send(.continueWithFeedback)
        #expect(await eventually { feature.state.phase == .complete })
        #expect(await realtime.reviewRequestCount() == 2)
        #expect(feature.state.learningReport?.attemptSummary.restaurantTurn.scaffold == .full)
        #expect(feature.state.plannerStep?.action.action == .reduceScaffold)
    }

    @Test("Retry preserves the obligation and cannot duplicate a commit")
    func retryIntegrityAndDoubleTapProtection() async throws {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider(matches: [.unclear, .matched])
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        await reachFirstRecording(feature: feature)
        let firstRequest = try #require(audio.captureRequests.first)
        feature.send(.finishAttempt)
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.taughtPhrase, .feedback) = feature.state.phase { true }
            else { false }
        })
        #expect(await realtime.reviewRequestCount() == 1)
        #expect(feature.state.reviewedAttempts.first?.targetMatch == .unclear)

        feature.send(.retryAttempt)
        #expect(await eventually {
            feature.state.phase == .attempt(context: .taughtPhrase, step: .ready)
        })
        feature.send(.beginAttempt)
        #expect(await eventually { audio.captureRequests.count == 2 })
        let retryRequest = try #require(audio.captureRequests.last)
        #expect(retryRequest.id != firstRequest.id)
        #expect(retryRequest.obligationID == firstRequest.obligationID)
        #expect(retryRequest.attemptNumber == 2)
        #expect(retryRequest.scaffold == .full)
    }

    @Test("Review failure is visible, recoverable, and never fabricates feedback")
    func reviewFailureIsRecoverable() async {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider(
            outcomes: [.failure(.connectionFailed), .success(.matched)]
        )
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually {
            feature.state.phase == .attempt(
                context: .taughtPhrase,
                step: .recoverableError(.realtime(.connectionFailed))
            )
        })
        #expect(feature.state.reviewedAttempts.isEmpty)

        feature.send(.retryAttempt)
        #expect(await eventually {
            feature.state.phase == .attempt(context: .taughtPhrase, step: .ready)
        })
        feature.send(.beginAttempt)
        #expect(await eventually { feature.state.isRecording })
        feature.send(.finishAttempt)
        #expect(await eventually { feature.state.reviewedAttempts.count == 1 })
        #expect(feature.state.reviewedAttempts.first?.targetMatch == .matched)
    }

    @Test("Restart invalidates a late provider review")
    func staleReviewAfterRestartIsIgnored() async {
        let audio = FakeGuidedAudioController()
        let realtime = SuspendedGuidedRealtimeProvider()
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually { await realtime.hasPendingReview() })
        feature.send(.restart)
        #expect(await eventually { feature.state.phase == .orientation })

        await realtime.resolvePendingReview()
        for _ in 0..<20 { await Task.yield() }
        #expect(feature.state.phase == .orientation)
        #expect(feature.state.reviewedAttempts.isEmpty)
    }

    @Test("GPT next-practice planning is explicit and double-tap safe")
    func explicitPlannerOptIn() async {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider(matches: [.matched, .matched])
        let planner = SuspendedGuidedLearningPlanner()
        let feature = GuidedLessonFeature(
            audio: audio,
            realtime: realtime,
            planner: planner
        )

        await completeLesson(feature: feature)
        guard case .local(let local)? = feature.state.plannerStep else {
            Issue.record("Expected an immediate local plan")
            return
        }
        #expect(local.action == .reduceScaffold)
        #expect(await planner.requestCount() == 0)

        feature.send(.requestNextPlan)
        feature.send(.requestNextPlan)
        #expect(await eventually { await planner.hasPendingRequest() })
        #expect(await planner.requestCount() == 1)
        guard case .requesting? = feature.state.plannerStep else {
            Issue.record("Expected visible planner loading")
            return
        }

        await planner.resolve()
        #expect(await eventually {
            if case .model = feature.state.plannerStep { true } else { false }
        })
        #expect(feature.state.plannerStep?.action.source == .model)
        #expect(audio.captureRequests.count == 2)
    }

    @Test("Restart invalidates a late guided planner result")
    func stalePlannerAfterRestart() async {
        let planner = SuspendedGuidedLearningPlanner()
        let feature = GuidedLessonFeature(
            audio: FakeGuidedAudioController(),
            realtime: FakeGuidedRealtimeProvider(matches: [.matched, .matched]),
            planner: planner
        )
        await completeLesson(feature: feature)
        feature.send(.requestNextPlan)
        #expect(await eventually { await planner.hasPendingRequest() })

        feature.send(.restart)
        #expect(await eventually { feature.state.phase == .orientation })
        await planner.resolve()
        for _ in 0..<20 { await Task.yield() }
        #expect(feature.state.phase == .orientation)
        #expect(feature.state.plannerStep == nil)
    }

    @Test("Restart teardown finishes before one-tap model playback is exposed")
    func restartTeardownCannotStopNewPlayback() async {
        let audio = FakeGuidedAudioController()
        audio.suspendNextStop()
        let feature = GuidedLessonFeature(
            audio: audio,
            realtime: FakeGuidedRealtimeProvider()
        )

        let reset = Task { await feature.resetForNewLesson() }
        #expect(await eventually { audio.hasPendingStop })

        feature.send(.showPhrase)
        feature.send(.playModel)
        #expect(audio.playedPrompts.isEmpty)

        audio.resolvePendingStop()
        await reset.value
        feature.send(.showPhrase)
        feature.send(.playModel)

        #expect(await eventually { feature.state.phase == .model(.completed) })
        #expect(audio.playedPrompts == [.hitoriDesu])
    }

    @Test("A canceled permission request cannot overwrite retry recovery")
    func stalePermissionFailureIsIgnored() async {
        let audio = FakeGuidedAudioController()
        let feature = GuidedLessonFeature(
            audio: audio,
            realtime: FakeGuidedRealtimeProvider()
        )

        feature.send(.showPhrase)
        feature.send(.playModel)
        #expect(await eventually { feature.state.phase == .model(.completed) })
        audio.suspendNextCaptureStart()
        feature.send(.beginAttempt)
        #expect(await eventually { audio.hasPendingCaptureStart })

        audio.emitLifecycleStop()
        #expect(await eventually {
            feature.state.phase == .attempt(
                context: .taughtPhrase,
                step: .recoverableError(.interrupted)
            )
        })
        feature.send(.retryAttempt)
        #expect(await eventually {
            feature.state.phase == .attempt(context: .taughtPhrase, step: .ready)
        })

        audio.failPendingCaptureStart()
        for _ in 0..<20 { await Task.yield() }
        #expect(feature.state.phase == .attempt(context: .taughtPhrase, step: .ready))
    }

    @Test("Visible text feedback does not wait for optional spoken feedback")
    func spokenFeedbackCannotHoldReviewOpen() async {
        let realtime = FakeGuidedRealtimeProvider(
            matches: [.close],
            suspendsSpokenFeedback: true
        )
        let feature = GuidedLessonFeature(
            audio: FakeGuidedAudioController(),
            realtime: realtime
        )

        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.taughtPhrase, .feedback) = feature.state.phase { true }
            else { false }
        })
        #expect(await eventually { await realtime.hasPendingSpokenFeedback() })
        #expect(feature.state.spokenFeedbackPreparing)
        #expect(!feature.state.spokenFeedbackCompleted)

        feature.send(.continueWithFeedback)
        #expect(await eventually { feature.state.phase == .situationBrief })
    }

    @Test("A rapid second Continue cannot bypass spoken-feedback cleanup")
    func doubleContinueWaitsForOneCleanupTransition() async {
        let audio = FakeGuidedAudioController()
        let realtime = FakeGuidedRealtimeProvider(
            matches: [.matched],
            suspendsSpokenFeedback: true
        )
        let feature = GuidedLessonFeature(audio: audio, realtime: realtime)

        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.taughtPhrase, .feedback) = feature.state.phase { true }
            else { false }
        })
        #expect(await eventually { await realtime.hasPendingSpokenFeedback() })

        audio.suspendNextStop()
        feature.send(.continueWithFeedback)
        #expect(await eventually { audio.hasPendingStop })
        feature.send(.continueWithFeedback)
        for _ in 0..<20 { await Task.yield() }

        #expect(feature.state.feedbackTransition == .continuing)
        #expect(audio.stopReasons == [.replacement])
        if case .attempt(.taughtPhrase, .feedback) = feature.state.phase {
            // The single cleanup transition still owns the visible state.
        } else {
            Issue.record("A second tap bypassed the pending cleanup")
        }

        audio.resolvePendingStop()
        #expect(await eventually { feature.state.phase == .situationBrief })
        #expect(audio.stopReasons == [.replacement])
    }

    private func reachFirstRecording(feature: GuidedLessonFeature) async {
        feature.send(.showPhrase)
        feature.send(.playModel)
        #expect(await eventually { feature.state.phase == .model(.completed) })
        feature.send(.beginAttempt)
        #expect(await eventually { feature.state.isRecording })
    }

    private func completeLesson(feature: GuidedLessonFeature) async {
        await reachFirstRecording(feature: feature)
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.taughtPhrase, .feedback) = feature.state.phase { true }
            else { false }
        })
        feature.send(.continueWithFeedback)
        #expect(await eventually { feature.state.phase == .situationBrief })
        feature.send(.playWaiterTurn)
        #expect(await eventually { feature.state.phase == .tutorTurn(.responseReady) })
        feature.send(.beginAttempt)
        #expect(await eventually { feature.state.isRecording })
        feature.send(.finishAttempt)
        #expect(await eventually {
            if case .attempt(.restaurantTurn, .feedback) = feature.state.phase { true }
            else { false }
        })
        feature.send(.continueWithFeedback)
        #expect(await eventually { feature.state.phase == .complete })
    }

    private func eventually(
        _ condition: @escaping @MainActor () async -> Bool
    ) async -> Bool {
        for _ in 0..<400 {
            if await condition() { return true }
            await Task.yield()
        }
        return await condition()
    }
}

private enum FakeReviewOutcome: Sendable {
    case success(GuidedTargetMatch)
    case failure(GuidedRealtimeError)
}

private actor FakeGuidedRealtimeProvider: GuidedRealtimeProviding {
    private var outcomes: [FakeReviewOutcome]
    private var reviews: [GuidedAttemptRequest] = []
    private var waiterRequests = 0
    private var connected = false
    private let suspendsSpokenFeedback: Bool
    private var pendingSpokenFeedback:
        CheckedContinuation<GuidedRealtimeSpokenFeedback, Error>?

    init(
        matches: [GuidedTargetMatch] = [.matched],
        suspendsSpokenFeedback: Bool = false
    ) {
        outcomes = matches.map(FakeReviewOutcome.success)
        self.suspendsSpokenFeedback = suspendsSpokenFeedback
    }

    init(outcomes: [FakeReviewOutcome]) {
        self.outcomes = outcomes
        suspendsSpokenFeedback = false
    }

    func connect() async throws {
        connected = true
    }

    func reviewAttempt(
        _ request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws -> GuidedRealtimeReviewResult {
        reviews.append(request)
        let outcome = outcomes.isEmpty ? .success(.matched) : outcomes.removeFirst()
        switch outcome {
        case .failure(let error):
            throw error
        case .success(let match):
            let review = makeReview(request: request, match: match)
            return GuidedRealtimeReviewResult(
                request: request,
                review: review,
                approximateTranscript: match == .unclear ? nil : "一人です"
            )
        }
    }

    func requestRestaurantTurn() async throws -> GuidedRealtimeTutorTurn {
        waiterRequests += 1
        return GuidedRealtimeTutorTurn(
            transcript: "何名様ですか？",
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    func requestSpokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) async throws -> GuidedRealtimeSpokenFeedback {
        if suspendsSpokenFeedback {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    pendingSpokenFeedback = continuation
                }
            } onCancel: {
                Task { await self.cancelPendingSpokenFeedback() }
            }
        }
        return spokenFeedback(for: result)
    }

    func disconnect() async {
        connected = false
    }

    func reviewRequestCount() -> Int { reviews.count }
    func waiterRequestCount() -> Int { waiterRequests }
    func hasPendingSpokenFeedback() -> Bool { pendingSpokenFeedback != nil }

    private func cancelPendingSpokenFeedback() {
        guard let pendingSpokenFeedback else { return }
        self.pendingSpokenFeedback = nil
        pendingSpokenFeedback.resume(throwing: CancellationError())
    }

    private func spokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) -> GuidedRealtimeSpokenFeedback {
        GuidedRealtimeSpokenFeedback(
            transcript: result.request.feedbackLanguage.text(
                english: "Good attempt. Try once more.",
                spanish: "Buen intento. Prueba una vez más."
            ),
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    private func makeReview(
        request: GuidedAttemptRequest,
        match: GuidedTargetMatch
    ) -> GuidedAttemptReview {
        if match == .unclear {
            return .unclear(attemptID: request.id)
        }
        return GuidedAttemptReview(
            attemptID: request.id,
            targetPhraseID: request.targetPhraseID,
            targetMatch: match,
            heardJapanese: "一人です",
            evidenceCode: match == .matched
                ? .fullTargetInTranscript
                : .partialTargetInTranscript,
            retryFocusCode: match == .matched
                ? .useWithWaiter
                : .completeTarget
        )
    }
}

private actor SuspendedGuidedRealtimeProvider: GuidedRealtimeProviding {
    private var pending: (
        request: GuidedAttemptRequest,
        continuation: CheckedContinuation<GuidedRealtimeReviewResult, Error>
    )?

    func connect() async throws {}

    func reviewAttempt(
        _ request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws -> GuidedRealtimeReviewResult {
        try await withCheckedThrowingContinuation { continuation in
            pending = (request, continuation)
        }
    }

    func requestRestaurantTurn() async throws -> GuidedRealtimeTutorTurn {
        GuidedRealtimeTutorTurn(
            transcript: "何名様ですか？",
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    func requestSpokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) async throws -> GuidedRealtimeSpokenFeedback {
        GuidedRealtimeSpokenFeedback(
            transcript: nil,
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    func disconnect() async {}

    func hasPendingReview() -> Bool { pending != nil }

    func resolvePendingReview() {
        guard let pending else { return }
        self.pending = nil
        let review = GuidedAttemptReview(
            attemptID: pending.request.id,
            targetPhraseID: pending.request.targetPhraseID,
            targetMatch: .matched,
            heardJapanese: "一人です",
            evidenceCode: .fullTargetInTranscript,
            retryFocusCode: .useWithWaiter
        )
        pending.continuation.resume(returning: GuidedRealtimeReviewResult(
            request: pending.request,
            review: review,
            approximateTranscript: "一人です"
        ))
    }
}

private actor SuspendedGuidedLearningPlanner: GuidedLearningPlanning {
    private var requests = 0
    private var pending: (
        report: GuidedLearningReport,
        continuation: CheckedContinuation<GuidedNextPracticeAction, Error>
    )?

    func improvedAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction {
        requests += 1
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pending = (report, continuation)
            }
        } onCancel: {
            Task { await self.cancelPending() }
        }
    }

    func hasPendingRequest() -> Bool { pending != nil }
    func requestCount() -> Int { requests }

    func resolve() {
        guard let pending else { return }
        self.pending = nil
        pending.continuation.resume(returning: GuidedPedagogyPolicy().make(
            report: pending.report,
            action: .reduceScaffold,
            reason: .matchedWithSupport,
            source: .model,
            model: GuidedPedagogyPolicy.expectedRemoteModel
        ))
    }

    private func cancelPending() {
        guard let pending else { return }
        self.pending = nil
        pending.continuation.resume(throwing: CancellationError())
    }
}

@MainActor
private final class FakeGuidedAudioController: GuidedLessonAudioControlling {
    private let continuation: AsyncStream<ProductAudioEvent>.Continuation
    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle
    private(set) var playedPrompts: [BundledPrompt] = []
    private(set) var captureRequests: [CaptureRequest] = []
    private(set) var realtimePlaybackCount = 0
    private(set) var stopReasons: [AudioStopReason] = []
    private var activeRequest: CaptureRequest?
    private var shouldSuspendStop = false
    private var pendingStop: CheckedContinuation<Void, Never>?
    private var shouldSuspendCaptureStart = false
    private var pendingCaptureStart: CheckedContinuation<Void, Error>?

    var hasPendingStop: Bool { pendingStop != nil }
    var hasPendingCaptureStart: Bool { pendingCaptureStart != nil }

    init() {
        let pair = AsyncStream.makeStream(
            of: ProductAudioEvent.self,
            bufferingPolicy: .bufferingNewest(32)
        )
        events = pair.stream
        continuation = pair.continuation
    }

    func play(_ prompt: BundledPrompt) async throws {
        playedPrompts.append(prompt)
        state = .playing(prompt)
        continuation.yield(.stateChanged(state))
        await Task.yield()
        state = .idle
        continuation.yield(.stateChanged(state))
        continuation.yield(.playbackFinished(prompt))
    }

    func startRealtimeCapture(_ request: CaptureRequest) async throws {
        guard activeRequest == nil else { throw ProductAudioFailure.captureInProgress }
        captureRequests.append(request)
        if shouldSuspendCaptureStart {
            shouldSuspendCaptureStart = false
            try await withCheckedThrowingContinuation { continuation in
                pendingCaptureStart = continuation
            }
        }
        activeRequest = request
        state = .capturing(request)
        continuation.yield(.stateChanged(state))
    }

    func finishRealtimeCapture(
        _ disposition: CaptureDisposition
    ) async throws -> RealtimeCapturePayload? {
        guard let request = activeRequest else { return nil }
        activeRequest = nil
        let receipt = CaptureReceipt(
            id: request.id,
            request: request,
            startedAt: Date(timeIntervalSince1970: 10),
            endedAt: Date(timeIntervalSince1970: 12),
            capturedDuration: 2,
            estimatedVoiceOnset: 0.2,
            speechPresenceDetected: true,
            sampleRate: 48_000,
            disposition: disposition,
            rawAudioRetained: false
        )
        state = .idle
        continuation.yield(.stateChanged(state))
        continuation.yield(.captureFinished(receipt))
        return RealtimeCapturePayload(
            receipt: receipt,
            pcm16Data: Data(repeating: 1, count: 19_200)
        )
    }

    func playRealtimePCM16(_ data: Data) async throws {
        #expect(!data.isEmpty)
        realtimePlaybackCount += 1
        state = .playingRealtime
        continuation.yield(.stateChanged(state))
        await Task.yield()
        state = .idle
        continuation.yield(.stateChanged(state))
    }

    func stop(_ reason: AudioStopReason) async {
        stopReasons.append(reason)
        if shouldSuspendStop {
            shouldSuspendStop = false
            await withCheckedContinuation { continuation in
                pendingStop = continuation
            }
        }
        activeRequest = nil
        state = .idle
        continuation.yield(.stateChanged(state))
    }

    func suspendNextStop() {
        shouldSuspendStop = true
    }

    func resolvePendingStop() {
        let continuation = pendingStop
        pendingStop = nil
        continuation?.resume()
    }

    func suspendNextCaptureStart() {
        shouldSuspendCaptureStart = true
    }

    func failPendingCaptureStart() {
        let continuation = pendingCaptureStart
        pendingCaptureStart = nil
        continuation?.resume(throwing: ProductAudioFailure.interrupted)
    }

    func emitLifecycleStop() {
        continuation.yield(.lifecycleStopped(.interruptionBegan))
    }
}
