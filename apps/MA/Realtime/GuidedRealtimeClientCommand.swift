import Foundation

enum GuidedRealtimeClientCommand {
    static func appendInputAudio(_ data: Data, eventID: String) throws -> Data {
        guard !data.isEmpty,
              data.count <= 48_000,
              data.count.isMultiple(of: MemoryLayout<Int16>.size) else {
            throw GuidedRealtimeError.invalidAudio
        }
        return try encode([
            "type": "input_audio_buffer.append",
            "event_id": try eventIdentifier(eventID),
            "audio": data.base64EncodedString(),
        ])
    }

    static func clearInput(eventID: String) throws -> Data {
        try encode([
            "type": "input_audio_buffer.clear",
            "event_id": try eventIdentifier(eventID),
        ])
    }

    static func commitInput(eventID: String) throws -> Data {
        try encode([
            "type": "input_audio_buffer.commit",
            "event_id": try eventIdentifier(eventID),
        ])
    }

    static func createReviewResponse(
        request: GuidedAttemptRequest,
        eventID: String
    ) throws -> Data {
        let context = request.context == .restaurantTurn
            ? "This attempt answered the waiter in the restaurant turn."
            : "This attempt practiced the taught phrase before the restaurant turn."
        return try encode([
            "type": "response.create",
            "event_id": try eventIdentifier(eventID),
            "response": [
                "instructions": [
                    "Review only the just-committed learner audio against 一人です (hitori desu).",
                    context,
                    "Call report_attempt exactly once using only the declared assessment, evidence, and retry-focus enum codes. Do not author feedback prose and do not speak yet.",
                    "Never return a score, confidence, mastery claim, or phoneme-level diagnosis.",
                ].joined(separator: " "),
                "tool_choice": [
                    "type": "function",
                    "name": "report_attempt",
                ],
                "output_modalities": ["text"],
                // The constrained report_attempt payload can exceed 128
                // Realtime tokens even though its JSON is small. At 128 the
                // provider can emit function_call_arguments.done and still
                // finish response.done as incomplete/max_output_tokens, which
                // must fail closed. Keep this bounded but large enough for the
                // complete four-field tool call observed against the live
                // product session policy.
                "max_output_tokens": 256,
                "metadata": [
                    "purpose": "attempt_review",
                    "attempt_id": request.id.uuidString.lowercased(),
                ],
            ],
        ])
    }

    static func functionOutput(
        callID: String,
        output: String,
        eventID: String
    ) throws -> Data {
        guard !output.isEmpty, output.utf8.count <= 512 else {
            throw GuidedRealtimeError.invalidReview
        }
        return try encode([
            "type": "conversation.item.create",
            "event_id": try eventIdentifier(eventID),
            "item": [
                "type": "function_call_output",
                "call_id": try providerIdentifier(callID),
                "output": output,
            ],
        ])
    }

    static func createSpokenFeedbackResponse(
        review: GuidedAttemptReview,
        language: MAInterfaceLanguage,
        eventID: String
    ) throws -> Data {
        // Both sentences are canonical local copy selected from validated enum
        // codes. No model-authored function argument is interpolated here.
        let positive = review.positive(in: language)
        let next = review.retryFocus(in: language) ?? language.text(
            english: "Keep the same short answer for the waiter.",
            spanish: "Mantén la misma respuesta corta para el mesero."
        )
        let languageInstruction = language.text(
            english: "Speak in English in exactly two short sentences and then stop.",
            spanish: "Speak in Spanish in exactly two short sentences and then stop."
        )
        return try encode([
            "type": "response.create",
            "event_id": try eventIdentifier(eventID),
            "response": [
                "instructions": [
                    languageInstruction,
                    "First say exactly this grounded point: \(positive)",
                    "Then say this single next focus: \(next)",
                    "Do not add Japanese beyond hitori desu. Do not add a score or any new diagnosis.",
                ].joined(separator: " "),
                "tool_choice": "none",
                "output_modalities": ["audio"],
                "max_output_tokens": 160,
                "metadata": ["purpose": "spoken_attempt_feedback"],
            ],
        ])
    }

    static func createRestaurantTurn(eventID: String) throws -> Data {
        try encode([
            "type": "response.create",
            "event_id": try eventIdentifier(eventID),
            "response": [
                "instructions": [
                    "Act as the restaurant waiter for one brief turn.",
                    "Say exactly this Japanese question once, naturally and clearly: 何名様ですか？",
                    "Do not add a greeting, explanation, translation, or second sentence.",
                ].joined(separator: " "),
                "tool_choice": "none",
                "output_modalities": ["audio"],
                "max_output_tokens": 64,
                "metadata": ["purpose": "restaurant_waiter_turn"],
            ],
        ])
    }

    private static func eventIdentifier(_ value: String) throws -> String {
        guard (3...128).contains(value.count),
              value.unicodeScalars.allSatisfy({ $0.value >= 0x21 && $0.value <= 0x7E }) else {
            throw GuidedRealtimeError.providerRejected
        }
        return value
    }

    private static func providerIdentifier(_ value: String) throws -> String {
        guard !value.isEmpty,
              value.count <= 256,
              value.unicodeScalars.allSatisfy({ $0.value >= 0x21 && $0.value <= 0x7E }) else {
            throw GuidedRealtimeError.providerRejected
        }
        return value
    }

    private static func encode(_ value: [String: Any]) throws -> Data {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(
                  withJSONObject: value,
                  options: [.sortedKeys, .withoutEscapingSlashes]
              ),
              !data.isEmpty,
              data.count <= 1_048_576 else {
            throw GuidedRealtimeError.providerRejected
        }
        return data
    }
}
