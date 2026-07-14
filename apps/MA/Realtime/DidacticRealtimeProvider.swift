import Foundation

private actor GuidedRealtimeEventMailbox {
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<GuidedRealtimeServerEvent?, Never>
    }

    private var buffered: [GuidedRealtimeServerEvent] = []
    private var waiter: Waiter?
    private var connectionGeneration: UInt64 = 0
    private var finished = false

    func beginConnection() -> UInt64 {
        connectionGeneration &+= 1
        clear(resumingWaiter: true)
        return connectionGeneration
    }

    func invalidateConnection() {
        connectionGeneration &+= 1
        clear(resumingWaiter: true)
    }

    func push(_ event: GuidedRealtimeServerEvent, generation: UInt64) {
        guard !finished, generation == connectionGeneration else { return }
        if let waiter {
            self.waiter = nil
            waiter.continuation.resume(returning: event)
            return
        }
        if buffered.count == 256 {
            buffered.removeFirst()
        }
        buffered.append(event)
    }

    func reset() {
        buffered.removeAll(keepingCapacity: true)
    }

    func next() async -> GuidedRealtimeServerEvent? {
        if !buffered.isEmpty {
            return buffered.removeFirst()
        }
        guard !finished, waiter == nil else { return nil }
        let id = UUID()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                waiter = Waiter(id: id, continuation: continuation)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id: id) }
        }
    }

    func finish() {
        finished = true
        clear(resumingWaiter: true)
    }

    private func cancelWaiter(id: UUID) {
        guard waiter?.id == id else { return }
        let continuation = waiter?.continuation
        waiter = nil
        continuation?.resume(returning: nil)
    }

    private func clear(resumingWaiter: Bool) {
        buffered.removeAll(keepingCapacity: true)
        guard resumingWaiter, let waiter else { return }
        self.waiter = nil
        waiter.continuation.resume(returning: nil)
    }
}

