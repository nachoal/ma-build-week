import Foundation

struct DeterministicPedagogyPolicy: Sendable {
    static let modelVersion = "ma-deterministic-pedagogy-v1"
    static let expectedRemoteModel = "gpt-5.6-sol"

    func fallback(for report: LearningReport) -> NextLearningAction {
        guard report.isValidForPlannerTransport,
              let last = report.lastAttempt else {
            return make(
                report: report,
                action: .abstain,
                reason: .insufficientEvidence,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }

        if report.currentObligationCompleted && last.repairCount > 0 {
            return make(
                report: report,
                action: .advance,
                reason: .completedAfterRepair,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }
        if !last.speechPresenceDetected {
            return make(
                report: report,
                action: .repeatLesson,
                reason: .speechPresenceMissing,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }
        if !last.selfReportedCompleted && last.repairCount > 0 {
            return make(
                report: report,
                action: .isolateSegment,
                reason: .repairNeeded,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }
        if last.selfReportedCompleted && last.scaffold != .none {
            return make(
                report: report,
                action: .reduceScaffold,
                reason: .scaffoldStillPresent,
                source: .deterministicPolicy,
                model: Self.modelVersion
            )
        }
        return make(
            report: report,
            action: .repeatLesson,
            reason: .incompleteSelfReport,
            source: .deterministicPolicy,
            model: Self.modelVersion
        )
    }

    func validatedModelAction(
        _ candidate: NextLearningAction,
        for report: LearningReport
    ) -> NextLearningAction? {
        guard report.isValidForPlannerTransport,
              candidate.schemaVersion == 1,
              candidate.reportID == report.id,
              candidate.model == Self.expectedRemoteModel,
              candidate.source == .model,
              candidate.obligationID == report.scenePlan.obligationID,
              let last = report.lastAttempt,
              isSupported(candidate.action, report: report, last: last),
              isSupported(candidate.reason, report: report, last: last),
              isAllowedPair(action: candidate.action, reason: candidate.reason) else {
            return nil
        }
        return make(
            report: report,
            action: candidate.action,
            reason: candidate.reason,
            source: .model,
            model: Self.expectedRemoteModel
        )
    }

    func make(
        report: LearningReport,
        action: LearningActionKind,
        reason: LearningReason,
        source: LearningRecommendationSource,
        model: String
    ) -> NextLearningAction {
        NextLearningAction(
            schemaVersion: 1,
            reportID: report.id,
            model: model,
            source: source,
            action: action,
            reason: reason,
            explanationES: explanation(for: action),
            evidenceReasonES: evidenceReason(for: reason),
            obligationID: report.scenePlan.obligationID
        )
    }

    private func isSupported(
        _ action: LearningActionKind,
        report: LearningReport,
        last: Attempt
    ) -> Bool {
        switch action {
        case .advance:
            report.currentObligationCompleted
        case .reduceScaffold:
            last.selfReportedCompleted && last.scaffold != .none
        case .isolateSegment:
            last.repairCount > 0
        case .repeatLesson, .abstain:
            true
        }
    }

    private func isSupported(
        _ reason: LearningReason,
        report: LearningReport,
        last: Attempt
    ) -> Bool {
        switch reason {
        case .completedAfterRepair:
            report.currentObligationCompleted && last.repairCount > 0
        case .incompleteSelfReport:
            !last.selfReportedCompleted
        case .speechPresenceMissing:
            !last.speechPresenceDetected
        case .scaffoldStillPresent:
            last.scaffold != .none
        case .repairNeeded:
            !last.selfReportedCompleted && last.repairCount > 0
        case .insufficientEvidence:
            true
        }
    }

    private func isAllowedPair(
        action: LearningActionKind,
        reason: LearningReason
    ) -> Bool {
        switch action {
        case .repeatLesson:
            reason == .incompleteSelfReport || reason == .speechPresenceMissing
        case .reduceScaffold:
            reason == .scaffoldStillPresent
        case .isolateSegment:
            reason == .repairNeeded || reason == .speechPresenceMissing
        case .advance:
            reason == .completedAfterRepair
        case .abstain:
            reason == .insufficientEvidence
        }
    }

    private func explanation(for action: LearningActionKind) -> String {
        switch action {
        case .repeatLesson:
            "Repite la misma respuesta antes de cambiar de situación."
        case .reduceScaffold:
            "Haz otro intento con menos ayuda visible."
        case .isolateSegment:
            "Aísla una parte breve antes de volver a la situación."
        case .advance:
            "Ya puedes pasar al siguiente objetivo práctico."
        case .abstain:
            "Mantén el plan local porque faltan hechos suficientes."
        }
    }

    private func evidenceReason(for reason: LearningReason) -> String {
        switch reason {
        case .completedAfterRepair:
            "Confirmaste la misma obligación después de una reparación."
        case .incompleteSelfReport:
            "Marcaste el intento más reciente como incompleto."
        case .speechPresenceMissing:
            "No hubo señal local suficiente de voz en el intento."
        case .scaffoldStillPresent:
            "El intento más reciente todavía usó ayuda visible."
        case .repairNeeded:
            "El intento siguió incompleto después de pedir ayuda."
        case .insufficientEvidence:
            "Los hechos disponibles no justifican cambiar de objetivo."
        }
    }
}
