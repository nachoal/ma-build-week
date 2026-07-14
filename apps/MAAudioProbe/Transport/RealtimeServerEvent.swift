import Foundation

struct RealtimeOutputAudioChunk: Sendable, Equatable {
    let eventID: String?
    let responseID: String?
    let itemID: String?
    let outputIndex: Int?
    let contentIndex: Int?
    let pcm16Data: Data
}

struct RealtimeProviderError: Sendable, Equatable {
    let eventID: String?
    let code: String?
    let type: String?
}

enum RealtimeServerEvent: Sendable, Equatable {
    case sessionConfiguration(type: String, eventID: String?, rawEvent: Data)
    case outputAudio(RealtimeOutputAudioChunk)
    case inputSpeechStarted(eventID: String?, itemID: String?, audioStartMilliseconds: Int?)
    case inputSpeechStopped(eventID: String?, itemID: String?, audioEndMilliseconds: Int?)
    case responseStarted(eventID: String?, responseID: String?)
    case responseFinished(eventID: String?, responseID: String?, status: String?)
    case outputItemAdded(eventID: String?, responseID: String?, itemID: String?)
    case outputItemFinished(eventID: String?, responseID: String?, itemID: String?)
    case providerError(RealtimeProviderError)
    case ignored(type: String, eventID: String?)
}

enum RealtimeServerEventParserError: Error, Equatable {
    case oversized
    case invalidJSON
    case missingType
    case invalidAudioDelta
}

enum RealtimeServerEventParser {
    static func parse(_ data: Data) throws -> RealtimeServerEvent {
        guard data.count <= 1_048_576 else {
            throw RealtimeServerEventParserError.oversized
        }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let event = object as? [String: Any] else {
            throw RealtimeServerEventParserError.invalidJSON
        }
        guard let type = event["type"] as? String, !type.isEmpty else {
            throw RealtimeServerEventParserError.missingType
        }

        let eventID = event["event_id"] as? String
        let response = event["response"] as? [String: Any]
        let item = event["item"] as? [String: Any]

        switch type {
        case "session.created", "session.updated":
            return .sessionConfiguration(type: type, eventID: eventID, rawEvent: data)
        case "response.output_audio.delta":
            guard let encoded = event["delta"] as? String,
                  let audio = Data(base64Encoded: encoded),
                  !audio.isEmpty,
                  audio.count.isMultiple(of: MemoryLayout<Int16>.size) else {
                throw RealtimeServerEventParserError.invalidAudioDelta
            }
            return .outputAudio(
                RealtimeOutputAudioChunk(
                    eventID: eventID,
                    responseID: event["response_id"] as? String,
                    itemID: event["item_id"] as? String,
                    outputIndex: event["output_index"] as? Int,
                    contentIndex: event["content_index"] as? Int,
                    pcm16Data: audio
                )
            )
        case "input_audio_buffer.speech_started":
            return .inputSpeechStarted(
                eventID: eventID,
                itemID: event["item_id"] as? String,
                audioStartMilliseconds: event["audio_start_ms"] as? Int
            )
        case "input_audio_buffer.speech_stopped":
            return .inputSpeechStopped(
                eventID: eventID,
                itemID: event["item_id"] as? String,
                audioEndMilliseconds: event["audio_end_ms"] as? Int
            )
        case "response.created":
            return .responseStarted(
                eventID: eventID,
                responseID: response?["id"] as? String
            )
        case "response.done":
            return .responseFinished(
                eventID: eventID,
                responseID: response?["id"] as? String,
                status: response?["status"] as? String
            )
        case "response.output_item.added":
            return .outputItemAdded(
                eventID: eventID,
                responseID: event["response_id"] as? String,
                itemID: item?["id"] as? String
            )
        case "response.output_item.done":
            return .outputItemFinished(
                eventID: eventID,
                responseID: event["response_id"] as? String,
                itemID: item?["id"] as? String
            )
        case "error":
            let error = event["error"] as? [String: Any]
            return .providerError(
                RealtimeProviderError(
                    eventID: eventID,
                    code: error?["code"] as? String,
                    type: error?["type"] as? String
                )
            )
        default:
            return .ignored(type: type, eventID: eventID)
        }
    }
}

struct ProviderEventDeduplicator: Sendable {
    private let capacity: Int
    private var orderedEventIDs: [String] = []
    private var eventIDs: Set<String> = []

    init(capacity: Int = 4_096) {
        self.capacity = max(1, capacity)
        orderedEventIDs.reserveCapacity(min(capacity, 4_096))
    }

    mutating func accept(eventID: String?) -> Bool {
        guard let eventID, !eventID.isEmpty else {
            return true
        }
        guard eventIDs.insert(eventID).inserted else {
            return false
        }
        orderedEventIDs.append(eventID)
        if orderedEventIDs.count > capacity {
            let removed = orderedEventIDs.removeFirst()
            eventIDs.remove(removed)
        }
        return true
    }
}
