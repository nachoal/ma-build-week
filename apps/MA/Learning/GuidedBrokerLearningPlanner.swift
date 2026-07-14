import Foundation
import OSLog

enum GuidedBrokerLearningPlannerError: Error, Equatable, Sendable {
    case missingCredential
    case invalidReport
    case unauthorized
    case rateLimited
    case serviceUnavailable
    case invalidResponse
    case requestFailed

    var diagnosticCode: String {
        switch self {
        case .missingCredential: "missing_credential"
        case .invalidReport: "invalid_report"
        case .unauthorized: "unauthorized"
        case .rateLimited: "rate_limited"
        case .serviceUnavailable: "service_unavailable"
        case .invalidResponse: "invalid_response"
        case .requestFailed: "request_failed"
        }
    }
}

actor GuidedBrokerLearningPlanner: GuidedRemoteLearningPlanning {
    /// The Worker may make two bounded seven-second provider attempts. Leave
    /// enough room for both attempts plus the broker round trip while staying
    /// below the learner-visible 35-second terminal wait.
    static let requestTimeout: TimeInterval = 22

    static let endpoint = URL(
        string: "https://ma-session-broker.ignacio-alley.workers.dev/learning/guided-next"
    )!

    private let session: URLSession
    private let endpointURL: URL
    private let credentials: any PlannerInstallCredentialLoading
    private let diagnosticLogger = Logger(
        subsystem: "com.ia.ma",
        category: "GuidedPlannerBroker"
    )

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
            timeoutInterval: Self.requestTimeout
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
            let nsError = error as NSError
            diagnosticLogger.error(
                "transport_failed domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public)"
            )
            throw GuidedBrokerLearningPlannerError.requestFailed
        }
        guard let http = response as? HTTPURLResponse else {
            throw GuidedBrokerLearningPlannerError.invalidResponse
        }
        switch http.statusCode {
        case 200:
            diagnosticLogger.notice("response_succeeded")
        case 401:
            diagnosticLogger.error("response_failed code=unauthorized")
            throw GuidedBrokerLearningPlannerError.unauthorized
        case 429:
            diagnosticLogger.error("response_failed code=rate_limited")
            throw GuidedBrokerLearningPlannerError.rateLimited
        case 502, 503, 504:
            diagnosticLogger.error("response_failed code=service_unavailable")
            throw GuidedBrokerLearningPlannerError.serviceUnavailable
        default:
            diagnosticLogger.error(
                "response_failed code=unexpected_status status=\(http.statusCode, privacy: .public)"
            )
            throw GuidedBrokerLearningPlannerError.requestFailed
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
            diagnosticLogger.error("response_failed code=invalid_response")
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
