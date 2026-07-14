import Foundation

struct GuidedRealtimeOutputAudioChunk: Sendable, Equatable {
    let eventID: String
    let responseID: String
    let itemID: String
    let outputIndex: Int
    let contentIndex: Int
    let pcm16Data: Data
}

struct GuidedRealtimeFunctionCall: Sendable, Equatable {
    let eventID: String
    let responseID: String
    let itemID: String
    let outputIndex: Int
    let callID: String
    let name: String
    let arguments: String
}

enum GuidedRealtimeServerEvent: Sendable, Equatable {
    case sessionConfiguration(eventID: String?, rawEvent: Data)
    case inputCommitted(eventID: String?, itemID: String)
    case inputTranscript(eventID: String?, itemID: String, transcript: String)
    case inputTranscriptFailed(eventID: String?, itemID: String)
    case outputAudio(GuidedRealtimeOutputAudioChunk)
    case outputAudioFinished(eventID: String?, responseID: String, itemID: String)
    case outputTranscript(
        eventID: String?, responseID: String, itemID: String, transcript: String
    )
    case functionCall(GuidedRealtimeFunctionCall)
    case responseStarted(eventID: String?, responseID: String)
    case responseFinished(
        eventID: String?,
        responseID: String,
        status: String,
        incompleteReason: String?
    )
    case providerError(eventID: String?, code: String?)
    case transportFailed
    case ignored(type: String, eventID: String?)

    var eventID: String? {
        switch self {
        case .sessionConfiguration(let eventID, _),
             .inputCommitted(let eventID, _),
             .inputTranscript(let eventID, _, _),
             .inputTranscriptFailed(let eventID, _),
             .outputAudioFinished(let eventID, _, _),
             .outputTranscript(let eventID, _, _, _),
             .responseStarted(let eventID, _),
             .responseFinished(let eventID, _, _, _),
             .providerError(let eventID, _),
             .ignored(_, let eventID):
            eventID
        case .outputAudio(let chunk):
            chunk.eventID
        case .functionCall(let call):
            call.eventID
        case .transportFailed:
            nil
        }
    }
}

