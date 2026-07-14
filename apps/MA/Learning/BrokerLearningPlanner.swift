import Foundation

enum BrokerLearningPlannerError: Error, Equatable, Sendable {
    case missingCredential
    case invalidReport
    case unauthorized
    case rateLimited
    case serviceUnavailable
    case invalidResponse
    case requestFailed
}

protocol RemoteLearningPlanning: Sendable {
    func requestNextAction(for report: LearningReport) async throws -> NextLearningAction
}

actor BrokerLearningPlanner: RemoteLearningPlanning {
    static let endpoint = URL(
        string: "https://ma-session-broker.ignacio-alley.workers.dev/learning/next"
    )!

    private let session: URLSession
    private let endpointURL: URL
    private let credentials: any PlannerInstallCredentialLoading

    init(
        session: URLSession = URLSession(configuration: .ephemeral),
        endpoint: URL = BrokerLearningPlanner.endpoint,
        credentials: any PlannerInstallCredentialLoading = PlannerInstallCredentialStore()
    ) {
        self.session = session
        endpointURL = endpoint
        self.credentials = credentials
    }

    func requestNextAction(
        for report: LearningReport
    ) async throws -> NextLearningAction {
        guard report.isValidForPlannerTransport else {
            throw BrokerLearningPlannerError.invalidReport
        }
        guard let token = try credentials.loadToken(),
              PlannerInstallCredentialStore.isValid(token: token) else {
            throw BrokerLearningPlannerError.missingCredential
        }

        let body: Data
        do {
            body = try JSONEncoder().encode(report)
        } catch {
            throw BrokerLearningPlannerError.invalidReport
        }
        guard body.count <= 16_384 else {
            throw BrokerLearningPlannerError.invalidReport
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
            if Task.isCancelled {
                throw CancellationError()
            }
            throw BrokerLearningPlannerError.requestFailed
        }

        guard let http = response as? HTTPURLResponse else {
            throw BrokerLearningPlannerError.invalidResponse
        }
        switch http.statusCode {
        case 200:
            break
        case 401:
            throw BrokerLearningPlannerError.unauthorized
        case 429:
            throw BrokerLearningPlannerError.rateLimited
        case 502, 503, 504:
            throw BrokerLearningPlannerError.serviceUnavailable
        default:
            throw BrokerLearningPlannerError.requestFailed
        }

        guard http.value(forHTTPHeaderField: "Content-Type")?
            .lowercased().hasPrefix("application/json") == true,
              data.count <= 8_192,
              Self.hasExactResponseKeys(data),
              let action = try? JSONDecoder().decode(NextLearningAction.self, from: data),
              action.schemaVersion == 1,
              action.reportID == report.id,
              action.model == DeterministicPedagogyPolicy.expectedRemoteModel,
              action.source == .model else {
            throw BrokerLearningPlannerError.invalidResponse
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
            "explanation_es",
            "evidence_reason_es",
            "obligation_id",
        ])
    }
}