actor DidacticRealtimeProvider: GuidedRealtimeProviding {
    private struct ReviewEnvelope {
        let call: GuidedRealtimeFunctionCall
        let arguments: String
        let itemID: String
        let approximateTranscript: String?
    }

    private struct SpokenEnvelope {
        let transcript: String?
        let pcm16Data: Data
    }

    private struct PendingSpokenFeedback {
        let result: GuidedRealtimeReviewResult
        let itemID: String
        let callID: String
        let functionOutput: String
    }

    private struct ConnectionAttempt {
        let generation: UInt64
        let task: Task<Void, Error>
    }

    private let broker: any GuidedRealtimeSecretMinting
    private let transport: any GuidedRealtimeTransporting
    private let mailbox = GuidedRealtimeEventMailbox()
    private let clock = ContinuousClock()

    private var connected = false
    private var operationActive = false
    private var nextCommandSequence: UInt64 = 0
    private var connectionGeneration: UInt64 = 0
    private var connectionAttempt: ConnectionAttempt?
    private var transportMayBeOpen = false
    private var pendingSpokenFeedback: PendingSpokenFeedback?

    init(
        broker: any GuidedRealtimeSecretMinting = GuidedRealtimeSessionBrokerClient(),
        transport: any GuidedRealtimeTransporting = GuidedRealtimeWebSocketTransport()
    ) {
        self.broker = broker
        self.transport = transport
    }

    func connect() async throws {
        guard !connected else { return }

        let attempt: ConnectionAttempt
        if let connectionAttempt {
            attempt = connectionAttempt
        } else {
            let mailboxGeneration = await mailbox.beginConnection()
            connectionGeneration &+= 1
            let generation = connectionGeneration
            transportMayBeOpen = true
            let task = Task { [broker, transport, mailbox] in
                let secret = try await broker.mintClientSecret()
                try Task.checkCancellation()
                try await transport.connect(clientSecret: secret) { event in
                    await mailbox.push(event, generation: mailboxGeneration)
                }
                try Task.checkCancellation()
            }
            attempt = ConnectionAttempt(generation: generation, task: task)
            connectionAttempt = attempt
        }

        do {
            try await attempt.task.value
            guard !Task.isCancelled,
                  attempt.generation == connectionGeneration else {
                throw CancellationError()
            }
            if connectionAttempt?.generation == attempt.generation {
                connectionAttempt = nil
            }
            connected = true
        } catch is CancellationError {
            if connectionAttempt?.generation == attempt.generation {
                connectionAttempt = nil
            }
            if attempt.generation == connectionGeneration {
                await invalidateConnection(expectedGeneration: attempt.generation)
            }
            throw CancellationError()
        } catch let error as GuidedRealtimeError {
            if connectionAttempt?.generation == attempt.generation {
                connectionAttempt = nil
            }
            if attempt.generation == connectionGeneration {
                await invalidateConnection(expectedGeneration: attempt.generation)
            }
            throw error
        } catch {
            if connectionAttempt?.generation == attempt.generation {
                connectionAttempt = nil
            }
            if attempt.generation == connectionGeneration {
                await invalidateConnection(expectedGeneration: attempt.generation)
            }
            throw GuidedRealtimeError.connectionFailed
        }
    }

    func reviewAttempt(
        _ request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws -> GuidedRealtimeReviewResult {
        guard !operationActive else { throw GuidedRealtimeError.providerRejected }
        guard request.targetPhraseID == GuidedAttemptRequest.targetPhraseID,
              request.attemptNumber > 0,
              pcm16Data.count >= 9_600,
              pcm16Data.count <= 576_000,
              pcm16Data.count.isMultiple(of: MemoryLayout<Int16>.size) else {
            throw GuidedRealtimeError.noSpeech
        }

        operationActive = true
        defer { operationActive = false }
        if pendingSpokenFeedback != nil {
            await invalidateConnection(
                expectedGeneration: connectionGeneration
            )
        }
        pendingSpokenFeedback = nil
        try await connect()
        let operationConnectionGeneration = connectionGeneration
        await mailbox.reset()

        do {
            try await sendInputAndReviewRequest(request: request, pcm16Data: pcm16Data)
            let envelope = try await awaitReview(request: request)
            var review = try GuidedAttemptReview.validated(
                arguments: envelope.arguments,
                attemptID: request.id,
                approximateTranscript: envelope.approximateTranscript
            )
            if review.targetMatch == .unclear {
                review = .unclear(attemptID: request.id)
            }

            let result = GuidedRealtimeReviewResult(
                request: request,
                review: review,
                approximateTranscript: envelope.approximateTranscript
            )

            if let output = try? review.functionOutput() {
                pendingSpokenFeedback = PendingSpokenFeedback(
                    result: result,
                    itemID: envelope.itemID,
                    callID: envelope.call.callID,
                    functionOutput: output
                )
            } else {
                pendingSpokenFeedback = nil
            }

            // The validated, canonical text review returns immediately. Spoken
            // feedback is a separate best-effort request so audio generation
            // can never hold the learner in the reviewing state.
            return result
        } catch let error as GuidedRealtimeError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw error
        } catch is CancellationError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw CancellationError()
        } catch {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw GuidedRealtimeError.providerRejected
        }
    }

    func requestSpokenFeedback(
        for result: GuidedRealtimeReviewResult
    ) async throws -> GuidedRealtimeSpokenFeedback {
        guard !operationActive,
              let pending = pendingSpokenFeedback,
              pending.result.request.id == result.request.id,
              pending.result.review == result.review,
              pending.result.approximateTranscript == result.approximateTranscript else {
            throw GuidedRealtimeError.playbackUnavailable
        }

        pendingSpokenFeedback = nil
        operationActive = true
        defer { operationActive = false }
        let operationConnectionGeneration = connectionGeneration
        await mailbox.reset()

        do {
            let spoken = try await withTaskCancellationHandler {
                try await transport.send(
                    GuidedRealtimeClientCommand.functionOutput(
                        callID: pending.callID,
                        output: pending.functionOutput,
                        eventID: nextCommandID(prefix: "tool_output")
                    )
                )
                try Task.checkCancellation()
                try await transport.send(
                    GuidedRealtimeClientCommand.createSpokenFeedbackResponse(
                        review: result.review,
                        language: result.request.feedbackLanguage,
                        eventID: nextCommandID(prefix: "spoken_feedback")
                    )
                )
                try Task.checkCancellation()
                return try await awaitAudioResponse(
                    purpose: "spoken_attempt_feedback",
                    inputItemID: pending.itemID,
                    approximateTranscript: result.approximateTranscript
                )
            } onCancel: {
                Task {
                    await self.invalidateConnection(
                        expectedGeneration: operationConnectionGeneration
                    )
                }
            }
            return GuidedRealtimeSpokenFeedback(
                transcript: spoken.transcript,
                pcm16Data: spoken.pcm16Data
            )
        } catch let error as GuidedRealtimeError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw error
        } catch is CancellationError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw CancellationError()
        } catch {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw GuidedRealtimeError.playbackUnavailable
        }
    }

    func requestRestaurantTurn() async throws -> GuidedRealtimeTutorTurn {
        guard !operationActive else { throw GuidedRealtimeError.providerRejected }
        operationActive = true
        defer { operationActive = false }
        if pendingSpokenFeedback != nil {
            await invalidateConnection(
                expectedGeneration: connectionGeneration
            )
        }
        pendingSpokenFeedback = nil
        try await connect()
        let operationConnectionGeneration = connectionGeneration
        await mailbox.reset()

        do {
            let result = try await withTaskCancellationHandler {
                try await transport.send(
                    GuidedRealtimeClientCommand.createRestaurantTurn(
                        eventID: nextCommandID(prefix: "restaurant_turn")
                    )
                )
                try Task.checkCancellation()
                return try await awaitAudioResponse(
                    purpose: "restaurant_waiter_turn",
                    inputItemID: nil,
                    approximateTranscript: nil
                )
            } onCancel: {
                Task {
                    await self.invalidateConnection(
                        expectedGeneration: operationConnectionGeneration
                    )
                }
            }
            return GuidedRealtimeTutorTurn(
                transcript: result.transcript,
                pcm16Data: result.pcm16Data
            )
        } catch let error as GuidedRealtimeError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw error
        } catch is CancellationError {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw CancellationError()
        } catch {
            await invalidateConnection(expectedGeneration: operationConnectionGeneration)
            throw GuidedRealtimeError.providerRejected
        }
    }

    func disconnect() async {
        operationActive = false
        await invalidateConnection()
    }

    /// Invalidates both the socket and its mailbox generation. Disconnecting
    /// is intentionally stronger than a best-effort response.cancel: no late
    /// audio from an abandoned optional response can be mistaken for the next
    /// tutor turn after reconnecting.
    private func invalidateConnection(expectedGeneration: UInt64? = nil) async {
        if let expectedGeneration,
           expectedGeneration != connectionGeneration {
            return
        }
        let shouldDisconnectTransport = transportMayBeOpen
        transportMayBeOpen = false
        connectionGeneration &+= 1
        connectionAttempt?.task.cancel()
        connectionAttempt = nil
        connected = false
        pendingSpokenFeedback = nil
        await mailbox.invalidateConnection()
        if shouldDisconnectTransport {
            await transport.disconnect()
        }
    }

    private func sendInputAndReviewRequest(
        request: GuidedAttemptRequest,
        pcm16Data: Data
    ) async throws {
        try await transport.send(
            GuidedRealtimeClientCommand.clearInput(
                eventID: nextCommandID(prefix: "clear")
            )
        )

        var offset = 0
        while offset < pcm16Data.count {
            let end = min(offset + 48_000, pcm16Data.count)
            let chunk = pcm16Data.subdata(in: offset..<end)
            try await transport.send(
                GuidedRealtimeClientCommand.appendInputAudio(
                    chunk,
                    eventID: nextCommandID(prefix: "audio")
                )
            )
            offset = end
        }

        try await transport.send(
            GuidedRealtimeClientCommand.commitInput(
                eventID: nextCommandID(prefix: "commit")
            )
        )
        try await transport.send(
            GuidedRealtimeClientCommand.createReviewResponse(
                request: request,
                eventID: nextCommandID(prefix: "review")
            )
        )
    }

    private func awaitReview(
        request: GuidedAttemptRequest
    ) async throws -> ReviewEnvelope {
        let deadline = clock.now.advanced(by: .seconds(18))
        var inputItemID: String?
        var approximateTranscript: String?
        var transcriptionFailed = false
        var responseID: String?
        var call: GuidedRealtimeFunctionCall?
        var responseCompleted = false

        while clock.now < deadline {
            let event = try await nextEvent(until: deadline)
            switch event {
            case .inputCommitted(_, let itemID):
                guard inputItemID == nil || inputItemID == itemID else {
                    throw GuidedRealtimeError.providerRejected
                }
                inputItemID = itemID

            case .inputTranscript(_, let itemID, let transcript):
                if inputItemID == itemID {
                    approximateTranscript = transcript
                }

            case .inputTranscriptFailed(_, let itemID):
                if inputItemID == itemID {
                    transcriptionFailed = true
                }

            case .responseStarted(_, let id):
                guard responseID == nil || responseID == id else { continue }
                responseID = id

            case .functionCall(let candidate):
                guard candidate.name == "report_attempt",
                      call == nil,
                      responseID == nil || responseID == candidate.responseID else {
                    throw GuidedRealtimeError.invalidReview
                }
                responseID = candidate.responseID
                call = candidate

            case .responseFinished(_, let id, let status):
                guard responseID == nil || responseID == id else { continue }
                responseID = id
                guard status == "completed" else {
                    throw GuidedRealtimeError.responseIncomplete
                }
                responseCompleted = true

            case .outputAudio(let chunk):
                if chunk.responseID == responseID {
                    throw GuidedRealtimeError.invalidReview
                }

            case .providerError, .transportFailed:
                connected = false
                throw GuidedRealtimeError.disconnected

            default:
                break
            }

            if let inputItemID, let call, responseCompleted {
                if approximateTranscript == nil, !transcriptionFailed {
                    approximateTranscript = try await awaitLateTranscript(
                        itemID: inputItemID,
                        maximumWait: .milliseconds(1_500)
                    )
                }
                return ReviewEnvelope(
                    call: call,
                    arguments: call.arguments,
                    itemID: inputItemID,
                    approximateTranscript: approximateTranscript
                )
            }
        }
        throw GuidedRealtimeError.responseTimedOut
    }

    private func awaitLateTranscript(
        itemID: String,
        maximumWait: Duration
    ) async throws -> String? {
        let deadline = clock.now.advanced(by: maximumWait)
        while clock.now < deadline {
            do {
                let event = try await nextEvent(until: deadline)
                switch event {
                case .inputTranscript(_, let candidateID, let transcript)
                    where candidateID == itemID:
                    return transcript
                case .inputTranscriptFailed(_, let candidateID)
                    where candidateID == itemID:
                    return nil
                case .providerError, .transportFailed:
                    connected = false
                    throw GuidedRealtimeError.disconnected
                default:
                    continue
                }
            } catch GuidedRealtimeError.responseTimedOut {
                return nil
            }
        }
        return nil
    }

    private func awaitAudioResponse(
        purpose: String,
        inputItemID: String?,
        approximateTranscript: String?
    ) async throws -> SpokenEnvelope {
        let deadline = clock.now.advanced(by: .seconds(20))
        var responseID: String?
        var responseCompleted = false
        var audioFinished = false
        var audioData = Data()
        var transcript: String?
        var retainedInputTranscript = approximateTranscript

        while clock.now < deadline {
            let event = try await nextEvent(until: deadline)
            switch event {
            case .responseStarted(_, let id):
                guard responseID == nil || responseID == id else { continue }
                responseID = id

            case .outputAudio(let chunk):
                guard responseID == nil || responseID == chunk.responseID else { continue }
                responseID = chunk.responseID
                guard audioData.count + chunk.pcm16Data.count <= 1_200_000 else {
                    throw GuidedRealtimeError.providerRejected
                }
                audioData.append(chunk.pcm16Data)

            case .outputAudioFinished(_, let id, _):
                guard responseID == nil || responseID == id else { continue }
                responseID = id
                audioFinished = true

            case .outputTranscript(_, let id, _, let value):
                guard responseID == nil || responseID == id else { continue }
                responseID = id
                transcript = value

            case .responseFinished(_, let id, let status):
                guard responseID == nil || responseID == id else { continue }
                responseID = id
                guard status == "completed" else {
                    throw GuidedRealtimeError.responseIncomplete
                }
                responseCompleted = true

            case .inputTranscript(_, let itemID, let value):
                if itemID == inputItemID {
                    retainedInputTranscript = value
                }

            case .functionCall:
                throw GuidedRealtimeError.providerRejected

            case .providerError, .transportFailed:
                connected = false
                throw GuidedRealtimeError.disconnected

            default:
                break
            }

            if responseID != nil, responseCompleted, audioFinished, !audioData.isEmpty {
                _ = purpose
                _ = retainedInputTranscript
                return SpokenEnvelope(transcript: transcript, pcm16Data: audioData)
            }
        }
        throw GuidedRealtimeError.responseTimedOut
    }

    private func nextEvent(
        until deadline: ContinuousClock.Instant
    ) async throws -> GuidedRealtimeServerEvent {
        let remaining = clock.now.duration(to: deadline)
        guard remaining > .zero else { throw GuidedRealtimeError.responseTimedOut }

        return try await withThrowingTaskGroup(of: GuidedRealtimeServerEvent.self) { group in
            group.addTask { [mailbox] in
                guard let event = await mailbox.next() else {
                    throw GuidedRealtimeError.disconnected
                }
                return event
            }
            group.addTask {
                try await ContinuousClock().sleep(for: remaining)
                throw GuidedRealtimeError.responseTimedOut
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw GuidedRealtimeError.disconnected
            }
            return result
        }
    }

    private func nextCommandID(prefix: String) -> String {
        defer { nextCommandSequence &+= 1 }
        return "evt_product_\(prefix)_\(nextCommandSequence)"
    }
}
