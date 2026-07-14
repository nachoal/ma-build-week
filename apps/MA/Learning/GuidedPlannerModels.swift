import Foundation

enum GuidedPracticeScaffold: String, Codable, Equatable, Sendable {
    case full
    case none
}

struct GuidedAttemptFact: Equatable, Sendable, Identifiable {
    let id: UUID
    let context: GuidedAttemptContext
    let attemptNumber: Int
    let targetMatch: GuidedTargetMatch
    let scaffold: GuidedPracticeScaffold

    init(result: GuidedRealtimeReviewResult, scaffold: GuidedPracticeScaffold) {
        id = result.request.id
        context = result.request.context
        attemptNumber = result.request.attemptNumber
        targetMatch = result.review.targetMatch
        self.scaffold = scaffold
    }

    init(
        id: UUID,
        context: GuidedAttemptContext,
        attemptNumber: Int,
        targetMatch: GuidedTargetMatch,
        scaffold: GuidedPracticeScaffold
    ) {
        self.id = id
        self.context = context
        self.attemptNumber = attemptNumber
        self.targetMatch = targetMatch
        self.scaffold = scaffold
    }
}

struct GuidedStageSummary: Codable, Equatable, Sendable {
    let attemptCount: Int
    let lastReview: GuidedTargetMatch
    let scaffold: GuidedPracticeScaffold

    enum CodingKeys: String, CodingKey {
        case attemptCount = "attempt_count"
        case lastReview = "last_review"
        case scaffold
    }
}

struct GuidedAttemptSummary: Codable, Equatable, Sendable {
    let taughtPhrase: GuidedStageSummary
    let restaurantTurn: GuidedStageSummary

    enum CodingKeys: String, CodingKey {
        case taughtPhrase = "taught_phrase"
        case restaurantTurn = "restaurant_turn"
    }
}

struct GuidedLearningReport: Codable, Equatable, Sendable, Identifiable {
    let schemaVersion: Int
    let id: UUID
    let scenePlan: ScenePlan
    let attemptSummary: GuidedAttemptSummary
    let lessonFinished: Bool
    let rawAudioIncluded: Bool
    let transcriptIncluded: Bool
    let selfAssessmentIncluded: Bool

    init(
        schemaVersion: Int = 2,
        id: UUID = UUID(),
        scenePlan: ScenePlan = .restaurantForOne,
        attemptSummary: GuidedAttemptSummary,
        lessonFinished: Bool = true,
        rawAudioIncluded: Bool = false,
        transcriptIncluded: Bool = false,
        selfAssessmentIncluded: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.scenePlan = scenePlan
        self.attemptSummary = attemptSummary
        self.lessonFinished = lessonFinished
        self.rawAudioIncluded = rawAudioIncluded
        self.transcriptIncluded = transcriptIncluded
        self.selfAssessmentIncluded = selfAssessmentIncluded
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case id = "report_id"
        case scenePlan = "scene_plan"
        case attemptSummary = "attempt_summary"
        case lessonFinished = "lesson_finished"
        case rawAudioIncluded = "raw_audio_included"
        case transcriptIncluded = "transcript_included"
        case selfAssessmentIncluded = "self_assessment_included"
    }

    var isValidForPlannerTransport: Bool {
        guard schemaVersion == 2,
              scenePlan == .restaurantForOne,
              lessonFinished,
              !rawAudioIncluded,
              !transcriptIncluded,
              !selfAssessmentIncluded else { return false }
        return Self.isValid(attemptSummary.taughtPhrase)
            && Self.isValid(attemptSummary.restaurantTurn)
    }

    static func make(
        from facts: [GuidedAttemptFact],
        id: UUID = UUID()
    ) -> GuidedLearningReport? {
        guard (2...16).contains(facts.count),
              Set(facts.map(\.id)).count == facts.count,
              zip(facts, facts.dropFirst()).allSatisfy({ pair in
                  pair.0.attemptNumber < pair.1.attemptNumber
              })
        else { return nil }

        var reachedRestaurant = false
        for fact in facts {
            if fact.context == .restaurantTurn {
                reachedRestaurant = true
            } else if reachedRestaurant {
                return nil
            }
        }

        let taught = facts.filter { $0.context == .taughtPhrase }
        let restaurant = facts.filter { $0.context == .restaurantTurn }
        guard (1...8).contains(taught.count),
              (1...8).contains(restaurant.count),
              let taughtLast = taught.last,
              let restaurantLast = restaurant.last else { return nil }

        let report = GuidedLearningReport(
            id: id,
            attemptSummary: GuidedAttemptSummary(
                taughtPhrase: GuidedStageSummary(
                    attemptCount: taught.count,
                    lastReview: taughtLast.targetMatch,
                    scaffold: taughtLast.scaffold
                ),
                restaurantTurn: GuidedStageSummary(
                    attemptCount: restaurant.count,
                    lastReview: restaurantLast.targetMatch,
                    scaffold: restaurantLast.scaffold
                )
            )
        )
        return report.isValidForPlannerTransport ? report : nil
    }

    private static func isValid(_ summary: GuidedStageSummary) -> Bool {
        (1...8).contains(summary.attemptCount)
    }
}

enum GuidedPracticeActionKind: String, Codable, CaseIterable, Equatable, Sendable {
    case repeatLesson = "repeat"
    case reduceScaffold = "reduce_scaffold"
    case advance
    case abstain
}

enum GuidedPracticeReason: String, Codable, CaseIterable, Equatable, Sendable {
    case reviewUnclear = "review_unclear"
    case targetClose = "target_close"
    case targetNotMatched = "target_not_matched"
    case matchedWithSupport = "matched_with_support"
    case matchedWithoutSupport = "matched_without_support"
    case insufficientEvidence = "insufficient_evidence"
}

enum GuidedPracticeRecommendationSource: String, Codable, Equatable, Sendable {
    case model
    case deterministicPolicy = "deterministic_policy"
}

struct GuidedNextPracticeAction: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let reportID: UUID
    let model: String
    let source: GuidedPracticeRecommendationSource
    let action: GuidedPracticeActionKind
    let reason: GuidedPracticeReason
    let explanationEN: String
    let explanationES: String
    let evidenceReasonEN: String
    let evidenceReasonES: String
    let obligationID: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case reportID = "report_id"
        case model
        case source
        case action
        case reason
        case explanationEN = "explanation_en"
        case explanationES = "explanation_es"
        case evidenceReasonEN = "evidence_reason_en"
        case evidenceReasonES = "evidence_reason_es"
        case obligationID = "obligation_id"
    }

    func explanation(in language: MAInterfaceLanguage) -> String {
        language == .english ? explanationEN : explanationES
    }

    func evidenceReason(in language: MAInterfaceLanguage) -> String {
        language == .english ? evidenceReasonEN : evidenceReasonES
    }
}

enum GuidedPlannerStep: Equatable, Sendable {
    case local(GuidedNextPracticeAction)
    case requesting(GuidedNextPracticeAction)
    case model(GuidedNextPracticeAction)
    case unavailable(GuidedNextPracticeAction)

    var action: GuidedNextPracticeAction {
        switch self {
        case .local(let action),
             .requesting(let action),
             .model(let action),
             .unavailable(let action):
            action
        }
    }
}
