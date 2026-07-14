import Foundation

enum ProbeDiagnosticKind: String, Codable, Sendable {
    case lifecycle
    case configuration
    case microphoneFrame
    case providerEvent
    case playbackScheduled
    case playbackRendered
    case playbackStopped
    case routeChanged
    case interrupted
    case error
}

struct ProbeDiagnosticEvent: Codable, Sendable, Equatable {
    let sequence: UInt64
    let monotonicNanoseconds: UInt64
    let wallClock: Date
    let kind: ProbeDiagnosticKind
    let details: [String: String]
    let redactedProviderJSON: String?
}

struct ProbeDiagnosticSnapshot: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let generatedAt: Date
    let droppedEventCount: UInt64
    let events: [ProbeDiagnosticEvent]
}

actor ProbeDiagnostics {
    private let origin: ContinuousClock.Instant
    private let capacity: Int
    private var events: [ProbeDiagnosticEvent] = []
    private var nextSequence: UInt64 = 0
    private var droppedEventCount: UInt64 = 0

    init(capacity: Int = 20_000) {
        self.origin = ContinuousClock.now
        self.capacity = max(1, capacity)
        events.reserveCapacity(min(capacity, 20_000))
    }

    func record(
        _ kind: ProbeDiagnosticKind,
        details: [String: String] = [:],
        wallClock: Date = Date()
    ) {
        append(
            kind,
            details: ProbeDiagnosticSanitizer.details(details),
            redactedProviderJSON: nil,
            wallClock: wallClock
        )
    }

    func recordProviderEvent(_ data: Data, wallClock: Date = Date()) {
        let redacted = ProviderEventRedactor.redactedJSONString(from: data)
        let eventType = ProviderEventRedactor.eventType(from: data) ?? "unknown"
        append(
            .providerEvent,
            details: ["type": eventType],
            redactedProviderJSON: redacted,
            wallClock: wallClock
        )
    }

    func snapshot(generatedAt: Date = Date()) -> ProbeDiagnosticSnapshot {
        ProbeDiagnosticSnapshot(
            schemaVersion: 1,
            generatedAt: generatedAt,
            droppedEventCount: droppedEventCount,
            events: events
        )
    }

    func encodedSnapshot(generatedAt: Date = Date()) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(snapshot(generatedAt: generatedAt))
    }

    private func append(
        _ kind: ProbeDiagnosticKind,
        details: [String: String],
        redactedProviderJSON: String?,
        wallClock: Date
    ) {
        if events.count == capacity {
            events.removeFirst()
            droppedEventCount += 1
        }
        let elapsed = origin.duration(to: ContinuousClock.now)
        let components = elapsed.components
        let seconds = UInt64(max(0, components.seconds))
        let nanoseconds = UInt64(max(0, components.attoseconds / 1_000_000_000))
        events.append(
            ProbeDiagnosticEvent(
                sequence: nextSequence,
                monotonicNanoseconds: seconds &* 1_000_000_000 &+ nanoseconds,
                wallClock: wallClock,
                kind: kind,
                details: details,
                redactedProviderJSON: redactedProviderJSON
            )
        )
        nextSequence &+= 1
    }
}

private enum ProbeDiagnosticSanitizer {
    private static let forbiddenFragments = [
        "authorization", "secret", "token", "transcript", "audio", "delta",
    ]

    static func details(_ details: [String: String]) -> [String: String] {
        Dictionary(
            uniqueKeysWithValues: details
                .sorted { $0.key < $1.key }
                .prefix(32)
                .map { key, value in
                    let normalizedKey = String(key.prefix(64))
                    let lowered = normalizedKey.lowercased()
                    let isForbidden = forbiddenFragments.contains { lowered.contains($0) }
                    return (normalizedKey, isForbidden ? "<redacted>" : String(value.prefix(256)))
                }
        )
    }
}

enum ProviderEventRedactor {
    private static let deniedKeys: Set<String> = [
        "arguments",
        "audio",
        "authorization",
        "content",
        "delta",
        "input_audio",
        "instructions",
        "message",
        "output",
        "secret",
        "text",
        "token",
        "transcript",
        "value",
    ]

    static func eventType(from data: Data) -> String? {
        guard data.count <= 1_048_576,
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return nil
        }
        return dictionary["type"] as? String
    }

    static func redactedJSONString(from data: Data) -> String {
        guard data.count <= 1_048_576,
              let object = try? JSONSerialization.jsonObject(with: data) else {
            return #"{"redacted":"invalid_or_oversized_event"}"#
        }
        let redacted = redact(object, key: nil)
        guard JSONSerialization.isValidJSONObject(redacted),
              let encoded = try? JSONSerialization.data(
                withJSONObject: redacted,
                options: [.sortedKeys, .withoutEscapingSlashes]
              ),
              let text = String(data: encoded, encoding: .utf8) else {
            return #"{"redacted":"encoding_failed"}"#
        }
        return text
    }

    private static func redact(_ value: Any, key: String?) -> Any {
        if let key, deniedKeys.contains(key.lowercased()) {
            return "<redacted>"
        }
        if let dictionary = value as? [String: Any] {
            return Dictionary(
                uniqueKeysWithValues: dictionary.map { nestedKey, nestedValue in
                    (nestedKey, redact(nestedValue, key: nestedKey))
                }
            )
        }
        if let array = value as? [Any] {
            return array.map { redact($0, key: nil) }
        }
        if value is String || value is NSNumber || value is NSNull {
            return value
        }
        return "<redacted>"
    }
}
