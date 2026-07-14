import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Realtime outbound command queue")
struct RealtimeOutboundCommandQueueTests {
    @Test("Mic appends cannot interleave between cancel and truncate")
    func atomicControlBatch() async throws {
        let socket = SuspendingRealtimeSocket(inbound: [try sessionEvent()])
        let transport = RealtimeWebSocketTransport(
            socketFactory: SuspendingRealtimeSocketFactory(socket: socket),
            endpoint: URL(string: "wss://realtime.example.test/v1")!
        )
        try await transport.connect(clientSecret: clientSecret) { _ in }
        let queue = RealtimeOutboundCommandQueue(transport: transport)

        let cancel = try RealtimeClientCommand.cancelResponse(
            responseID: "resp_1",
            eventID: "evt_cancel"
        )
        let truncate = try RealtimeClientCommand.truncateItem(
            itemID: "item_1",
            contentIndex: 0,
            audioEndMilliseconds: 500,
            eventID: "evt_truncate"
        )
        let append = try RealtimeClientCommand.appendInputAudio(
            Data([0, 0]),
            eventID: "evt_append"
        )

        let controlTask = Task { try await queue.sendBatch([cancel, truncate]) }
        await socket.waitUntilFirstSendSuspends()
        let appendTask = Task { try await queue.send(append) }
        await socket.releaseFirstSend()

        try await controlTask.value
        try await appendTask.value
        let sentTypes = await socket.sent.compactMap(ProviderEventRedactor.eventType)
        #expect(sentTypes == [
            "response.cancel",
            "conversation.item.truncate",
            "input_audio_buffer.append",
        ])
        await transport.disconnect()
    }

    private var clientSecret: RealtimeClientSecret {
        RealtimeClientSecret(
            value: "ephemeral-test",
            expiresAt: 2_000_000_120,
            expectedConfigurationHash: "c21f6f941eea87222619b915285fb965eae52b1529948dc31585dd6061b857d6"
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

private final class SuspendingRealtimeSocketFactory: RealtimeSocketCreating, @unchecked Sendable {
    private let socket: SuspendingRealtimeSocket

    init(socket: SuspendingRealtimeSocket) {
        self.socket = socket
    }

    func makeSocket(request: URLRequest) -> any RealtimeSocket {
        socket
    }
}

private actor SuspendingRealtimeSocket: RealtimeSocket {
    enum MockError: Error { case closed }

    private var inbound: [Data]
    private var firstSendContinuation: CheckedContinuation<Void, Never>?
    private var firstSendStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var receiveWaiters: [CheckedContinuation<Data, Error>] = []
    private var firstSendStarted = false
    private var firstSendReleased = false
    private(set) var sent: [Data] = []
    private var closed = false

    init(inbound: [Data]) {
        self.inbound = inbound
    }

    func start() {}

    func send(_ data: Data) async throws {
        guard !closed else { throw MockError.closed }
        sent.append(data)
        if sent.count == 1, !firstSendReleased {
            firstSendStarted = true
            let waiters = firstSendStartWaiters
            firstSendStartWaiters.removeAll()
            waiters.forEach { $0.resume() }
            await withCheckedContinuation { continuation in
                firstSendContinuation = continuation
            }
        }
    }

    func receive() async throws -> Data {
        guard !closed else { throw MockError.closed }
        if !inbound.isEmpty {
            return inbound.removeFirst()
        }
        return try await withCheckedThrowingContinuation { continuation in
            receiveWaiters.append(continuation)
        }
    }

    func close() {
        closed = true
        let waiters = receiveWaiters
        receiveWaiters.removeAll()
        waiters.forEach { $0.resume(throwing: MockError.closed) }
        releaseFirstSend()
    }

    func waitUntilFirstSendSuspends() async {
        guard !firstSendStarted else { return }
        await withCheckedContinuation { continuation in
            firstSendStartWaiters.append(continuation)
        }
    }

    func releaseFirstSend() {
        firstSendReleased = true
        firstSendContinuation?.resume()
        firstSendContinuation = nil
    }
}
