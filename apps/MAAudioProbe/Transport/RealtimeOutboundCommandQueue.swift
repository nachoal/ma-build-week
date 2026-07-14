import Foundation

actor RealtimeOutboundCommandQueue {
    private struct Batch {
        let commands: [Data]
        let continuation: CheckedContinuation<Void, Error>
    }

    private let transport: RealtimeWebSocketTransport
    private var batches: [Batch] = []
    private var isDraining = false

    init(transport: RealtimeWebSocketTransport) {
        self.transport = transport
    }

    func send(_ command: Data) async throws {
        try await sendBatch([command])
    }

    func sendBatch(_ commands: [Data]) async throws {
        guard !commands.isEmpty,
              commands.allSatisfy({ !$0.isEmpty && $0.count <= 1_048_576 }) else {
            throw RealtimeWebSocketTransportError.invalidCommand
        }

        try await withCheckedThrowingContinuation { continuation in
            batches.append(Batch(commands: commands, continuation: continuation))
            startDrainIfNeeded()
        }
    }

    private func startDrainIfNeeded() {
        guard !isDraining else { return }
        isDraining = true
        Task { await drain() }
    }

    private func drain() async {
        while !batches.isEmpty {
            let batch = batches.removeFirst()
            do {
                for command in batch.commands {
                    try await transport.send(command)
                }
                batch.continuation.resume()
            } catch {
                batch.continuation.resume(throwing: error)
            }
        }
        isDraining = false
    }
}
