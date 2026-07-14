import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Realtime server events")
struct RealtimeServerEventTests {
    @Test("Audio deltas decode PCM and retain only control identifiers")
    func outputAudioDelta() throws {
        let pcm = Data([1, 0, 2, 0])
        let event = Data(
            #"{"type":"response.output_audio.delta","event_id":"evt_1","response_id":"resp_1","item_id":"item_1","output_index":0,"content_index":1,"delta":"AQACAA=="}"#.utf8
        )

        let parsed = try RealtimeServerEventParser.parse(event)

        #expect(
            parsed == .outputAudio(
                RealtimeOutputAudioChunk(
                    eventID: "evt_1",
                    responseID: "resp_1",
                    itemID: "item_1",
                    outputIndex: 0,
                    contentIndex: 1,
                    pcm16Data: pcm
                )
            )
        )
    }

    @Test("Malformed or odd-byte audio deltas fail closed")
    func invalidAudioDelta() {
        for delta in ["not-base64", "AQ=="] {
            let data = Data(
                "{\"type\":\"response.output_audio.delta\",\"delta\":\"\(delta)\"}".utf8
            )
            #expect(throws: RealtimeServerEventParserError.invalidAudioDelta) {
                try RealtimeServerEventParser.parse(data)
            }
        }
    }

    @Test("Decoded tutor chunks over one second fail closed")
    func oversizedDecodedAudioDelta() {
        let delta = Data(repeating: 0, count: 48_002).base64EncodedString()
        let data = Data(
            """
            {"type":"response.output_audio.delta","event_id":"evt_oversized","response_id":"resp_1","item_id":"item_1","output_index":0,"content_index":0,"delta":"\(delta)"}
            """.utf8
        )

        #expect(throws: RealtimeServerEventParserError.invalidAudioDelta) {
            try RealtimeServerEventParser.parse(data)
        }
    }

    @Test("Provider errors discard private human-readable messages")
    func providerErrorIsSanitized() throws {
        let data = Data(
            #"{"type":"error","event_id":"evt_2","error":{"code":"bad_request","type":"invalid_request_error","message":"private provider detail"}}"#.utf8
        )

        let parsed = try RealtimeServerEventParser.parse(data)

        #expect(
            parsed == .providerError(
                RealtimeProviderError(
                    eventID: "evt_2",
                    code: "bad_request",
                    type: "invalid_request_error"
                )
            )
        )
        #expect(!String(describing: parsed).contains("private provider detail"))
    }

    @Test("Duplicate event IDs are rejected within a bounded window")
    func deduplication() {
        var deduplicator = ProviderEventDeduplicator(capacity: 2)

        let first = deduplicator.accept(eventID: "one")
        let duplicate = deduplicator.accept(eventID: "one")
        let second = deduplicator.accept(eventID: "two")
        let third = deduplicator.accept(eventID: "three")
        let evicted = deduplicator.accept(eventID: "one")
        let missing = deduplicator.accept(eventID: nil)

        #expect(first)
        #expect(!duplicate)
        #expect(second)
        #expect(third)
        #expect(evicted)
        #expect(missing)
    }
}
