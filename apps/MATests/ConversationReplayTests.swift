import Foundation
import Testing
@testable import MA

@Suite("Normalized PARTIAL conversation replay")
struct ConversationReplayTests {
    @Test("Capability groups cannot imply revoked live or exact behavior")
    func capabilitiesStayIndependent() {
        let product = PracticeCapabilities.gate0Partial
        #expect(product.conversation.model == .unavailable)
        #expect(product.conversation.audioTopology.supportsImmediateLocalStop)
        #expect(!product.conversation.audioTopology.supportsOverlappingCapture)
        #expect(!product.conversation.audioTopology.exposesRenderedCursor)
        #expect(!product.conversation.audioTopology.supportsExactRenderedReplay)
        #expect(!product.conversation.floorPolicy.distinguishesBackchannels)
        #expect(
            product.conversation.floorPolicy.evidenceVerdict
                == .characterizationOnlyPartial
        )

        let replay = ConversationCapabilitySnapshot.labeledReplay
        #expect(replay.model == .unavailable)
        #expect(replay.audioTopology == .unavailable)
        #expect(!replay.floorPolicy.distinguishesBackchannels)
        #expect(replay.floorPolicy.evidenceVerdict == .unavailable)
    }

    @Test("Canonical fixture is bounded, Codable, monotonic, and PARTIAL-only")
    func fixtureContract() throws {
        let script = KaiwaLoopReplayFixture.script
        #expect(script.events.count <= ReplayConversationScript.maximumEventCount)
        #expect(ReplayConversationScript.validate(
            configuration: script.configuration,
            events: script.events
        ))
        #expect(script.events.map(\.sequence) == Array(script.events.indices))
        #expect(Set(script.events.map(\.correlationID)).count == script.events.count)
        #expect(script.events.allSatisfy { $0.source == .labeledReplay })
        #expect(script.events.allSatisfy { !$0.supportsLiveClaim })
        #expect(script.events.allSatisfy { !$0.supportsExactHeardClaim })
        #expect(script.events.allSatisfy { !$0.evidence.retainsRawAudio })
        #expect(script.events.allSatisfy { !$0.evidence.retainsRawProviderPayload })
        #expect(!script.events.contains { event in
            switch event.payload {
            case .backchannelDetected, .takeFloorDetected,
                 .learnerPartialTranscript, .tutorTranscriptDelta:
                true
            default:
                false
            }
        })

        let encoded = try JSONEncoder().encode(script)
        let decoded = try JSONDecoder().decode(ReplayConversationScript.self, from: encoded)
        #expect(decoded == script)
        let text = try #require(String(data: encoded, encoding: .utf8))
        #expect(!text.localizedCaseInsensitiveContains("authorization"))
        #expect(!text.localizedCaseInsensitiveContains("client_secret"))
        #expect(!text.localizedCaseInsensitiveContains("api_key"))
    }

    @Test("Malformed, cross-session, live, exact, and post-terminal scripts fail closed")
    func invalidScriptsAreRejected() {
        let canonical = KaiwaLoopReplayFixture.script

        var outOfOrder = canonical.events
        outOfOrder.swapAt(3, 4)
        expectInvalid(outOfOrder)

        var duplicateCorrelation = canonical.events
        duplicateCorrelation[4] = copy(
            duplicateCorrelation[4],
            correlationID: duplicateCorrelation[3].correlationID
        )
        expectInvalid(duplicateCorrelation)

        var crossSession = canonical.events
        crossSession[5] = copy(crossSession[5], sessionID: UUID())
        expectInvalid(crossSession)

        var live = canonical.events
        live[5] = copy(live[5], source: .realtimeProvider)
        expectInvalid(live)

        var exact = canonical.events
        exact[5] = copy(
            exact[5],
            evidence: ConversationEventEvidence(
                provenance: .renderedAudioMeasured,
                isSanitized: true,
                retainsRawProviderPayload: false,
                retainsRawAudio: false
            )
        )
        expectInvalid(exact)

        var overlap = canonical.events
        overlap[5] = copy(overlap[5], payload: .backchannelDetected(atNanoseconds: 1))
        expectInvalid(overlap)

        var postTerminal = canonical.events
        let terminal = try! #require(postTerminal.last)
        postTerminal.append(
            copy(
                terminal,
                sequence: postTerminal.count,
                monotonicNanoseconds: terminal.monotonicNanoseconds + 1,
                correlationID: "after-terminal",
                payload: .sessionWaiting
            )
        )
        expectInvalid(postTerminal)

        let overCapacity = Array(
            repeating: canonical.events[0],
            count: ReplayConversationScript.maximumEventCount + 1
        )
        expectInvalid(overCapacity)
    }

    @Test("Direct normalized reduction is deterministic and reaches honest proof")
    func deterministicTerminalState() throws {
        let first = KaiwaLoopReplayReducer.replay(KaiwaLoopReplayFixture.script.events)
        let second = KaiwaLoopReplayReducer.replay(KaiwaLoopReplayFixture.script.events)

        #expect(first == second)
        #expect(first.phase == .proof)
        #expect(first.presentationSource == .labeledReplay)
        #expect(first.sourceBadge == "REPLAY · NOT LIVE / NO EN VIVO")
        #expect(first.attempts.count == 4)
        #expect(first.attempts.allSatisfy { $0.provenance == .replayFixture })
        #expect(first.attempts.allSatisfy { !$0.rawAudioRetained })
        #expect(first.completedPreRepairAttempt?.repairCount == 0)
        #expect(first.completedPostRepairAttempt?.repairCount == 1)
        #expect(first.completedPreRepairAttempt?.obligationID == first.completedPostRepairAttempt?.obligationID)
        #expect(first.repairSegmentPlayed)
        #expect(first.resumePlaybackCompleted)
        #expect(!first.repairSegment.isExactRenderedWindow)
        #expect(first.learningReport == nil)
        #expect(first.nextLearningAction?.source == .cachedFixture)
        #expect(first.nextLearningAction?.model == "ma-kaiwa-replay-v1")

        var state = KaiwaLoopState()
        state.presentationSource = .labeledReplay
        for event in KaiwaLoopReplayFixture.script.events {
            state = KaiwaLoopReplayReducer.reduce(state, event)
            #expect(state.sourceBadge == "REPLAY · NOT LIVE / NO EN VIVO")
        }
    }

    @Test("Product and replay share the hero semantic reducer, including resume")
    func productAndReplaySemanticParity() {
        var product = KaiwaLoopState()
        func apply(_ action: KaiwaLoopSemanticAction) {
            product = KaiwaLoopReducer.reduce(product, action)
        }

        apply(.beginCoached(.full))
        apply(.recordAttempt(localAttempt(from: KaiwaLoopReplayFixture.attemptFull)))
        apply(.beginCoached(.rhythmOnly))
        apply(.recordAttempt(localAttempt(from: KaiwaLoopReplayFixture.attemptRhythm)))
        apply(.beginCoached(.none))
        apply(.recordAttempt(localAttempt(from: KaiwaLoopReplayFixture.attemptBeforeRepair)))
        apply(.confirmFirstExchange)
        apply(.introduceControls)
        apply(.beginNatural)
        apply(.naturalPlaybackBegan)
        apply(.requestRepair)
        apply(.completeRepairStop)
        apply(.completeControlledSegment)
        apply(.beginResume)
        #expect(product.phase == .resuming)
        apply(.completeResume)
        apply(.recordAttempt(localAttempt(from: KaiwaLoopReplayFixture.attemptAfterRepair)))
        apply(.setLearningAction(KaiwaLoopReplayFixture.cachedAction))
        apply(.finishLesson)

        var replay = KaiwaLoopState()
        var replayPhases: [KaiwaLoopPhase] = []
        for event in KaiwaLoopReplayFixture.script.events {
            replay = KaiwaLoopReplayReducer.reduce(replay, event)
            replayPhases.append(replay.phase)
        }

        #expect(replayPhases.contains(.resuming))
        #expect(product.phase == replay.phase)
        #expect(product.scaffold == replay.scaffold)
        #expect(product.successfulScaffolds == replay.successfulScaffolds)
        #expect(product.attempts.map(\.id) == replay.attempts.map(\.id))
        #expect(product.naturalStopRecorded == replay.naturalStopRecorded)
        #expect(product.repairSegmentPlayed == replay.repairSegmentPlayed)
        #expect(product.resumePlaybackCompleted == replay.resumePlaybackCompleted)
        #expect(product.naturalTutorFinished == replay.naturalTutorFinished)
        #expect(product.nextLearningAction == replay.nextLearningAction)
    }

    @Test("ReplayAdapter emits the exact canonical stream once")
    func adapterMatchesDirectStream() async throws {
        let first = try await collect(ReplayAdapter())
        let second = try await collect(ReplayAdapter())
        #expect(first == KaiwaLoopReplayFixture.script.events)
        #expect(first == second)

        let adapter = ReplayAdapter()
        await #expect(throws: ConversationProviderFailure.unsupportedIntent) {
            try await adapter.send(.audioControl(.stopTutorLocally))
        }
    }

    @Test("Midstream cancellation is terminal and cannot duplicate the stream")
    func cancellationIsTerminal() async throws {
        let adapter = ReplayAdapter(
            delivery: .paced(timeScale: 1, maximumDelay: .milliseconds(200))
        )
        var iterator = adapter.events.makeAsyncIterator()
        try await adapter.connect(configuration: KaiwaLoopReplayFixture.configuration)
        #expect(await iterator.next()?.sequence == 0)
        #expect(await iterator.next()?.sequence == 1)
        let producer = Task { try await adapter.requestResponse() }
        #expect(await iterator.next()?.sequence == 2)
        try await adapter.cancelResponse()

        await #expect(throws: ConversationProviderFailure.responseAlreadyRequested) {
            try await adapter.requestResponse()
        }
        await #expect(throws: ConversationProviderFailure.cancelled) {
            try await producer.value
        }
    }

    private func collect(_ adapter: ReplayAdapter) async throws -> [ConversationEvent] {
        let stream = adapter.events
        let producer = Task {
            try await adapter.connect(configuration: KaiwaLoopReplayFixture.configuration)
            try await adapter.requestResponse()
        }
        var result: [ConversationEvent] = []
        for await event in stream { result.append(event) }
        try await producer.value
        return result
    }

    private func expectInvalid(_ events: [ConversationEvent]) {
        #expect(throws: ConversationProviderFailure.invalidReplayScript) {
            try ReplayConversationScript(
                configuration: KaiwaLoopReplayFixture.configuration,
                events: events
            )
        }
    }

    private func localAttempt(
        from evidence: ConversationAttemptEvidence
    ) -> PracticeAttemptEvidence {
        let request = CaptureRequest(
            id: evidence.id,
            obligationID: evidence.obligationID,
            scaffold: evidence.scaffold,
            attemptNumber: evidence.attemptNumber
        )
        let receipt = CaptureReceipt(
            id: evidence.id,
            request: request,
            startedAt: Date(timeIntervalSince1970: 0),
            endedAt: Date(timeIntervalSince1970: evidence.capturedDuration),
            capturedDuration: evidence.capturedDuration,
            estimatedVoiceOnset: evidence.estimatedVoiceOnset,
            speechPresenceDetected: evidence.speechPresenceDetected,
            sampleRate: 48_000,
            disposition: .completed,
            rawAudioRetained: false
        )
        return PracticeAttemptEvidence(
            receipt: receipt,
            selfReportedCompleted: evidence.selfReportedCompleted,
            repairCount: evidence.repairCount
        )
    }

    private func copy(
        _ event: ConversationEvent,
        sequence: Int? = nil,
        monotonicNanoseconds: UInt64? = nil,
        sessionID: UUID? = nil,
        correlationID: String? = nil,
        source: ConversationEventSource? = nil,
        evidence: ConversationEventEvidence? = nil,
        payload: ConversationEventPayload? = nil
    ) -> ConversationEvent {
        ConversationEvent(
            schemaVersion: event.schemaVersion,
            sequence: sequence ?? event.sequence,
            monotonicNanoseconds: monotonicNanoseconds ?? event.monotonicNanoseconds,
            sessionID: sessionID ?? event.sessionID,
            sceneID: event.sceneID,
            obligationID: event.obligationID,
            correlationID: correlationID ?? event.correlationID,
            source: source ?? event.source,
            evidence: evidence ?? event.evidence,
            payload: payload ?? event.payload
        )
    }
}

