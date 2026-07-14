#if DEBUG
import Foundation

/// Deterministic simulator-only dependencies used by UI automation. Production
/// can never select them because the entire file is compiled out of Release.
@MainActor
final class GuidedLessonUITestAudioController: GuidedLessonAudioControlling {
    private let continuation: AsyncStream<ProductAudioEvent>.Continuation
    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle
    private var activeRequest: CaptureRequest?

    init() {
        let pair = AsyncStream.makeStream(
            of: ProductAudioEvent.self,
            bufferingPolicy: .bufferingNewest(32)
        )
        events = pair.stream
        continuation = pair.continuation
    }

    func play(_ prompt: BundledPrompt) async throws {
        setState(.playing(prompt))
        try await ContinuousClock().sleep(for: .milliseconds(120))
        setState(.idle)
        continuation.yield(.playbackFinished(prompt))
    }

    func startRealtimeCapture(_ request: CaptureRequest) async throws {
        guard activeRequest == nil else { throw ProductAudioFailure.captureInProgress }
        activeRequest = request
        setState(.capturing(request))
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
        setState(.idle)
        continuation.yield(.captureFinished(receipt))
        return RealtimeCapturePayload(
            receipt: receipt,
            pcm16Data: Data(repeating: 1, count: 19_200)
        )
    }

    func playRealtimePCM16(_ data: Data) async throws {
        guard !data.isEmpty else { throw ProductAudioFailure.invalidProviderAudio }
        setState(.playingRealtime)
        try await ContinuousClock().sleep(for: .milliseconds(120))
        setState(.idle)
    }

    func stop(_ reason: AudioStopReason) async {
        activeRequest = nil
        setState(.idle)
    }

    private func setState(_ value: ProductAudioState) {
        state = value
        continuation.yield(.stateChanged(value))
    }
}

actor GuidedLessonUITestRealtimeProvider: GuidedRealtimeProviding {
    private var reviewCount = 0

    func connect() async throws {
        try await ContinuousClock().sleep(for: .milliseconds(50))
    }

    func reviewAttempt(
        _ request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws -> GuidedRealtimeReviewResult {
        guard pcm16Data.count >= 9_600 else { throw GuidedRealtimeError.noSpeech }
        try await ContinuousClock().sleep(for: .milliseconds(180))
        reviewCount += 1
        let match: GuidedTargetMatch = reviewCount == 1 ? .close : .matched
        let review = GuidedAttemptReview(
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
        return GuidedRealtimeReviewResult(
            request: request,
            review: review,
            approximateTranscript: "一人です"
        )
    }

    func requestSpokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) async throws -> GuidedRealtimeSpokenFeedback {
        try await ContinuousClock().sleep(for: .milliseconds(80))
        return GuidedRealtimeSpokenFeedback(
            transcript: result.request.feedbackLanguage.text(
                english: "MA caught part of the phrase. Say hi-to-ri de-su evenly.",
                spanish: "MA captó parte de la frase. Di hi-to-ri de-su a ritmo parejo."
            ),
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    func requestRestaurantTurn() async throws -> GuidedRealtimeTutorTurn {
        try await ContinuousClock().sleep(for: .milliseconds(120))
        return GuidedRealtimeTutorTurn(
            transcript: "何名様ですか？",
            pcm16Data: Data(repeating: 1, count: 4_800)
        )
    }

    func disconnect() async {}
}

actor GuidedLessonUITestLearningPlanner: GuidedLearningPlanning {
    func improvedAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction {
        try await ContinuousClock().sleep(for: .milliseconds(180))
        if ProcessInfo.processInfo.environment["MA_UI_TEST_GUIDED_PLANNER_FAIL"] == "true" {
            throw GuidedLearningPlannerError.invalidResponse
        }
        return GuidedPedagogyPolicy().make(
            report: report,
            action: .reduceScaffold,
            reason: .matchedWithSupport,
            source: .model,
            model: GuidedPedagogyPolicy.expectedRemoteModel
        )
    }
}
#endif
