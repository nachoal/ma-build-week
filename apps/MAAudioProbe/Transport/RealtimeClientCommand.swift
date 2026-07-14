import Foundation

enum RealtimeClientCommandError: Error, Equatable {
    case invalidEventID
    case invalidAudio
    case invalidIdentifier
    case invalidContentIndex
    case invalidAudioEnd
    case encodingFailed
}

enum RealtimeClientCommand {
    static func appendInputAudio(_ pcm16Data: Data, eventID: String) throws -> Data {
        guard !pcm16Data.isEmpty,
              pcm16Data.count <= 48_000,
              pcm16Data.count.isMultiple(of: MemoryLayout<Int16>.size) else {
            throw RealtimeClientCommandError.invalidAudio
        }
        return try encode(
            [
                "type": "input_audio_buffer.append",
                "event_id": try validatedEventID(eventID),
                "audio": pcm16Data.base64EncodedString(),
            ]
        )
    }

    static func clearInput(eventID: String) throws -> Data {
        try encode(
            [
                "type": "input_audio_buffer.clear",
                "event_id": try validatedEventID(eventID),
            ]
        )
    }

    static func commitInput(eventID: String) throws -> Data {
        try encode(
            [
                "type": "input_audio_buffer.commit",
                "event_id": try validatedEventID(eventID),
            ]
        )
    }

    static func createResponse(eventID: String) throws -> Data {
        try encode(
            [
                "type": "response.create",
                "event_id": try validatedEventID(eventID),
            ]
        )
    }

    static func cancelResponse(responseID: String?, eventID: String) throws -> Data {
        var object: [String: Any] = [
            "type": "response.cancel",
            "event_id": try validatedEventID(eventID),
        ]
        if let responseID {
            object["response_id"] = try validatedIdentifier(responseID)
        }
        return try encode(object)
    }

    static func truncateItem(
        itemID: String,
        contentIndex: Int,
        audioEndMilliseconds: Int,
        eventID: String
    ) throws -> Data {
        guard contentIndex >= 0 else {
            throw RealtimeClientCommandError.invalidContentIndex
        }
        guard audioEndMilliseconds >= 0 else {
            throw RealtimeClientCommandError.invalidAudioEnd
        }
        return try encode(
            [
                "type": "conversation.item.truncate",
                "event_id": try validatedEventID(eventID),
                "item_id": try validatedIdentifier(itemID),
                "content_index": contentIndex,
                "audio_end_ms": audioEndMilliseconds,
            ]
        )
    }

    private static func validatedEventID(_ value: String) throws -> String {
        guard value.count >= 3, value.count <= 128 else {
            throw RealtimeClientCommandError.invalidEventID
        }
        return value
    }

    private static func validatedIdentifier(_ value: String) throws -> String {
        guard !value.isEmpty, value.count <= 256 else {
            throw RealtimeClientCommandError.invalidIdentifier
        }
        return value
    }

    private static func encode(_ object: [String: Any]) throws -> Data {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(
                withJSONObject: object,
                options: [.sortedKeys, .withoutEscapingSlashes]
              ) else {
            throw RealtimeClientCommandError.encodingFailed
        }
        return data
    }
}
