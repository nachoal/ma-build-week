import Foundation
import OSLog

enum GuidedRealtimeTransportState: Sendable, Equatable {
    case idle
    case connecting
    case connected
    case failed
}

protocol GuidedRealtimeTransporting: Sendable {
    func connect(
        clientSecret: GuidedRealtimeClientSecret,
        onEvent: @escaping @Sendable (GuidedRealtimeServerEvent) async -> Void
    ) async throws
    func send(_ command: Data) async throws
    func connectionState() async -> GuidedRealtimeTransportState
    func disconnect() async
}

protocol GuidedRealtimeSocket: Sendable {
    func start() async
    func send(_ data: Data) async throws
    func receive() async throws -> Data
    func close() async
}

protocol GuidedRealtimeSocketCreating: Sendable {
    func makeSocket(request: URLRequest) -> any GuidedRealtimeSocket
}

enum GuidedRealtimeOutboundPolicy {
    private static let allowedTypes: Set<String> = [
        "input_audio_buffer.clear",
        "input_audio_buffer.append",
        "input_audio_buffer.commit",
        "conversation.item.create",
        "response.create",
    ]

    static func validate(_ command: Data) throws {
        guard !command.isEmpty,
              command.count <= 1_048_576,
              let value = try? JSONSerialization.jsonObject(with: command),
              let object = value as? [String: Any],
              let type = object["type"] as? String,
              allowedTypes.contains(type) else {
            throw GuidedRealtimeError.providerRejected
        }

        guard type == "response.create" else { return }
        guard let response = object["response"] as? [String: Any] else {
            throw GuidedRealtimeError.providerRejected
        }
        guard let reasoningValue = response["reasoning"] else { return }
        guard let reasoning = reasoningValue as? [String: Any],
              Set(reasoning.keys) == Set(["effort"]),
              reasoning["effort"] as? String == "low" else {
            throw GuidedRealtimeError.providerRejected
        }
    }
}

struct GuidedURLSessionRealtimeSocketFactory: GuidedRealtimeSocketCreating {
    private let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func makeSocket(request: URLRequest) -> any GuidedRealtimeSocket {
        let task = session.webSocketTask(with: request)
        task.maximumMessageSize = 1_048_576
        return GuidedURLSessionRealtimeSocket(task: task)
    }
}

