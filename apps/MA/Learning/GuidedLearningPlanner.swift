import Foundation

enum GuidedLearningPlannerError: Error, Equatable, Sendable {
    case invalidReport
    case invalidResponse
}

protocol GuidedRemoteLearningPlanning: Sendable {
    func requestNextAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction
}

protocol GuidedLearningPlanning: Sendable {
    func improvedAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction
}

struct GuidedPedagogyPolicy: Sendable {
    static let modelVersion = "ma-guided-pedagogy-v2"
    static let expectedRemoteModel = "gpt-5.6-sol"

    func fallback(for report: GuidedLearningReport) -> GuidedNextPracticeAction {
        guard report.isValidForPlannerTransport else {
            return make(
                report: report,
                action: .abstain,
                reason: .insufficientEvidence,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }

        let restaurant = report.attemptSummary.restaurantTurn
        switch restaurant.lastReview {
        case .matched:
            if restaurant.scaffold == .none {
                return make(
                    report: report,
                    action: .advance,
                    reason: .matchedWithoutSupport,
                    source: .deterministicPolicy,
                    model: Self.modelVersion
                )
            }
            return make(
                report: report,
                action: .reduceScaffold,
                reason: .matchedWithSupport,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        case .close:
            return make(
                report: report,
                action: .repeatLesson,
                reason: .targetClose,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        case .different:
            return make(
                report: report,
                action: .repeatLesson,
                reason: .targetNotMatched,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        case .unclear:
            return make(
                report: report,
                action: .repeatLesson,
                reason: .reviewUnclear,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }
    }

    func validatedModelAction(
        _ candidate: GuidedNextPracticeAction,
        for report: GuidedLearningReport
    ) -> GuidedNextPracticeAction? {
        guard report.isValidForPlannerTransport,
              candidate.schemaVersion == 2,
              candidate.reportID == report.id,
              candidate.model == Self.expectedRemoteModel,
              candidate.source == .model,
              candidate.obligationID == report.scenePlan.obligationID,
              isSupported(candidate.action, reason: candidate.reason, report: report)
        else { return nil }
        return make(
            report: report,
            action: candidate.action,
            reason: candidate.reason,
            source: .model,
            model: Self.expectedRemoteModel
        )
    }

    func make(
        report: GuidedLearningReport,
        action: GuidedPracticeActionKind,
        reason: GuidedPracticeReason,
        source: GuidedPracticeRecommendationSource,
        model: String
    ) -> GuidedNextPracticeAction {
        GuidedNextPracticeAction(
            schemaVersion: 2,
            reportID: report.id,
            model: model,
            source: source,
            action: action,
            reason: reason,
            explanationEN: explanationEN(for: action),
            explanationES: explanationES(for: action),
            evidenceReasonEN: evidenceEN(for: reason),
            evidenceReasonES: evidenceES(for: reason),
            obligationID: report.scenePlan.obligationID
        )
    }

    private func isSupported(
        _ action: GuidedPracticeActionKind,
        reason: GuidedPracticeReason,
        report: GuidedLearningReport
    ) -> Bool {
        let restaurant = report.attemptSummary.restaurantTurn
        return switch (action, reason) {
        case (.repeatLesson, .reviewUnclear):
            restaurant.lastReview == .unclear
        case (.repeatLesson, .targetClose):
            restaurant.lastReview == .close
        case (.repeatLesson, .targetNotMatched):
            restaurant.lastReview == .different
        case (.reduceScaffold, .matchedWithSupport):
            restaurant.lastReview == .matched && restaurant.scaffold == .full
        case (.advance, .matchedWithoutSupport):
            restaurant.lastReview == .matched && restaurant.scaffold == .none
        case (.abstain, .insufficientEvidence):
            true
        default:
            false
        }
    }

    private func explanationEN(for action: GuidedPracticeActionKind) -> String {
        switch action {
        case .repeatLesson: "Repeat hitori desu with the model before another scene."
        case .reduceScaffold: "Try the same exchange again with less visible help."
        case .advance: "Try a new beginner scene while keeping this phrase as support."
        case .abstain: "Keep the local plan because the available facts are not enough."
        }
    }

    private func explanationES(for action: GuidedPracticeActionKind) -> String {
        switch action {
        case .repeatLesson: "Repite hitori desu con el modelo antes de otra escena."
        case .reduceScaffold: "Haz el mismo intercambio otra vez con menos ayuda visible."
        case .advance: "Prueba otra escena inicial conservando esta frase como apoyo."
        case .abstain: "Mantén el plan local porque los hechos disponibles no bastan."
        }
    }

    private func evidenceEN(for reason: GuidedPracticeReason) -> String {
        switch reason {
        case .reviewUnclear: "The restaurant-turn review could not verify the words."
        case .targetClose: "The restaurant answer was close to the expected phrase."
        case .targetNotMatched: "The restaurant answer did not match the expected phrase."
        case .matchedWithSupport: "MA recognized the expected answer while it was visible."
        case .matchedWithoutSupport: "MA recognized the expected answer without visible help."
        case .insufficientEvidence: "The aggregate lesson facts do not justify a change."
        }
    }

    private func evidenceES(for reason: GuidedPracticeReason) -> String {
        switch reason {
        case .reviewUnclear: "La revisión del turno no pudo verificar las palabras."
        case .targetClose: "La respuesta del restaurante fue cercana a la frase esperada."
        case .targetNotMatched: "La respuesta del restaurante no coincidió con la frase esperada."
        case .matchedWithSupport: "MA reconoció la respuesta esperada mientras estaba visible."
        case .matchedWithoutSupport: "MA reconoció la respuesta esperada sin ayuda visible."
        case .insufficientEvidence: "Los hechos agregados de la lección no justifican un cambio."
        }
    }
}

struct GuidedLearningPlanner: GuidedLearningPlanning {
    private let remote: any GuidedRemoteLearningPlanning
    private let policy: GuidedPedagogyPolicy

    init(
        remote: any GuidedRemoteLearningPlanning,
        policy: GuidedPedagogyPolicy = GuidedPedagogyPolicy()
    ) {
        self.remote = remote
        self.policy = policy
    }

    func improvedAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction {
        guard report.isValidForPlannerTransport else {
            throw GuidedLearningPlannerError.invalidReport
        }
        let candidate = try await remote.requestNextAction(for: report)
        guard !Task.isCancelled,
              let validated = policy.validatedModelAction(candidate, for: report) else {
            throw GuidedLearningPlannerError.invalidResponse
        }
        return validated
    }
}
