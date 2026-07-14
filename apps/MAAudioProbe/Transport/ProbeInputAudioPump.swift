import Foundation

actor ProbeInputAudioPump {
    private let outboundQueue: RealtimeOutboundCommandQueue
    private let diagnostics: ProbeDiagnostics
    private var enabled = false
    private var nextEventSequence: UInt64 = 0
    private(set) var sentFrameCount: UInt64 = 0

    init(outboundQueue: RealtimeOutboundCommandQueue, diagnostics: ProbeDiagnostics) {
        self.outboundQueue = outboundQueue
        self.diagnostics = diagnostics
    }

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
    }

    func accept(_ pcm16Data: Data) async {
        guard enabled else { return }
        let eventID = "evt_input_\(nextEventSequence)"
        nextEventSequence &+= 1
        do {
            let command = try RealtimeClientCommand.appendInputAudio(
                pcm16Data,
                eventID: eventID
            )
            try await outboundQueue.send(command)
            sentFrameCount &+= UInt64(pcm16Data.count / MemoryLayout<Int16>.size)
        } catch {
            enabled = false
            await diagnostics.record(
                .error,
                details: ["stage": "input_pump", "category": "send_failed"]
            )
        }
    }

    func reset() {
        enabled = false
        nextEventSequence = 0
        sentFrameCount = 0
    }
}
