import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Probe diagnostics")
struct ProbeDiagnosticsTests {
    @Test("Provider events retain control identifiers but remove media and text")
    func providerRedaction() {
        let source = Data(
            #"{"type":"response.output_audio.delta","event_id":"evt_1","item_id":"item_1","delta":"private-base64","transcript":"private words","response":{"id":"resp_1","output":[{"content":"private"}]},"session":{"model":"gpt-realtime-2.1","instructions":"private prompt"}}"#.utf8
        )

        let redacted = ProviderEventRedactor.redactedJSONString(from: source)

        #expect(redacted.contains("response.output_audio.delta"))
        #expect(redacted.contains("evt_1"))
        #expect(redacted.contains("item_1"))
        #expect(redacted.contains("resp_1"))
        #expect(redacted.contains("gpt-realtime-2.1"))
        #expect(!redacted.contains("private-base64"))
        #expect(!redacted.contains("private words"))
        #expect(!redacted.contains("private prompt"))
    }

    @Test("Event storage is ordered, bounded, and reports drops")
    func boundedStorage() async {
        let diagnostics = ProbeDiagnostics(capacity: 2)
        await diagnostics.record(.lifecycle, details: ["state": "one"])
        await diagnostics.record(.lifecycle, details: ["state": "two"])
        await diagnostics.record(.lifecycle, details: ["state": "three"])

        let snapshot = await diagnostics.snapshot()

        #expect(snapshot.events.map(\.sequence) == [1, 2])
        #expect(snapshot.events.map { $0.details["state"] } == ["two", "three"])
        #expect(snapshot.events[1].monotonicNanoseconds >= snapshot.events[0].monotonicNanoseconds)
        #expect(snapshot.droppedEventCount == 1)
    }

    @Test("Free-form diagnostic details redact sensitive key classes")
    func detailRedaction() async {
        let diagnostics = ProbeDiagnostics(capacity: 1)
        await diagnostics.record(
            .configuration,
            details: [
                "transport": "websocket",
                "client_secret": "must-not-survive",
                "audio_delta": "must-not-survive",
            ]
        )

        let event = await diagnostics.snapshot().events[0]

        #expect(event.details["transport"] == "websocket")
        #expect(event.details["client_secret"] == "<redacted>")
        #expect(event.details["audio_delta"] == "<redacted>")
    }
}
