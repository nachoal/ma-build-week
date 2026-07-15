import Foundation
import Testing
@testable import MA

@Suite("Didactic Realtime provider orchestration")
struct DidacticRealtimeProviderTests {
    @Test("A reviewed attempt sends one ordered push-to-talk transaction")
    func completeReviewedTurn() async throws {
        let transport = ScriptedGuidedTransport()
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )
        let request = GuidedAttemptRequest(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!,
            context: .taughtPhrase,
            attemptNumber: 1
        )

        let result = try await provider.reviewAttempt(
            request,
            pcm16Data: Data(repeating: 1, count: 19_200)
        )

        #expect(result.request == request)
        #expect(result.review.targetMatch == .close)
        #expect(result.approximateTranscript == "一人です")
        #expect(await transport.commandTypes() == [
            "input_audio_buffer.clear",
            "input_audio_buffer.append",
            "input_audio_buffer.commit",
            "response.create",
        ])

        let spoken = try await provider.requestSpokenFeedback(for: result)
        #expect(spoken.pcm16Data.count == 4_800)
        #expect(spoken.transcript == "Buen intento. Separa hi-to-ri.")
        #expect(await transport.commandTypes() == [
            "input_audio_buffer.clear",
            "input_audio_buffer.append",
            "input_audio_buffer.commit",
            "response.create",
            "conversation.item.create",
            "response.create",
        ])
        #expect(await transport.responsePurposes() == [
            "attempt_review",
            "spoken_attempt_feedback",
        ])
    }

    @Test("An incomplete review response is never surfaced as learner feedback")
    func incompleteReviewFailsClosed() async {
        let transport = ScriptedGuidedTransport(reviewStatus: "incomplete")
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )
        let request = GuidedAttemptRequest(context: .restaurantTurn, attemptNumber: 1)

        await #expect(throws: GuidedRealtimeError.responseIncomplete) {
            try await provider.reviewAttempt(
                request,
                pcm16Data: Data(repeating: 1, count: 19_200)
            )
        }
        #expect(await transport.commandTypes() == [
            "input_audio_buffer.clear",
            "input_audio_buffer.append",
            "input_audio_buffer.commit",
            "response.create",
        ])
    }

    @Test("The waiter turn is one bounded captioned audio response")
    func boundedWaiterTurn() async throws {
        let transport = ScriptedGuidedTransport()
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )

        let turn = try await provider.requestRestaurantTurn()

        #expect(turn.transcript == "何名様ですか？")
        #expect(turn.pcm16Data.count == 4_800)
        #expect(await transport.commandTypes() == ["response.create"])
        #expect(await transport.responsePurposes() == ["restaurant_waiter_turn"])
    }

    @Test("Empty, odd, short, or oversized learner audio never reaches transport")
    func rejectsInvalidAudioBeforeSending() async {
        let transport = ScriptedGuidedTransport()
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )
        let request = GuidedAttemptRequest(context: .taughtPhrase, attemptNumber: 1)

        for data in [
            Data(),
            Data(repeating: 1, count: 9_599),
            Data(repeating: 1, count: 576_002),
        ] {
            await #expect(throws: GuidedRealtimeError.noSpeech) {
                try await provider.reviewAttempt(request, pcm16Data: data)
            }
        }
        #expect(await transport.commandTypes().isEmpty)
    }

    @Test("Warm-up and review share exactly one in-flight connection")
    func concurrentConnectsShareAttempt() async throws {
        let broker = SuspendedGuidedSecretBroker()
        let transport = CountingGuidedTransport()
        let provider = DidacticRealtimeProvider(broker: broker, transport: transport)

        let first = Task { try await provider.connect() }
        #expect(await eventually { await broker.requestCount() == 1 })
        let second = Task { try await provider.connect() }
        for _ in 0..<20 { await Task.yield() }
        #expect(await broker.requestCount() == 1)

        await broker.resolve()
        try await first.value
        try await second.value
        #expect(await transport.connectCount() == 1)
    }

    @Test("A transport failure after warm-up reconnects before readiness")
    func staleWarmTransportReconnects() async throws {
        let transport = CountingGuidedTransport()
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )

        try await provider.connect()
        await transport.failConnection()
        try await provider.connect()

        #expect(await transport.connectCount() == 2)
        #expect(await transport.disconnectCount() == 1)
        #expect(await transport.connectionState() == .connected)
    }

    @Test("Disconnect invalidates a late secret mint without resurrecting transport")
    func disconnectInvalidatesLateConnect() async {
        let broker = SuspendedGuidedSecretBroker()
        let transport = CountingGuidedTransport()
        let provider = DidacticRealtimeProvider(broker: broker, transport: transport)

        let connection = Task { try await provider.connect() }
        #expect(await eventually { await broker.requestCount() == 1 })
        await provider.disconnect()
        await broker.resolve()

        do {
            try await connection.value
            Issue.record("A disconnected connection attempt must not succeed")
        } catch is CancellationError {
            // Expected: the stored connection task is canceled and fenced.
        } catch {
            Issue.record("Expected cancellation, received \(error)")
        }
        #expect(await transport.connectCount() == 0)
        #expect(await transport.disconnectCount() == 1)
    }

    @Test("Canceling spoken feedback fences late audio before the waiter turn")
    func canceledSpokenFeedbackCannotLeakIntoWaiterTurn() async throws {
        let transport = ScriptedGuidedTransport(holdsSpokenFeedback: true)
        let provider = DidacticRealtimeProvider(
            broker: StubGuidedSecretBroker(),
            transport: transport
        )
        let request = GuidedAttemptRequest(context: .taughtPhrase, attemptNumber: 1)
        let result = try await provider.reviewAttempt(
            request,
            pcm16Data: Data(repeating: 1, count: 19_200)
        )

        let spoken = Task {
            try await provider.requestSpokenFeedback(for: result)
        }
        #expect(await eventually {
            (await transport.responsePurposes()).contains("spoken_attempt_feedback")
        })
        spoken.cancel()
        do {
            _ = try await spoken.value
            Issue.record("Canceled spoken feedback must not complete")
        } catch {
            // Cancellation closes the connection; either cancellation or the
            // resulting disconnected error is an acceptable local outcome.
        }

        #expect(await transport.disconnectCount() == 1)
        let waiter = try await provider.requestRestaurantTurn()
        #expect(waiter.transcript == "何名様ですか？")
        #expect(waiter.pcm16Data == Data(repeating: 1, count: 4_800))
        #expect(await transport.connectCount() == 2)
        #expect(await transport.responsePurposes() == [
            "attempt_review",
            "spoken_attempt_feedback",
            "restaurant_waiter_turn",
        ])
    }

    private func eventually(
        _ condition: @escaping @Sendable () async -> Bool
    ) async -> Bool {
        for _ in 0..<400 {
            if await condition() { return true }
            await Task.yield()
        }
        return await condition()
    }
}

