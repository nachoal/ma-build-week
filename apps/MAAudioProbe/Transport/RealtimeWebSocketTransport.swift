import Foundation

enum RealtimeWebSocketTransportError: Error, Equatable {
    case alreadyConnected
    case invalidClientSecret
    case handshakeTimedOut
    case handshakeFailed
    case invalidHandshake
    case configurationMismatch
    case disconnected
    case invalidCommand
    case sendFailed
    case receiveFailed
}

enum RealtimeWebSocketTransportState: Sendable, Equatable {
    case idle
    case connecting
    case connected
    case failed
}

protocol RealtimeSocket: Sendable {
    func start() async
    func send(_ data: Data) async throws
    func receive() async throws -> Data
    func close() async
}

protocol RealtimeSocketCreating: Sendable {
    func makeSocket(request: URLRequest) -> any RealtimeSocket
}

struct URLSessionRealtimeSocketFactory: RealtimeSocketCreating {
    private let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func makeSocket(request: URLRequest) -> any RealtimeSocket {
        let task = session.webSocketTask(with: request)
        task.maximumMessageSize = 1_048_576
        return URLSessionRealtimeSocket(task: task)
    }
}

private actor URLSessionRealtimeSocket: RealtimeSocket {
    private let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func start() {
        task.resume()
    }

    func send(_ data: Data) async throws {
        guard data.count <= 1_048_576,
              let text = String(data: data, encoding: .utf8) else {
            throw RealtimeWebSocketTransportError.invalidCommand
        }
        try await task.send(.string(text))
    }

    func receive() async throws -> Data {
        let message = try await task.receive()
        let data: Data
        switch message {
        case .data(let payload):
            data = payload
        case .string(let text):
            data = Data(text.utf8)
        @unknown default:
            throw RealtimeWebSocketTransportError.receiveFailed
        }
        guard data.count <= 1_048_576 else {
            throw RealtimeWebSocketTransportError.receiveFailed
        }
        return data
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
    }
}

