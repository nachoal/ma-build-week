import CryptoKit
import Foundation

struct FixedRealtimeSessionPolicy: Codable, Sendable, Equatable {
    struct Audio: Codable, Sendable, Equatable {
        struct Input: Codable, Sendable, Equatable {
            struct Format: Codable, Sendable, Equatable {
                let type: String
                let rate: Int
            }

            struct TurnDetection: Codable, Sendable, Equatable {
                let type: String
                let threshold: Double
                let prefixPaddingMilliseconds: Int
                let silenceDurationMilliseconds: Int
                let createResponse: Bool
                let interruptResponse: Bool

                enum CodingKeys: String, CodingKey {
                    case type
                    case threshold
                    case prefixPaddingMilliseconds = "prefix_padding_ms"
                    case silenceDurationMilliseconds = "silence_duration_ms"
                    case createResponse = "create_response"
                    case interruptResponse = "interrupt_response"
                }
            }

            let format: Format
            let turnDetection: TurnDetection

            enum CodingKeys: String, CodingKey {
                case format
                case turnDetection = "turn_detection"
            }
        }

        struct Output: Codable, Sendable, Equatable {
            struct Format: Codable, Sendable, Equatable {
                let type: String
                let rate: Int
            }

            let format: Format
            let voice: String
        }

        let input: Input
        let output: Output
    }

    let type: String
    let model: String
    let outputModalities: [String]
    let instructions: String
    let audio: Audio

    enum CodingKeys: String, CodingKey {
        case type
        case model
        case outputModalities = "output_modalities"
        case instructions
        case audio
    }

    static let expected = FixedRealtimeSessionPolicy(
        type: "realtime",
        model: "gpt-realtime-2.1",
        outputModalities: ["audio"],
        instructions: [
            "You are the waiter in one tightly bounded Japanese restaurant-arrival rehearsal.",
            "Speak natural Japanese, stay on the active restaurant obligation, and keep turns concise.",
            "Do not teach or grade during the live turn. The app owns repair, floor control, and pedagogy.",
        ].joined(separator: " "),
        audio: Audio(
            input: Audio.Input(
                format: Audio.Input.Format(type: "audio/pcm", rate: 24_000),
                turnDetection: Audio.Input.TurnDetection(
                    type: "server_vad",
                    threshold: 0.5,
                    prefixPaddingMilliseconds: 300,
                    silenceDurationMilliseconds: 500,
                    createResponse: false,
                    interruptResponse: false
                )
            ),
            output: Audio.Output(
                format: Audio.Output.Format(type: "audio/pcm", rate: 24_000),
                voice: "marin"
            )
        )
    )
}

struct RealtimePolicyVerification: Sendable, Equatable {
    let observedHash: String
    let expectedHash: String

    var matches: Bool {
        observedHash == expectedHash
    }
}

enum RealtimePolicyVerificationError: Error, Equatable {
    case invalidEvent
    case invalidExpectedHash
    case unsupportedEventType
}

enum RealtimePolicyVerifier {
    private struct Envelope: Decodable {
        let type: String
        let session: FixedRealtimeSessionPolicy
    }

    static func verify(
        eventData: Data,
        expectedHash: String
    ) throws -> RealtimePolicyVerification {
        guard expectedHash.range(of: #"^[a-f0-9]{64}$"#, options: .regularExpression) != nil else {
            throw RealtimePolicyVerificationError.invalidExpectedHash
        }

        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: eventData) else {
            throw RealtimePolicyVerificationError.invalidEvent
        }
        guard envelope.type == "session.created" || envelope.type == "session.updated" else {
            throw RealtimePolicyVerificationError.unsupportedEventType
        }

        return RealtimePolicyVerification(
            observedHash: try configurationHash(for: envelope.session),
            expectedHash: expectedHash
        )
    }

    static func configurationHash(
        for policy: FixedRealtimeSessionPolicy
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let encoded = try encoder.encode(policy)
        let digest = SHA256.hash(data: encoded)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
