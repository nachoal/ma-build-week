import Foundation

enum GuidedBrokerLearningPlannerError: Error, Equatable, Sendable {
    case missingCredential
    case invalidReport
    case unauthorized
    case rateLimited
    case serviceUnavailable
    case invalidResponse
    case requestFailed
}

actor GuidedBrokerLearningPlanner: GuidedRemoteLearningPlanning {
    static let endpoint = URL(
        string: "https://ma-session-broker.ignacio-alley.workers.dev/learning/guided-next"
    )!

    private let session: URLSession
    private let endpointURL: URL
    private let credentials: any PlannerInstallCredentialLoading

    init(
        session: URLSession = URLSession(configuration: .ephemeral),
        endpoint: URL = GuidedBrokerLearningPlanner.endpoint,
        credentials: any PlannerInstallCredentialLoading = PlannerInstallCredentialStore()
    ) {
        self.session = session
        endpointURL = endpoint
        self.credentials = credentials
    }

    func requestNextAction(
        for report: GuidedLearningReport
    ) async throws -> GuidedNextPracticeAction {
        guard report.isValidForPlannerTransport else {
            throw GuidedBrokerLearningPlannerError.invalidReport
        }
        guard let token = try credentials.loadToken(),
              PlannerInstallCredentialStore.isValid(token: token) else {
            throw GuidedBrokerLearningPlannerError.missingCredential
        }

        guard let body = try? JSONEncoder().encode(report),
              body.count <= 16_384 else {
            throw GuidedBrokerLearningPlannerError.invalidReport
        }
        var request = URLRequest(
            url: endpointURL,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 16
        )
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw GuidedBrokerLearningPlannerError.requestFailed
        }
        guard let http = response as? HTTPURLResponse else {
            throw GuidedBrokerLearningPlannerError.invalidResponse
        }
        switch http.statusCode {
        case 200: break
        case 401: throw GuidedBrokerLearningPlannerError.unauthorized
        case 429: throw GuidedBrokerLearningPlannerError.rateLimited
        case 502, 503, 504: throw GuidedBrokerLearningPlannerError.serviceUnavailable
        default: throw GuidedBrokerLearningPlannerError.requestFailed
        }

        guard http.value(forHTTPHeaderField: "Content-Type")?
            .lowercased().hasPrefix("application/json") == true,
              data.count <= 8_192,
              Self.hasExactResponseKeys(data),
              let action = try? JSONDecoder().decode(GuidedNextPracticeAction.self, from: data),
              action.schemaVersion == 2,
              action.reportID == report.id,
              action.model == GuidedPedagogyPolicy.expectedRemoteModel,
              action.source == .model else {
            throw GuidedBrokerLearningPlannerError.invalidResponse
        }
        return action
    }

    private static func hasExactResponseKeys(_ data: Data) -> Bool {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else { return false }
        return Set(dictionary.keys) == Set([
            "schema_version",
            "report_id",
            "model",
            "source",
            "action",
            "reason",
            "explanation_en",
            "explanation_es",
            "evidence_reason_en",
            "evidence_reason_es",
            "obligation_id",
        ])
    }
}