@Suite("Labeled replay feature isolation", .serialized)
@MainActor
struct LabeledReplayFeatureIsolationTests {
    @Test("Complete replay calls neither audio nor planner")
    func noExternalSideEffects() async {
        let audio = ReplaySpyAudioController()
        let planner = ReplaySpyPlanner()
        let feature = KaiwaLoopFeature(
            audio: audio,
            learningPlanner: planner,
            presentationSource: .labeledReplay
        )

        feature.startLabeledReplay(delivery: .immediate)
        #expect(await eventually {
            feature.state.phase == .proof
                && feature.state.nextLearningAction?.source == .cachedFixture
        })
        #expect(feature.state.sourceBadge == "REPLAY · NOT LIVE / NO EN VIVO")
        #expect(audio.operationCount == 0)
        #expect(await planner.requestCount() == 0)
        #expect(feature.state.learningReport == nil)
        #expect(feature.state.nextLearningAction?.source == .cachedFixture)
    }

    @Test("Restart invalidates stale paced replay before starting a fresh run")
    func restartRejectsStaleEvents() async {
        let audio = ReplaySpyAudioController()
        let planner = ReplaySpyPlanner()
        let feature = KaiwaLoopFeature(
            audio: audio,
            learningPlanner: planner,
            presentationSource: .labeledReplay
        )

        feature.startLabeledReplay(
            delivery: .paced(timeScale: 1, maximumDelay: .seconds(1))
        )
        await Task.yield()
        feature.startLabeledReplay(delivery: .immediate)

        #expect(await eventually { feature.state.phase == .proof })
        #expect(feature.state.attempts.map(\.id) == [
            KaiwaLoopReplayFixture.attemptFull.id,
            KaiwaLoopReplayFixture.attemptRhythm.id,
            KaiwaLoopReplayFixture.attemptBeforeRepair.id,
            KaiwaLoopReplayFixture.attemptAfterRepair.id,
        ])
        #expect(audio.operationCount == 0)
        #expect(await planner.requestCount() == 0)
    }

    private func eventually(
        _ condition: @escaping @MainActor () -> Bool
    ) async -> Bool {
        for _ in 0..<500 {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }
}

@MainActor
private final class ReplaySpyAudioController: ProductAudioControlling {
    let events: AsyncStream<ProductAudioEvent>
    private(set) var state: ProductAudioState = .idle
    private(set) var operationCount = 0

    init() {
        events = AsyncStream { continuation in continuation.finish() }
    }

    func play(_ prompt: BundledPrompt) async throws {
        _ = prompt
        operationCount += 1
    }

    func startCapture(_ request: CaptureRequest) async throws {
        _ = request
        operationCount += 1
    }

    func finishCapture(_ disposition: CaptureDisposition) async throws -> CaptureReceipt? {
        _ = disposition
        operationCount += 1
        return nil
    }

    func stop(_ reason: AudioStopReason) async {
        _ = reason
        operationCount += 1
    }

    func handleLifecycle(_ event: AudioLifecycleEvent) async {
        _ = event
        operationCount += 1
    }
}

private actor ReplaySpyPlanner: LearningPlanning {
    private var count = 0

    func nextAction(for report: LearningReport) async -> NextLearningAction {
        count += 1
        return DeterministicPedagogyPolicy().fallback(for: report)
    }

    func requestCount() -> Int { count }
}