enum GuidedRealtimeServerEventParser {
    static func parse(_ data: Data) throws -> GuidedRealtimeServerEvent {
        guard !data.isEmpty, data.count <= 1_048_576 else {
            throw GuidedRealtimeError.providerRejected
        }
        guard let value = try? JSONSerialization.jsonObject(with: data),
              let event = value as? [String: Any],
              let type = boundedIdentifier(event["type"], maximum: 128) else {
            throw GuidedRealtimeError.providerRejected
        }
        let eventID = optionalIdentifier(event["event_id"], maximum: 512)

        switch type {
        case "session.created", "session.updated":
            return .sessionConfiguration(eventID: eventID, rawEvent: data)

        case "input_audio_buffer.committed":
            guard let itemID = boundedIdentifier(event["item_id"], maximum: 256) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .inputCommitted(eventID: eventID, itemID: itemID)

        case "conversation.item.input_audio_transcription.completed":
            guard let itemID = boundedIdentifier(event["item_id"], maximum: 256),
                  let transcript = boundedText(event["transcript"], maximum: 512) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .inputTranscript(
                eventID: eventID,
                itemID: itemID,
                transcript: transcript
            )

        case "conversation.item.input_audio_transcription.failed":
            guard let itemID = boundedIdentifier(event["item_id"], maximum: 256) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .inputTranscriptFailed(eventID: eventID, itemID: itemID)

        case "response.output_audio.delta":
            guard let eventID,
                  let responseID = boundedIdentifier(event["response_id"], maximum: 256),
                  let itemID = boundedIdentifier(event["item_id"], maximum: 256),
                  let outputIndex = nonnegativeInteger(event["output_index"]),
                  let contentIndex = nonnegativeInteger(event["content_index"]),
                  let encoded = event["delta"] as? String,
                  encoded.utf8.count <= 64_000,
                  let audio = Data(base64Encoded: encoded),
                  !audio.isEmpty,
                  audio.count <= 48_000,
                  audio.count.isMultiple(of: MemoryLayout<Int16>.size) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .outputAudio(
                GuidedRealtimeOutputAudioChunk(
                    eventID: eventID,
                    responseID: responseID,
                    itemID: itemID,
                    outputIndex: outputIndex,
                    contentIndex: contentIndex,
                    pcm16Data: audio
                )
            )

        case "response.output_audio.done":
            guard let responseID = boundedIdentifier(event["response_id"], maximum: 256),
                  let itemID = boundedIdentifier(event["item_id"], maximum: 256) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .outputAudioFinished(
                eventID: eventID,
                responseID: responseID,
                itemID: itemID
            )

        case "response.output_audio_transcript.done":
            guard let responseID = boundedIdentifier(event["response_id"], maximum: 256),
                  let itemID = boundedIdentifier(event["item_id"], maximum: 256),
                  let transcript = boundedText(event["transcript"], maximum: 1_024) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .outputTranscript(
                eventID: eventID,
                responseID: responseID,
                itemID: itemID,
                transcript: transcript
            )

        case "response.function_call_arguments.done":
            guard let eventID,
                  let responseID = boundedIdentifier(event["response_id"], maximum: 256),
                  let itemID = boundedIdentifier(event["item_id"], maximum: 256),
                  let outputIndex = nonnegativeInteger(event["output_index"]),
                  let callID = boundedIdentifier(event["call_id"], maximum: 256),
                  let name = boundedIdentifier(event["name"], maximum: 128),
                  let arguments = boundedText(event["arguments"], maximum: 4_096) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .functionCall(
                GuidedRealtimeFunctionCall(
                    eventID: eventID,
                    responseID: responseID,
                    itemID: itemID,
                    outputIndex: outputIndex,
                    callID: callID,
                    name: name,
                    arguments: arguments
                )
            )

        case "response.created":
            let response = event["response"] as? [String: Any]
            guard let responseID = boundedIdentifier(response?["id"], maximum: 256) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .responseStarted(eventID: eventID, responseID: responseID)

        case "response.done":
            let response = event["response"] as? [String: Any]
            let statusDetails = response?["status_details"] as? [String: Any]
            guard let responseID = boundedIdentifier(response?["id"], maximum: 256),
                  let status = boundedIdentifier(response?["status"], maximum: 32) else {
                throw GuidedRealtimeError.providerRejected
            }
            return .responseFinished(
                eventID: eventID,
                responseID: responseID,
                status: status,
                incompleteReason: optionalIdentifier(
                    statusDetails?["reason"],
                    maximum: 64
                )
            )

        case "error":
            let error = event["error"] as? [String: Any]
            return .providerError(
                eventID: eventID,
                code: optionalIdentifier(error?["code"], maximum: 128)
            )

        default:
            return .ignored(type: type, eventID: eventID)
        }
    }

    private static func boundedIdentifier(_ value: Any?, maximum: Int) -> String? {
        guard let string = value as? String,
              !string.isEmpty,
              string.count <= maximum,
              string.unicodeScalars.allSatisfy({ $0.value >= 0x21 && $0.value <= 0x7E }) else {
            return nil
        }
        return string
    }

    private static func optionalIdentifier(_ value: Any?, maximum: Int) -> String? {
        guard value != nil else { return nil }
        return boundedIdentifier(value, maximum: maximum)
    }

    private static func boundedText(_ value: Any?, maximum: Int) -> String? {
        guard let raw = value as? String else { return nil }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              text.count <= maximum,
              text.unicodeScalars.allSatisfy({ scalar in
                  scalar.value == 0x0A || scalar.value >= 0x20
              }) else { return nil }
        return text
    }

    private static func nonnegativeInteger(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber else { return nil }
        let integer = number.intValue
        guard integer >= 0, NSNumber(value: integer) == number else { return nil }
        return integer
    }
}

struct GuidedProviderEventDeduplicator: Sendable {
    private let capacity: Int
    private var ordered: [String] = []
    private var identifiers: Set<String> = []

    init(capacity: Int = 4_096) {
        self.capacity = max(1, min(capacity, 4_096))
        ordered.reserveCapacity(self.capacity)
    }

    mutating func accept(_ eventID: String?) -> Bool {
        guard let eventID else { return true }
        guard identifiers.insert(eventID).inserted else { return false }
        ordered.append(eventID)
        if ordered.count > capacity {
            identifiers.remove(ordered.removeFirst())
        }
        return true
    }
}