private actor GuidedURLSessionRealtimeSocket: GuidedRealtimeSocket {
    private let task: URLSessionWebSocketTask
    private let diagnosticLogger = Logger(
        subsystem: "com.ia.ma",
        category: "GuidedRealtimeTransport"
    )

    init(task: URLSessionWebSocketTask) {
        self.task = task
    }

    func start() {
        task.resume()
    }

    func send(_ data: Data) async throws {
        guard data.count <= 1_048_576,
              let text = String(data: data, encoding: .utf8) else {
            throw GuidedRealtimeError.providerRejected
        }
        try await task.send(.string(text))
    }

    func receive() async throws -> Data {
        let message: URLSessionWebSocketTask.Message
        do {
            message = try await task.receive()
        } catch {
            let nsError = error as NSError
            diagnosticLogger.error(
                "receive_failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            throw error
        }
        let data: Data
        switch message {
        case .data(let value):
            data = value
        case .string(let value):
            data = Data(value.utf8)
        @unknown default:
            throw GuidedRealtimeError.providerRejected
        }
        guard !data.isEmpty, data.count <= 1_048_576 else {
            throw GuidedRealtimeError.providerRejected
        }
        return data
    }

    func close() {
        task.cancel(with: .goingAway, reason: nil)
    }
}

actor GuidedRealtimeWebSocketTransport: GuidedRealtimeTransporting {
    static let endpoint = URL(
        string: "wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1"
    )!

    private let socketFactory: any GuidedRealtimeSocketCreating
    private let endpoint: URL
    private let handshakeTimeout: Duration
    private let diagnosticLogger = Logger(
        subsystem: "com.ia.ma",
        category: "GuidedRealtimeTransport"
    )

    private var socket: (any GuidedRealtimeSocket)?
    private var receiveTask: Task<Void, Never>?
    private var eventHandler: (@Sendable (GuidedRealtimeServerEvent) async -> Void)?
    private var generation: UInt64 = 0
    private var deduplicator = GuidedProviderEventDeduplicator()
    private(set) var state: GuidedRealtimeTransportState = .idle

    init(
        socketFactory: any GuidedRealtimeSocketCreating = GuidedURLSessionRealtimeSocketFactory(),
        endpoint: URL = GuidedRealtimeWebSocketTransport.endpoint,
        handshakeTimeout: Duration = .seconds(8)
    ) {
        self.socketFactory = socketFactory
        self.endpoint = endpoint
        self.handshakeTimeout = handshakeTimeout
    }

    func connect(
        clientSecret: GuidedRealtimeClientSecret,
        onEvent: @escaping @Sendable (GuidedRealtimeServerEvent) async -> Void
    ) async throws {
        guard state != .connecting, state != .connected else { return }
        guard !clientSecret.value.isEmpty,
              clientSecret.value.count <= 2_048,
              clientSecret.expectedConfigurationHash.range(
                  of: #"^[a-f0-9]{64}$"#,
                  options: .regularExpression
              ) != nil else {
            throw GuidedRealtimeError.invalidClientSecret
        }

        state = .connecting
        diagnosticLogger.notice("connect_started")
        generation &+= 1
        let connectionGeneration = generation

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 12
        )
        request.setValue(
            "Bearer \(clientSecret.value)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let candidate = socketFactory.makeSocket(request: request)
        await candidate.start()
        do {
            let firstData = try await receiveFirstMessage(from: candidate)
            diagnosticLogger.notice("first_message_received")
            let firstEvent = try GuidedRealtimeServerEventParser.parse(firstData)
            guard case .sessionConfiguration = firstEvent else {
                throw GuidedRealtimeError.configurationMismatch
            }
            try GuidedRealtimePolicyVerifier.verifySessionCreated(
                firstData,
                expectedHash: clientSecret.expectedConfigurationHash
            )
            guard connectionGeneration == generation else {
                throw GuidedRealtimeError.disconnected
            }

            socket = candidate
            eventHandler = onEvent
            deduplicator = GuidedProviderEventDeduplicator()
            _ = deduplicator.accept(firstEvent.eventID)
            state = .connected
            await onEvent(firstEvent)

            receiveTask = Task { [weak self] in
                await self?.receiveLoop(
                    socket: candidate,
                    generation: connectionGeneration
                )
            }
        } catch {
            let nsError = error as NSError
            diagnosticLogger.error(
                "connect_failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            await candidate.close()
            if connectionGeneration == generation {
                state = .failed
            }
            if let error = error as? GuidedRealtimeError { throw error }
            throw GuidedRealtimeError.connectionFailed
        }
    }

    func send(_ command: Data) async throws {
        guard state == .connected, let socket else {
            throw GuidedRealtimeError.disconnected
        }
        try GuidedRealtimeOutboundPolicy.validate(command)
        do {
            try await socket.send(command)
        } catch {
            await failCurrentConnection(notify: true)
            throw GuidedRealtimeError.disconnected
        }
    }

    func connectionState() async -> GuidedRealtimeTransportState {
        state
    }

    func disconnect() async {
        generation &+= 1
        receiveTask?.cancel()
        receiveTask = nil
        let socketToClose = socket
        socket = nil
        eventHandler = nil
        deduplicator = GuidedProviderEventDeduplicator()
        state = .idle
        // Publish the detached, non-connected state before crossing the
        // socket actor boundary. A close may suspend; reconnect/readiness
        // checks must never observe the old socket as connected meanwhile.
        if let socketToClose { await socketToClose.close() }
    }

    private func receiveFirstMessage(
        from socket: any GuidedRealtimeSocket
    ) async throws -> Data {
        let timeout = handshakeTimeout
        return try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask { try await socket.receive() }
            group.addTask {
                try await ContinuousClock().sleep(for: timeout)
                throw GuidedRealtimeError.responseTimedOut
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw GuidedRealtimeError.connectionFailed
            }
            return first
        }
    }

    private func receiveLoop(
        socket: any GuidedRealtimeSocket,
        generation connectionGeneration: UInt64
    ) async {
        while !Task.isCancelled, connectionGeneration == generation {
            do {
                let data = try await socket.receive()
                guard !Task.isCancelled, connectionGeneration == generation else { return }
                let event = try GuidedRealtimeServerEventParser.parse(data)
                if case .sessionConfiguration = event {
                    throw GuidedRealtimeError.configurationMismatch
                }
                guard deduplicator.accept(event.eventID) else { continue }
                if let handler = eventHandler {
                    await handler(event)
                }
            } catch {
                guard !Task.isCancelled, connectionGeneration == generation else { return }
                await failCurrentConnection(notify: true)
                return
            }
        }
    }

    private func failCurrentConnection(notify: Bool) async {
        generation &+= 1
        receiveTask?.cancel()
        receiveTask = nil
        let socketToClose = socket
        let handler = eventHandler
        socket = nil
        eventHandler = nil
        deduplicator = GuidedProviderEventDeduplicator()
        state = .failed
        // As with explicit disconnect, detach and publish failure before an
        // awaited close. The provider's pre-record readiness check can now
        // reliably reject or reconnect a socket already in teardown.
        if let socketToClose { await socketToClose.close() }
        if notify, let handler {
            await handler(.transportFailed)
        }
    }
}
