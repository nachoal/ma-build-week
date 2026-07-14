import Foundation

enum GuidedRealtimeClientCommand {
    static let reviewMaxOutputTokens = 512
    static let spokenFeedbackMaxOutputTokens = 512
    static let restaurantTurnMaxOutputTokens = 192

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
                // Reasoning plus the constrained report_attempt payload varies
                // across otherwise-identical live runs. Both 128 and 256 have
                // produced a finished function call followed by
                // incomplete/max_output_tokens. The fixed session ceiling is
                // 512, so use that same bounded ceiling and still require a
                // completed response.done before accepting the tool call.
                "max_output_tokens": reviewMaxOutputTokens,
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
                // The fixed two-sentence explanations failed 10/10 at 160
                // live output tokens. A 384-token bound then passed a direct
                // 10-run probe but still clipped one of six complete,
                // same-session lessons. Use the fixed 512-token session
                // ceiling and continue to require completed response.done.
                "max_output_tokens": spokenFeedbackMaxOutputTokens,
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
                // Five direct generations used 46...83 output tokens, but the
                // complete same-session stress path still clipped three waiter
                // turns at 96 while reasoning effort was implicit. The broker
                // now pins low reasoning; 192 retains a strict bound with
                // measured headroom for the one exact question.
                "max_output_tokens": restaurantTurnMaxOutputTokens,
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
