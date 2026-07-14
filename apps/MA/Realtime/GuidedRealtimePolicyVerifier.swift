import CryptoKit
import Foundation

enum GuidedRealtimePolicyVerifier {
    static func verifySessionCreated(
        _ eventData: Data,
        expectedHash: String
    ) throws {
        guard expectedHash.range(
            of: #"^[a-f0-9]{64}$"#,
            options: .regularExpression
        ) != nil,
              let value = try? JSONSerialization.jsonObject(with: eventData),
              let event = value as? [String: Any],
              event["type"] as? String == "session.created",
              let session = event["session"] as? [String: Any],
              let projection = policyProjection(from: session),
              JSONSerialization.isValidJSONObject(projection),
              let canonical = try? JSONSerialization.data(
                  withJSONObject: projection,
                  options: [.sortedKeys, .withoutEscapingSlashes]
              ) else {
            throw GuidedRealtimeError.configurationMismatch
        }

        let observed = SHA256.hash(data: canonical)
            .map { String(format: "%02x", $0) }
            .joined()
        guard observed == expectedHash else {
            throw GuidedRealtimeError.configurationMismatch
        }
    }

    private static func policyProjection(
        from session: [String: Any]
    ) -> [String: Any]? {
        guard session["type"] as? String == "realtime",
              session["model"] as? String == "gpt-realtime-2.1",
              let modalities = session["output_modalities"] as? [String],
              modalities == ["audio"],
              let maxTokens = session["max_output_tokens"] as? NSNumber,
              maxTokens.intValue == 512,
              let instructions = session["instructions"] as? String,
              !instructions.isEmpty,
              let tools = session["tools"] as? [[String: Any]],
              tools.count == 1,
              tools[0]["name"] as? String == "report_attempt",
              session["tool_choice"] as? String == "none",
              session["tracing"] == nil || session["tracing"] is NSNull,
              let audio = session["audio"] as? [String: Any],
              let input = audio["input"] as? [String: Any],
              let output = audio["output"] as? [String: Any],
              input.keys.contains("turn_detection"),
              input["turn_detection"] is NSNull,
              let inputFormat = input["format"] as? [String: Any],
              inputFormat["type"] as? String == "audio/pcm",
              (inputFormat["rate"] as? NSNumber)?.intValue == 24_000,
              let noiseReduction = input["noise_reduction"] as? [String: Any],
              noiseReduction["type"] as? String == "near_field",
              let transcription = input["transcription"] as? [String: Any],
              transcription["model"] as? String == "gpt-4o-mini-transcribe-2025-12-15",
              transcription["language"] as? String == "ja",
              let outputFormat = output["format"] as? [String: Any],
              outputFormat["type"] as? String == "audio/pcm",
              (outputFormat["rate"] as? NSNumber)?.intValue == 24_000,
              output["voice"] as? String == "marin",
              let speed = output["speed"] as? NSNumber,
              abs(speed.doubleValue - 0.92) < 0.000_001 else {
            return nil
        }

        return [
            "type": "realtime",
            "model": "gpt-realtime-2.1",
            "output_modalities": modalities,
            "max_output_tokens": maxTokens,
            "instructions": instructions,
            "tools": tools,
            "tool_choice": "none",
            "tracing": NSNull(),
            "audio": [
                "input": [
                    "format": inputFormat,
                    "noise_reduction": noiseReduction,
                    "transcription": transcription,
                    "turn_detection": NSNull(),
                ],
                "output": [
                    "format": outputFormat,
                    "voice": "marin",
                    "speed": speed,
                ],
            ],
        ]
    }
}