private actor StubGuidedSecretBroker: GuidedRealtimeSecretMinting {
    func mintClientSecret() async throws -> GuidedRealtimeClientSecret {
        GuidedRealtimeClientSecret(
            value: "ek_test_secret",
            expiresAt: Int(Date().timeIntervalSince1970) + 120,
            expectedConfigurationHash: String(repeating: "a", count: 64)
        )
    }
}

private actor SuspendedGuidedSecretBroker: GuidedRealtimeSecretMinting {
    private var requests = 0
    private var continuation:
        CheckedContinuation<GuidedRealtimeClientSecret, Error>?

    func mintClientSecret() async throws -> GuidedRealtimeClientSecret {
        requests += 1
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func requestCount() -> Int { requests }

    func resolve() {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: GuidedRealtimeClientSecret(
            value: "ek_test_secret",
            expiresAt: Int(Date().timeIntervalSince1970) + 120,
            expectedConfigurationHash: String(repeating: "a", count: 64)
        ))
    }
}

private actor CountingGuidedTransport: GuidedRealtimeTransporting {
    private var connections = 0
    private var disconnections = 0
    private var state: GuidedRealtimeTransportState = .idle

    func connect(
        clientSecret: GuidedRealtimeClientSecret,
        onEvent: @escaping @Sendable (GuidedRealtimeServerEvent) async -> Void
    ) async throws {
        connections += 1
        state = .connected
    }

    func send(_ command: Data) async throws {}

    func connectionState() async -> GuidedRealtimeTransportState { state }

    func disconnect() async {
        disconnections += 1
        state = .idle
    }

    func failConnection() { state = .failed }

    func connectCount() -> Int { connections }
    func disconnectCount() -> Int { disconnections }
}

