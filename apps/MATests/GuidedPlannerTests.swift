import Foundation
import Testing
@testable import MA

@Suite("Guided aggregate-only learning planner", .serialized)
struct GuidedPlannerTests {
    private let installToken = String(repeating: "g", count: 48)

    @Test("The v2 report contains only aggregate categorical facts")
    func aggregateOnlyReport() throws {
        let report = try #require(makeGuidedPlannerTestReport())
        #expect(report.isValidForPlannerTransport)

        let data = try JSONEncoder().encode(report)
        let object = try #require(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        #expect(Set(object.keys) == Set([
            "schema_version",
            "report_id",
            "scene_plan",
            "attempt_summary",
            "lesson_finished",
            "raw_audio_included",
            "transcript_included",
            "self_assessment_included",
        ]))
        #expect(object["raw_audio_included"] as? Bool == false)
        #expect(object["transcript_included"] as? Bool == false)
        #expect(object["self_assessment_included"] as? Bool == false)
        let serialized = try #require(String(data: data, encoding: .utf8))
        for forbidden in [
            "heard_japanese",
            "positive_en",
            "positive_es",
            "correction",
            "retry_focus",
            "pcm",
            "duration",
            "speech_presence",
            "self_report",
        ] {
            #expect(!serialized.contains(forbidden))
        }
    }

    @Test("Attempt summaries preserve stage order and reject clamped or duplicate evidence")
    func reportBoundsAndOrder() {
        let validFacts = guidedPlannerFacts()
        #expect(GuidedLearningReport.make(from: validFacts) != nil)
        #expect(GuidedLearningReport.make(from: Array(validFacts.reversed())) == nil)
        #expect(GuidedLearningReport.make(from: [validFacts[0]]) == nil)

        let duplicate = [validFacts[0], validFacts[0], validFacts[1]]
        #expect(GuidedLearningReport.make(from: duplicate) == nil)

        var tooMany = (1...9).map { number in
            GuidedAttemptFact(
                id: UUID(),
                context: .taughtPhrase,
                attemptNumber: number,
                targetMatch: .close,
                scaffold: .full
            )
        }
        tooMany.append(GuidedAttemptFact(
            id: UUID(),
            context: .restaurantTurn,
            attemptNumber: 10,
            targetMatch: .matched,
            scaffold: .full
        ))
        #expect(GuidedLearningReport.make(from: tooMany) == nil)
    }

    @Test("Visible answer support can never produce an advance recommendation")
    func advanceRequiresNoSupport() throws {
        let policy = GuidedPedagogyPolicy()
        let supported = try #require(makeGuidedPlannerTestReport(scaffold: .full))
        let supportedAction = policy.fallback(for: supported)
        #expect(supportedAction.action == .reduceScaffold)
        #expect(supportedAction.reason == .matchedWithSupport)

        let unsupported = try #require(makeGuidedPlannerTestReport(scaffold: .none))
        let advance = policy.fallback(for: unsupported)
        #expect(advance.action == .advance)
        #expect(advance.reason == .matchedWithoutSupport)

        let inventedAdvance = policy.make(
            report: supported,
            action: .advance,
            reason: .matchedWithoutSupport,
            source: .model,
            model: GuidedPedagogyPolicy.expectedRemoteModel
        )
        #expect(policy.validatedModelAction(inventedAdvance, for: supported) == nil)
    }

    @Test("Model prose is discarded and re-authored canonically in both languages")
    func canonicalizesRemoteProse() async throws {
        let report = try #require(makeGuidedPlannerTestReport())
        let candidate = GuidedNextPracticeAction(
            schemaVersion: 2,
            reportID: report.id,
            model: GuidedPedagogyPolicy.expectedRemoteModel,
            source: .model,
            action: .reduceScaffold,
            reason: .matchedWithSupport,
            explanationEN: "99% mastered",
            explanationES: "99% dominado",
            evidenceReasonEN: "perfect pronunciation",
            evidenceReasonES: "pronunciación perfecta",
            obligationID: report.scenePlan.obligationID
        )
        let planner = GuidedLearningPlanner(
            remote: StubGuidedRemotePlanner(result: .success(candidate))
        )

        let result = try await planner.improvedAction(for: report)

        #expect(result.source == .model)
        #expect(result.explanationEN == "Try the same exchange again with less visible help.")
        #expect(result.explanationES == "Haz el mismo intercambio otra vez con menos ayuda visible.")
        #expect(!result.explanationEN.contains("99"))
    }

    @Test("Broker sends the exact v2 report to the guided product endpoint")
    func boundedBrokerRequest() async throws {
        let report = try #require(makeGuidedPlannerTestReport())
        let response = GuidedPedagogyPolicy().make(
            report: report,
            action: .reduceScaffold,
            reason: .matchedWithSupport,
            source: .model,
            model: GuidedPedagogyPolicy.expectedRemoteModel
        )
        let planner = GuidedBrokerLearningPlanner(
            session: Self.mockSession(statusCode: 200, body: try JSONEncoder().encode(response)),
            endpoint: URL(string: "https://broker.example/learning/guided-next")!,
            credentials: StubGuidedPlannerCredentials(token: installToken)
        )

        let result = try await planner.requestNextAction(for: report)

        #expect(result == response)
        let request = try #require(GuidedPlannerURLProtocol.lastRequest)
        #expect(request.url?.path == "/learning/guided-next")
        #expect(request.timeoutInterval == GuidedBrokerLearningPlanner.requestTimeout)
        #expect(GuidedBrokerLearningPlanner.requestTimeout == 27)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(installToken)")
        #expect(request.value(forHTTPHeaderField: "Cache-Control") == "no-store")
        let body = try #require(GuidedPlannerURLProtocol.lastBody)
        #expect(try JSONDecoder().decode(GuidedLearningReport.self, from: body) == report)
    }

    @Test("Missing credentials and extra response fields fail closed")
    func brokerFailures() async throws {
        let report = try #require(makeGuidedPlannerTestReport())
        let missing = GuidedBrokerLearningPlanner(
            session: Self.mockSession(statusCode: 200, body: Data()),
            credentials: StubGuidedPlannerCredentials(token: nil)
        )
        await #expect(throws: GuidedBrokerLearningPlannerError.missingCredential) {
            try await missing.requestNextAction(for: report)
        }

        let action = GuidedPedagogyPolicy().make(
            report: report,
            action: .reduceScaffold,
            reason: .matchedWithSupport,
            source: .model,
            model: GuidedPedagogyPolicy.expectedRemoteModel
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(action)) as? [String: Any]
        )
        object["score"] = 100
        let extra = GuidedBrokerLearningPlanner(
            session: Self.mockSession(
                statusCode: 200,
                body: try JSONSerialization.data(withJSONObject: object)
            ),
            credentials: StubGuidedPlannerCredentials(token: installToken)
        )
        await #expect(throws: GuidedBrokerLearningPlannerError.invalidResponse) {
            try await extra.requestNextAction(for: report)
        }
    }

    private static func mockSession(statusCode: Int, body: Data) -> URLSession {
        GuidedPlannerURLProtocol.statusCode = statusCode
        GuidedPlannerURLProtocol.body = body
        GuidedPlannerURLProtocol.lastRequest = nil
        GuidedPlannerURLProtocol.lastBody = nil
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GuidedPlannerURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private enum GuidedPlannerTestError: Error, Sendable {
    case failed
}

private struct StubGuidedRemotePlanner: GuidedRemoteLearningPlanning {
    let result: Result<GuidedNextPracticeAction, GuidedPlannerTestError>

    func requestNextAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction {
        try result.get()
    }
}

private struct StubGuidedPlannerCredentials: PlannerInstallCredentialLoading {
    let token: String?

    func provisionFromProcessEnvironment() throws {}
    func loadToken() throws -> String? { token }
}

private final class GuidedPlannerURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? Self.read(request.httpBodyStream)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json", "Cache-Control": "no-store"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream?) -> Data? {
        guard let stream else { return nil }
        stream.open()
        defer { stream.close() }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 1_024)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count >= 0 else { return nil }
            if count == 0 { break }
            result.append(buffer, count: count)
        }
        return result
    }
}

private func guidedPlannerFacts(
    restaurantMatch: GuidedTargetMatch = .matched,
    scaffold: GuidedPracticeScaffold = .full
) -> [GuidedAttemptFact] {
    [
        GuidedAttemptFact(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000013")!,
            context: .taughtPhrase,
            attemptNumber: 1,
            targetMatch: .close,
            scaffold: .full
        ),
        GuidedAttemptFact(
            id: UUID(uuidString: "00000000-0000-4000-8000-000000000014")!,
            context: .restaurantTurn,
            attemptNumber: 2,
            targetMatch: restaurantMatch,
            scaffold: scaffold
        ),
    ]
}

private func makeGuidedPlannerTestReport(
    restaurantMatch: GuidedTargetMatch = .matched,
    scaffold: GuidedPracticeScaffold = .full
) -> GuidedLearningReport? {
    GuidedLearningReport.make(
        from: guidedPlannerFacts(restaurantMatch: restaurantMatch, scaffold: scaffold),
        id: UUID(uuidString: "00000000-0000-4000-8000-000000000011")!
    )
}
