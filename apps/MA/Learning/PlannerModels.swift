import Foundation

struct ScenePlan: Codable, Equatable, Sendable {
    static let restaurantForOne = ScenePlan(
        sceneID: SceneID.restaurant.rawValue,
        obligationID: KaiwaLoopState.obligationID,
        learnerLevel: "zero_beginner",
        targetPhraseID: "restaurant.party-size.hitori-desu"
    )

    let sceneID: String
    let obligationID: String
    let learnerLevel: String
    let targetPhraseID: String

    enum CodingKeys: String, CodingKey {
        case sceneID = "scene_id"
        case obligationID = "obligation_id"
        case learnerLevel = "learner_level"
        case targetPhraseID = "target_phrase_id"
    }
}

struct Attempt: Codable, Equatable, Sendable, Identifiable {
    enum Scaffold: String, Codable, Equatable, Sendable {
        case full
        case rhythmOnly = "rhythm_only"
        case none

        init(_ scaffold: ScaffoldLevel) {
            self = switch scaffold {
            case .full: .full
            case .rhythmOnly: .rhythmOnly
            case .none: .none
            }
        }
    }

    let id: UUID
    let obligationID: String
    let scaffold: Scaffold
    let attemptNumber: Int
    let capturedDurationMS: Int
    let estimatedVoiceOnsetMS: Int?
    let speechPresenceDetected: Bool
    let selfReportedCompleted: Bool
    let repairCount: Int
    let rawAudioRetained: Bool

    init?(evidence: PracticeAttemptEvidence) {
        guard evidence.provenance == .localCaptureSelfAssessment,
              evidence.attemptNumber > 0,
              evidence.attemptNumber <= 20,
              evidence.repairCount >= 0,
              evidence.repairCount <= 10,
              !evidence.rawAudioRetained,
              let durationMS = Self.milliseconds(
                evidence.capturedDuration,
                maximum: 8_000
              ) else { return nil }

        let onsetMS: Int?
        if evidence.speechPresenceDetected {
            guard durationMS > 0,
                  let onset = evidence.estimatedVoiceOnset,
                  let converted = Self.milliseconds(onset, maximum: 8_000),
                  converted <= durationMS else { return nil }
            onsetMS = converted
        } else {
            guard evidence.estimatedVoiceOnset == nil else { return nil }
            onsetMS = nil
        }

        id = evidence.id
        obligationID = evidence.obligationID
        scaffold = Scaffold(evidence.scaffold)
        attemptNumber = evidence.attemptNumber
        capturedDurationMS = durationMS
        estimatedVoiceOnsetMS = onsetMS
        speechPresenceDetected = evidence.speechPresenceDetected
        selfReportedCompleted = evidence.selfReportedCompleted
        repairCount = evidence.repairCount
        rawAudioRetained = false
    }

    init(
        id: UUID,
        obligationID: String,
        scaffold: Scaffold,
        attemptNumber: Int,
        capturedDurationMS: Int,
        estimatedVoiceOnsetMS: Int?,
        speechPresenceDetected: Bool,
        selfReportedCompleted: Bool,
        repairCount: Int,
        rawAudioRetained: Bool = false
    ) {
        self.id = id
        self.obligationID = obligationID
        self.scaffold = scaffold
        self.attemptNumber = attemptNumber
        self.capturedDurationMS = capturedDurationMS
        self.estimatedVoiceOnsetMS = estimatedVoiceOnsetMS
        self.speechPresenceDetected = speechPresenceDetected
        self.selfReportedCompleted = selfReportedCompleted
        self.repairCount = repairCount
        self.rawAudioRetained = rawAudioRetained
    }

    enum CodingKeys: String, CodingKey {
        case id
        case obligationID = "obligation_id"
        case scaffold
        case attemptNumber = "attempt_number"
        case capturedDurationMS = "captured_duration_ms"
        case estimatedVoiceOnsetMS = "estimated_voice_onset_ms"
        case speechPresenceDetected = "speech_presence_detected"
        case selfReportedCompleted = "self_reported_completed"
        case repairCount = "repair_count"
        case rawAudioRetained = "raw_audio_retained"
    }

    private static func milliseconds(
        _ seconds: TimeInterval,
        maximum: Int
    ) -> Int? {
        guard seconds.isFinite, seconds >= 0 else { return nil }
        let milliseconds = (seconds * 1_000).rounded()
        guard milliseconds <= Double(maximum) else { return nil }
        return Int(milliseconds)
    }
}