private actor ScriptedGuidedTransport: GuidedRealtimeTransporting {
    private let reviewStatus: String
    private let holdsSpokenFeedback: Bool
    private var handler: (@Sendable (GuidedRealtimeServerEvent) async -> Void)?
    private var staleHandler: (@Sendable (GuidedRealtimeServerEvent) async -> Void)?
    private var types: [String] = []
    private var purposes: [String] = []
    private var connections = 0
    private var disconnections = 0
    private var state: GuidedRealtimeTransportState = .idle

    init(
        reviewStatus: String = "completed",
        holdsSpokenFeedback: Bool = false
    ) {
        self.reviewStatus = reviewStatus
        self.holdsSpokenFeedback = holdsSpokenFeedback
    }

    func connect(
        clientSecret: GuidedRealtimeClientSecret,
        onEvent: @escaping @Sendable (GuidedRealtimeServerEvent) async -> Void
    ) async throws {
        connections += 1
        handler = onEvent
        state = .connected
    }

    func send(_ command: Data) async throws {
        let object = try #require(
            JSONSerialization.jsonObject(with: command) as? [String: Any]
        )
        let type = try #require(object["type"] as? String)
        types.append(type)

        if type == "input_audio_buffer.commit" {
            await handler?(.inputCommitted(
                eventID: "server-commit",
                itemID: "item-input"
            ))
            await handler?(.inputTranscript(
                eventID: "server-transcript",
                itemID: "item-input",
                transcript: "一人です"
            ))
            return
        }
        guard type == "response.create",
              let response = object["response"] as? [String: Any],
              let metadata = response["metadata"] as? [String: Any],
              let purpose = metadata["purpose"] as? String else { return }
        purposes.append(purpose)

        switch purpose {
        case "attempt_review":
            let arguments = try reviewArguments()
            // Function output may precede response.created; correlation must
            // use its response ID and still require completed response.done.
            await handler?(.functionCall(GuidedRealtimeFunctionCall(
                eventID: "server-tool",
                responseID: "response-review",
                itemID: "item-tool",
                outputIndex: 0,
                callID: "call-review",
                name: "report_attempt",
                arguments: arguments
            )))
            await handler?(.responseStarted(
                eventID: "server-review-started",
                responseID: "response-review"
            ))
            await handler?(.responseFinished(
                eventID: "server-review-done",
                responseID: "response-review",
                status: reviewStatus,
                incompleteReason: reviewStatus == "completed" ? nil : "max_output_tokens"
            ))

        case "spoken_attempt_feedback":
            guard !holdsSpokenFeedback else { return }
            await emitAudioResponse(
                responseID: "response-feedback",
                itemID: "item-feedback",
                transcript: "Buen intento. Separa hi-to-ri."
            )

        case "restaurant_waiter_turn":
            if let staleHandler {
                self.staleHandler = nil
                await emitAudioResponse(
                    responseID: "response-feedback-late",
                    itemID: "item-feedback-late",
                    transcript: "This old coaching audio must be ignored.",
                    handler: staleHandler
                )
            }
            await emitAudioResponse(
                responseID: "response-waiter",
                itemID: "item-waiter",
                transcript: "何名様ですか？"
            )

        default:
            throw GuidedRealtimeError.providerRejected
        }
    }

    func disconnect() async {
        disconnections += 1
        staleHandler = handler
        handler = nil
        state = .idle
    }

    func connectionState() async -> GuidedRealtimeTransportState { state }

    func commandTypes() -> [String] { types }
    func responsePurposes() -> [String] { purposes }
    func connectCount() -> Int { connections }
    func disconnectCount() -> Int { disconnections }

    private func reviewArguments() throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: [
                "target_phrase_id": GuidedAttemptRequest.targetPhraseID,
                "assessment": "close",
                "evidence_code": "partial_target_in_transcript",
                "retry_focus_code": "complete_target",
            ],
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        return String(data: data, encoding: .utf8)!
    }

    private func emitAudioResponse(
        responseID: String,
        itemID: String,
        transcript: String,
        handler selectedHandler: (@Sendable (GuidedRealtimeServerEvent) async -> Void)? = nil
    ) async {
        guard let selectedHandler = selectedHandler ?? handler else { return }
        await selectedHandler(.responseStarted(
            eventID: "\(responseID)-started",
            responseID: responseID
        ))
        await selectedHandler(.outputAudio(GuidedRealtimeOutputAudioChunk(
            eventID: "\(responseID)-audio",
            responseID: responseID,
            itemID: itemID,
            outputIndex: 0,
            contentIndex: 0,
            pcm16Data: Data(repeating: 1, count: 4_800)
        )))
        await selectedHandler(.outputTranscript(
            eventID: "\(responseID)-transcript",
            responseID: responseID,
            itemID: itemID,
            transcript: transcript
        ))
        await selectedHandler(.outputAudioFinished(
            eventID: "\(responseID)-audio-done",
            responseID: responseID,
            itemID: itemID
        ))
        await selectedHandler(.responseFinished(
            eventID: "\(responseID)-done",
            responseID: responseID,
            status: "completed",
            incompleteReason: nil
        ))
    }
}