actor RealtimeWebSocketTransport {
    typealias EventHandler = @Sendable (RealtimeServerEvent) async -> Void

    private let socketFactory: any RealtimeSocketCreating
    private let endpoint: URL
    private let diagnostics: ProbeDiagnostics
    private let handshakeTimeout: Duration

    private var socket: (any RealtimeSocket)?
    private var receiveTask: Task<Void, Never>?
    private var eventHandler: EventHandler?
    private var expectedConfigurationHash: String?
    private var generation: UInt64 = 0
    private var deduplicator = ProviderEventDeduplicator()

    private(set) var state: RealtimeWebSocketTransportState = .idle

    init(
        socketFactory: any RealtimeSocketCreating = URLSessionRealtimeSocketFactory(),
        endpoint: URL = ProbeConfiguration.realtimeWebSocketURL,
        diagnostics: ProbeDiagnostics = ProbeDiagnostics(),
        handshakeTimeout: Duration = .seconds(8)
    ) {
        self.socketFactory = socketFactory
        self.endpoint = endpoint
        self.diagnostics = diagnostics
        self.handshakeTimeout = handshakeTimeout
    }

    func connect(
        clientSecret: RealtimeClientSecret,
        onEvent: @escaping EventHandler
    ) async throws {
        guard state != .connecting, state != .connected else {
            throw RealtimeWebSocketTransportError.alreadyConnected
        }
        guard !clientSecret.value.isEmpty,
              clientSecret.expectedConfigurationHash.range(
                of: #"^[a-f0-9]{64}$"#,
                options: .regularExpression
              ) != nil else {
            throw RealtimeWebSocketTransportError.invalidClientSecret
        }

        state = .connecting
        generation &+= 1
        let connectionGeneration = generation

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 12
        )
        request.setValue("Bearer \(clientSecret.value)", forHTTPHeaderField: "Authorization")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let candidate = socketFactory.makeSocket(request: request)
        await candidate.start()

        do {
            let firstData = try await receiveFirstMessage(from: candidate)
            let firstEvent = try await verifiedInboundEvent(
                firstData,
                expectedHash: clientSecret.expectedConfigurationHash,
                requireSessionCreated: true
            )
            guard connectionGeneration == generation else {
                throw RealtimeWebSocketTransportError.disconnected
            }

            socket = candidate
            eventHandler = onEvent
            expectedConfigurationHash = clientSecret.expectedConfigurationHash
            deduplicator = ProviderEventDeduplicator()
            _ = deduplicator.accept(eventID: eventID(of: firstEvent))
            state = .connected
            await diagnostics.record(
                .lifecycle,
                details: ["state": "connected", "transport": "websocket"]
            )
            await onEvent(firstEvent)

            receiveTask = Task { [weak self] in
                await self?.receiveLoop(
                    socket: candidate,
                    connectionGeneration: connectionGeneration
                )
            }
        } catch {
            await candidate.close()
            guard connectionGeneration == generation else {
                throw RealtimeWebSocketTransportError.disconnected
            }
            state = .failed
            await diagnostics.record(
                .error,
                details: ["stage": "handshake", "category": "connection_failed"]
            )
            if let transportError = error as? RealtimeWebSocketTransportError {
                throw transportError
            }
            throw RealtimeWebSocketTransportError.handshakeFailed
        }
    }

    func send(_ command: Data) async throws {
        guard state == .connected, let socket else {
            throw RealtimeWebSocketTransportError.disconnected
        }
        guard command.count <= 1_048_576,
              let commandType = ProviderEventRedactor.eventType(from: command) else {
            throw RealtimeWebSocketTransportError.invalidCommand
        }

        do {
            try await socket.send(command)
            await diagnostics.record(
                .providerEvent,
                details: ["direction": "sent", "type": commandType]
            )
        } catch {
            await failCurrentConnection(category: "send_failed")
            throw RealtimeWebSocketTransportError.sendFailed
        }
    }

    func disconnect() async {
        generation &+= 1
        receiveTask?.cancel()
        receiveTask = nil
        if let socket {
            await socket.close()
        }
        socket = nil
        eventHandler = nil
        expectedConfigurationHash = nil
        deduplicator = ProviderEventDeduplicator()
        state = .idle
        await diagnostics.record(
            .lifecycle,
            details: ["state": "disconnected", "transport": "websocket"]
        )
    }

    private func receiveFirstMessage(from socket: any RealtimeSocket) async throws -> Data {
        let timeout = handshakeTimeout
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await socket.receive()
            }
            group.addTask {
                try await ContinuousClock().sleep(for: timeout)
                await socket.close()
                throw RealtimeWebSocketTransportError.handshakeTimedOut
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw RealtimeWebSocketTransportError.handshakeFailed
            }
            return first
        }
    }

    private func receiveLoop(
        socket: any RealtimeSocket,
        connectionGeneration: UInt64
    ) async {
        while !Task.isCancelled, connectionGeneration == generation {
            do {
                let data = try await socket.receive()
                guard !Task.isCancelled, connectionGeneration == generation else { return }
                let event = try await verifiedInboundEvent(
                    data,
                    expectedHash: expectedConfigurationHash,
                    requireSessionCreated: false
                )
                guard deduplicator.accept(eventID: eventID(of: event)) else {
                    await diagnostics.record(
                        .providerEvent,
                        details: ["disposition": "duplicate_rejected"]
                    )
                    continue
                }
                if let eventHandler {
                    await eventHandler(event)
                }
            } catch is CancellationError {
                return
            } catch {
                guard connectionGeneration == generation else { return }
                await failCurrentConnection(category: "receive_failed")
                return
            }
        }
    }

    private func verifiedInboundEvent(
        _ data: Data,
        expectedHash: String?,
        requireSessionCreated: Bool
    ) async throws -> RealtimeServerEvent {
        await diagnostics.recordProviderEvent(data)
        let event: RealtimeServerEvent
        do {
            event = try RealtimeServerEventParser.parse(data)
        } catch {
            throw RealtimeWebSocketTransportError.receiveFailed
        }

        if requireSessionCreated {
            guard case .sessionConfiguration(let type, _, _) = event,
                  type == "session.created" else {
                throw RealtimeWebSocketTransportError.invalidHandshake
            }
        }

        if case .sessionConfiguration(_, _, let rawEvent) = event {
            guard let expectedHash else {
                throw RealtimeWebSocketTransportError.invalidHandshake
            }
            let verification: RealtimePolicyVerification
            do {
                verification = try RealtimePolicyVerifier.verify(
                    eventData: rawEvent,
                    expectedHash: expectedHash
                )
            } catch {
                throw RealtimeWebSocketTransportError.invalidHandshake
            }
            guard verification.matches else {
                throw RealtimeWebSocketTransportError.configurationMismatch
            }
        }
        return event
    }

    private func failCurrentConnection(category: String) async {
        receiveTask?.cancel()
        receiveTask = nil
        if let socket {
            await socket.close()
        }
        socket = nil
        eventHandler = nil
        expectedConfigurationHash = nil
        state = .failed
        await diagnostics.record(
            .error,
            details: ["stage": "transport", "category": category]
        )
    }

    private func eventID(of event: RealtimeServerEvent) -> String? {
        switch event {
        case .sessionConfiguration(_, let eventID, _): eventID
        case .outputAudio(let chunk): chunk.eventID
        case .inputSpeechStarted(let eventID, _, _): eventID
        case .inputSpeechStopped(let eventID, _, _): eventID
        case .responseStarted(let eventID, _): eventID
        case .responseFinished(let eventID, _, _): eventID
        case .outputItemAdded(let eventID, _, _): eventID
        case .outputItemFinished(let eventID, _, _): eventID
        case .providerError(let error): error.eventID
        case .ignored(_, let eventID): eventID
        }
    }
}