struct LearningReport: Codable, Equatable, Sendable, Identifiable {
    let schemaVersion: Int
    let id: UUID
    let scenePlan: ScenePlan
    let attempts: [Attempt]
    let currentObligationCompleted: Bool
    let repairSegmentID: String
    let rawAudioIncluded: Bool

    init(
        schemaVersion: Int = 1,
        id: UUID = UUID(),
        scenePlan: ScenePlan,
        attempts: [Attempt],
        currentObligationCompleted: Bool,
        repairSegmentID: String,
        rawAudioIncluded: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.scenePlan = scenePlan
        self.attempts = attempts
        self.currentObligationCompleted = currentObligationCompleted
        self.repairSegmentID = repairSegmentID
        self.rawAudioIncluded = rawAudioIncluded
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case id = "report_id"
        case scenePlan = "scene_plan"
        case attempts
        case currentObligationCompleted = "current_obligation_completed"
        case repairSegmentID = "repair_segment_id"
        case rawAudioIncluded = "raw_audio_included"
    }

    var lastAttempt: Attempt? { attempts.last }

    var isValidForPlannerTransport: Bool {
        guard schemaVersion == 1,
              scenePlan == .restaurantForOne,
              repairSegmentID == ControlledSegment.restaurantRepair.id,
              !rawAudioIncluded,
              attempts.count == 2,
              attempts[0].id != attempts[1].id,
              attempts[0].attemptNumber < attempts[1].attemptNumber,
              attempts[0].repairCount == 0,
              attempts[1].repairCount > 0,
              currentObligationCompleted == attempts[1].selfReportedCompleted else {
            return false
        }
        return attempts.allSatisfy { attempt in
            attempt.obligationID == scenePlan.obligationID
                && (1...20).contains(attempt.attemptNumber)
                && (0...8_000).contains(attempt.capturedDurationMS)
                && (0...10).contains(attempt.repairCount)
                && !attempt.rawAudioRetained
                && Self.hasConsistentPresenceEvidence(attempt)
        }
    }

    static func make(
        from state: KaiwaLoopState,
        id: UUID = UUID()
    ) -> LearningReport? {
        guard state.phase == .proof,
              let beforeEvidence = state.completedPreRepairAttempt,
              let afterEvidence = state.completedPostRepairAttempt,
              let before = Attempt(evidence: beforeEvidence),
              let after = Attempt(evidence: afterEvidence) else { return nil }

        let report = LearningReport(
            id: id,
            scenePlan: .restaurantForOne,
            attempts: [before, after],
            currentObligationCompleted: after.selfReportedCompleted,
            repairSegmentID: state.repairSegment.id
        )
        return report.isValidForPlannerTransport ? report : nil
    }

    private static func hasConsistentPresenceEvidence(_ attempt: Attempt) -> Bool {
        if attempt.speechPresenceDetected {
            guard attempt.capturedDurationMS > 0,
                  let onset = attempt.estimatedVoiceOnsetMS else { return false }
            return (0...attempt.capturedDurationMS).contains(onset)
        }
        return attempt.estimatedVoiceOnsetMS == nil
    }
}

enum LearningActionKind: String, Codable, CaseIterable, Equatable, Sendable {
    case repeatLesson = "repeat"
    case reduceScaffold = "reduce_scaffold"
    case isolateSegment = "isolate_segment"
    case advance
    case abstain
}

enum LearningReason: String, Codable, CaseIterable, Equatable, Sendable {
    case completedAfterRepair = "completed_after_repair"
    case incompleteSelfReport = "incomplete_self_report"
    case speechPresenceMissing = "speech_presence_missing"
    case scaffoldStillPresent = "scaffold_still_present"
    case repairNeeded = "repair_needed"
    case insufficientEvidence = "insufficient_evidence"
}

enum LearningRecommendationSource: String, Codable, Equatable, Sendable {
    case model
    case deterministicPolicy = "deterministic_policy"
    case cachedFixture = "cached_fixture"
}

struct NextLearningAction: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let reportID: UUID
    let model: String
    let source: LearningRecommendationSource
    let action: LearningActionKind
    let reason: LearningReason
    let explanationES: String
    let evidenceReasonES: String
    let obligationID: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case reportID = "report_id"
        case model
        case source
        case action
        case reason
        case explanationES = "explanation_es"
        case evidenceReasonES = "evidence_reason_es"
        case obligationID = "obligation_id"
    }
}
