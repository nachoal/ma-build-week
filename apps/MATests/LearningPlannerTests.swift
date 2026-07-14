import Foundation
import Testing
@testable import MA

@Suite("Bounded learning planner")
struct LearningPlannerTests {
    @Test("LearningReport encodes only the bounded evidence contract")
    func reportEncodingIsBounded() throws {
        let report = makePlannerTestReport()
        #expect(report.isValidForPlannerTransport)

        let data = try JSONEncoder().encode(report)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == Set([
            "schema_version",
            "report_id",
            "scene_plan",
            "attempts",
            "current_obligation_completed",
            "repair_segment_id",
            "raw_audio_included",
        ]))
        #expect(object["raw_audio_included"] as? Bool == false)
        let encoded = try #require(String(data: data, encoding: .utf8))
        #expect(!encoded.contains("transcript"))
        #expect(!encoded.contains("pronunciation"))
        #expect(!encoded.contains("audio_data"))
    }

    @Test("Worker and Swift decode the same completed-report fixture")
    func sharedContractFixture() throws {
        let url = try #require(
            Bundle(for: PlannerFixtureBundleAnchor.self).url(
                forResource: "learning-report-completed",
                withExtension: "json"
            )
        )
        let decoded = try JSONDecoder().decode(
            LearningReport.self,
            from: Data(contentsOf: url)
        )

        #expect(decoded == makePlannerTestReport())
        #expect(decoded.isValidForPlannerTransport)
    }

    @Test("Worker and Swift share the same accepted recommendation fixture")
    func sharedRecommendationFixture() throws {
        let url = try #require(
            Bundle(for: PlannerFixtureBundleAnchor.self).url(
                forResource: "next-learning-action-completed",
                withExtension: "json"
            )
        )
        let decoded = try JSONDecoder().decode(
            NextLearningAction.self,
            from: Data(contentsOf: url)
        )
        let report = makePlannerTestReport()

        #expect(
            DeterministicPedagogyPolicy().validatedModelAction(
                decoded,
                for: report
            ) == decoded
        )
    }

    @Test("Deterministic fallback advances only a completed repaired obligation")
    func deterministicAdvanceGuard() {
        let policy = DeterministicPedagogyPolicy()
        let completed = makePlannerTestReport()
        let advanced = policy.fallback(for: completed)
        #expect(advanced.action == .advance)
        #expect(advanced.reason == .completedAfterRepair)
        #expect(advanced.source == .deterministicPolicy)

        let incomplete = makePlannerTestReport(completed: false)
        let repeated = policy.fallback(for: incomplete)
        #expect(repeated.action == .isolateSegment)
        #expect(repeated.reason == .repairNeeded)
        #expect(repeated.source == .deterministicPolicy)
    }

    @Test("Model action and reason must be one supported semantic pair")
    func rejectsContradictoryPair() {
        let report = makePlannerTestReport()
        let candidate = NextLearningAction(
            schemaVersion: 1,
            reportID: report.id,
            model: "gpt-5.6-sol",
            source: .model,
            action: .advance,
            reason: .insufficientEvidence,
            explanationES: "Texto no confiable",
            evidenceReasonES: "Texto no confiable",
            obligationID: report.scenePlan.obligationID
        )

        #expect(
            DeterministicPedagogyPolicy().validatedModelAction(
                candidate,
                for: report
            ) == nil
        )
    }

    @Test("Valid model output is re-authored from canonical local language")
    func canonicalizesModelLanguage() async {
        let report = makePlannerTestReport()
        let candidate = NextLearningAction(
            schemaVersion: 1,
            reportID: report.id,
            model: "gpt-5.6-sol",
            source: .model,
            action: .advance,
            reason: .completedAfterRepair,
            explanationES: "Invented score: 99%",
            evidenceReasonES: "Fluency mastered",
            obligationID: report.scenePlan.obligationID
        )
        let planner = LearningPlanner(remote: StubRemotePlanner(result: .success(candidate)))

        let result = await planner.nextAction(for: report)

        #expect(result.source == .model)
        #expect(result.explanationES == "Ya puedes pasar al siguiente objetivo práctico.")
        #expect(
            result.evidenceReasonES
                == "Confirmaste la misma obligación después de una reparación."
        )
        #expect(!result.explanationES.contains("99"))
    }

    @Test("Every remote failure uses the same nonblocking local fallback")
    func remoteFailureFallsBack() async {
        let report = makePlannerTestReport()
        let expected = DeterministicPedagogyPolicy().fallback(for: report)
        let planner = LearningPlanner(remote: StubRemotePlanner(result: .failure(.timeout)))

        let result = await planner.nextAction(for: report)

        #expect(result == expected)
        #expect(result.source == .deterministicPolicy)
    }

    @Test("A stale report identifier can never be applied")
    func staleReportFallsBack() async {
        let report = makePlannerTestReport()
        let stale = NextLearningAction(
            schemaVersion: 1,
            reportID: UUID(),
            model: "gpt-5.6-sol",
            source: .model,
            action: .advance,
            reason: .completedAfterRepair,
            explanationES: "stale",
            evidenceReasonES: "stale",
            obligationID: report.scenePlan.obligationID
        )

        let result = await LearningPlanner(
            remote: StubRemotePlanner(result: .success(stale))
        ).nextAction(for: report)

        #expect(result.source == .deterministicPolicy)
        #expect(result.reportID == report.id)
    }
}

private final class PlannerFixtureBundleAnchor: NSObject {}

private enum PlannerTestError: Error, Sendable {
    case timeout
}

private struct StubRemotePlanner: RemoteLearningPlanning {
    let result: Result<NextLearningAction, PlannerTestError>

    func requestNextAction(for report: LearningReport) async throws -> NextLearningAction {
        try result.get()
    }
}

func makePlannerTestReport(
    completed: Bool = true,
    speechPresence: Bool = true,
    scaffold: Attempt.Scaffold = .none
) -> LearningReport {
    let obligation = KaiwaLoopState.obligationID
    return LearningReport(
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000001")!,
        scenePlan: .restaurantForOne,
        attempts: [
            Attempt(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000003")!,
                obligationID: obligation,
                scaffold: scaffold,
                attemptNumber: 3,
                capturedDurationMS: 2_000,
                estimatedVoiceOnsetMS: 800,
                speechPresenceDetected: true,
                selfReportedCompleted: true,
                repairCount: 0
            ),
            Attempt(
                id: UUID(uuidString: "00000000-0000-4000-8000-000000000004")!,
                obligationID: obligation,
                scaffold: scaffold,
                attemptNumber: 4,
                capturedDurationMS: speechPresence ? 2_000 : 0,
                estimatedVoiceOnsetMS: speechPresence ? 500 : nil,
                speechPresenceDetected: speechPresence,
                selfReportedCompleted: completed,
                repairCount: 1
            ),
        ],
        currentObligationCompleted: completed,
        repairSegmentID: ControlledSegment.restaurantRepair.id
    )
}
