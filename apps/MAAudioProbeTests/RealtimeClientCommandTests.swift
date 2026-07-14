import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Realtime client commands")
struct RealtimeClientCommandTests {
    @Test("Input append encodes bounded PCM without changing bytes")
    func appendInputAudio() throws {
        let pcm = Data([0, 0, 255, 127])
        let data = try RealtimeClientCommand.appendInputAudio(pcm, eventID: "evt_append")
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object["type"] as? String == "input_audio_buffer.append")
        #expect(object["event_id"] as? String == "evt_append")
        #expect(Data(base64Encoded: object["audio"] as? String ?? "") == pcm)
    }

    @Test("Truncation carries the render-derived item position")
    func truncateItem() throws {
        let data = try RealtimeClientCommand.truncateItem(
            itemID: "item_1",
            contentIndex: 0,
            audioEndMilliseconds: 2_375,
            eventID: "evt_truncate"
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        #expect(object["type"] as? String == "conversation.item.truncate")
        #expect(object["item_id"] as? String == "item_1")
        #expect(object["content_index"] as? Int == 0)
        #expect(object["audio_end_ms"] as? Int == 2_375)
    }

    @Test("Malformed audio and negative render positions fail closed")
    func invalidCommands() {
        #expect(throws: RealtimeClientCommandError.invalidAudio) {
            try RealtimeClientCommand.appendInputAudio(Data([1]), eventID: "evt_bad")
        }
        #expect(throws: RealtimeClientCommandError.invalidAudioEnd) {
            try RealtimeClientCommand.truncateItem(
                itemID: "item_1",
                contentIndex: 0,
                audioEndMilliseconds: -1,
                eventID: "evt_bad"
            )
        }
    }

    @Test("Response control commands remain explicit and separate")
    func responseCommands() throws {
        let cancel = try RealtimeClientCommand.cancelResponse(
            responseID: "resp_1",
            eventID: "evt_cancel"
        )
        let create = try RealtimeClientCommand.createResponse(eventID: "evt_create")
        let cancelObject = try #require(
            JSONSerialization.jsonObject(with: cancel) as? [String: Any]
        )
        let createObject = try #require(
            JSONSerialization.jsonObject(with: create) as? [String: Any]
        )

        #expect(cancelObject["type"] as? String == "response.cancel")
        #expect(cancelObject["response_id"] as? String == "resp_1")
        #expect(createObject["type"] as? String == "response.create")
        #expect(createObject["response_id"] == nil)
    }
}
