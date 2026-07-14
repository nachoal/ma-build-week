import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Realtime WebSocket transport")
struct RealtimeWebSocketTransportTests {
    private let expectedHash = "c21f6f941eea87222619b915285fb965eae52b1529948dc31585dd6061b857d6"

    @Test("Handshake verifies policy before exposing the connection")
    func verifiedHandshake() async throws {
        let socket = MockRealtimeSocket(inbound: [try sessionEvent()])
        let factory = MockRealtimeSocketFactory(socket: socket)
        let collector = RealtimeEventCollector()
        let transport = RealtimeWebSocketTransport(
            socketFactory: factory,
            endpoint: URL(string: "wss://realtime.example.test/v1")!
        )

        try await transport.connect(clientSecret: clientSecret) { event in
            await collector.record(event)
        }

        #expect(await transport.state == .connected)
        #expect(await collector.count == 1)
        let request = try #require(factory.request)
        #expect(request.url?.host == "realtime.example.test")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer ephemeral-test")

        let command = try RealtimeClientCommand.createResponse(eventID: "evt_create")
        try await transport.send(command)
        #expect(await socket.sent == [command])

        await transport.disconnect()
        #expect(await transport.state == .idle)
        #expect(await socket.isClosed)
    }

    @Test("A mismatched effective policy fails closed")
    func policyMismatch() async throws {
        var object = try #require(
            JSONSerialization.jsonObject(with: sessionEvent()) as? [String: Any]
        )
        var session = try #require(object["session"] as? [String: Any])
        session["model"] = "different-model"
        object["session"] = session
        let socket = MockRealtimeSocket(
            inbound: [try JSONSerialization.data(withJSONObject: object)]
        )
        let transport = RealtimeWebSocketTransport(
            socketFactory: MockRealtimeSocketFactory(socket: socket),
            endpoint: URL(string: "wss://realtime.example.test/v1")!
        )

        await #expect(throws: RealtimeWebSocketTransportError.configurationMismatch) {
            try await transport.connect(clientSecret: clientSecret) { _ in }
        }

        #expect(await transport.state == .failed)
        #expect(await socket.isClosed)
    }

    @Test("The first provider event must be session.created")
    func rejectsInvalidFirstEvent() async {
        let socket = MockRealtimeSocket(
            inbound: [Data(#"{"type":"response.created","event_id":"evt_1"}"#.utf8)]
        )
        let transport = RealtimeWebSocketTransport(
            socketFactory: MockRealtimeSocketFactory(socket: socket),
            endpoint: URL(string: "wss://realtime.example.test/v1")!
        )

        await #expect(throws: RealtimeWebSocketTransportError.invalidHandshake) {
            try await transport.connect(clientSecret: clientSecret) { _ in }
        }
        #expect(await socket.isClosed)
    }

    @Test("Disconnect during handshake cannot resurrect a stale connection")
    func disconnectDuringHandshake() async throws {
        let socket = MockRealtimeSocket(inbound: [])
        let transport = RealtimeWebSocketTransport(
            socketFactory: MockRealtimeSocketFactory(socket: socket),
            endpoint: URL(string: "wss://realtime.example.test/v1")!
        )
        let connectTask = Task {
            try await transport.connect(clientSecret: clientSecret) { _ in }
        }

        await socket.waitUntilReceiveStarts()
        await transport.disconnect()
        await socket.enqueue(try sessionEvent())

        await #expect(throws: RealtimeWebSocketTransportError.disconnected) {
            try await connectTask.value
        }
        #expect(await transport.state == .idle)
        #expect(await socket.isClosed)
    }

    private var clientSecret: RealtimeClientSecret {
        RealtimeClientSecret(
            value: "ephemeral-test",
            expiresAt: 2_000_000_120,
            expectedConfigurationHash: expectedHash
        )
    }

    private func sessionEvent() throws -> Data {
        let encoder = JSONEncoder()
        let policyData = try encoder.encode(FixedRealtimeSessionPolicy.expected)
        let policy = try JSONSerialization.jsonObject(with: policyData)
        return try JSONSerialization.data(
            withJSONObject: [
                "type": "session.created",
                "event_id": "evt_session",
                "session": policy,
            ]
        )
    }
}

private final class MockRealtimeSocketFactory: RealtimeSocketCreating, @unchecked Sendable {
    private let lock = NSLock()
    private let socket: MockRealtimeSocket
    private var storedRequest: URLRequest?

    init(socket: MockRealtimeSocket) {
        self.socket = socket
    }

    var request: URLRequest? {
        lock.withLock { storedRequest }
    }

    func makeSocket(request: URLRequest) -> any RealtimeSocket {
        lock.withLock { storedRequest = request }
        return socket
    }
}

private actor MockRealtimeSocket: RealtimeSocket {
    enum MockError: Error { case closed }

    private var inbound: [Data]
    private var waiters: [CheckedContinuation<Data, Error>] = []
    private var receiveStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var receiveStarted = false
    private(set) var sent: [Data] = []
    private(set) var isClosed = false

    init(inbound: [Data]) {
        self.inbound = inbound
    }

    func start() {}

    func send(_ data: Data) throws {
        guard !isClosed else { throw MockError.closed }
        sent.append(data)
    }

    func receive() async throws -> Data {
        guard !isClosed else { throw MockError.closed }
        receiveStarted = true
        let startWaiters = receiveStartWaiters
        receiveStartWaiters.removeAll()
        for continuation in startWaiters {
            continuation.resume()
        }
        if !inbound.isEmpty {
            return inbound.removeFirst()
        }
        return try await withCheckedThrowingContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func waitUntilReceiveStarts() async {
        guard !receiveStarted else { return }
        await withCheckedContinuation { continuation in
            receiveStartWaiters.append(continuation)
        }
    }

    func enqueue(_ data: Data) {
        if !waiters.isEmpty {
            waiters.removeFirst().resume(returning: data)
        } else {
            inbound.append(data)
        }
    }

    func close() {
        guard !isClosed else { return }
        isClosed = true
        let continuations = waiters
        waiters.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: MockError.closed)
        }
    }
}

private actor RealtimeEventCollector {
    private(set) var count = 0

    func record(_ event: RealtimeServerEvent) {
        count += 1
    }
}
