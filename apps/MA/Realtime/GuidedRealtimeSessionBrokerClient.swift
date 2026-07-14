import Foundation
import OSLog

protocol GuidedRealtimeSecretMinting: Sendable {
    func mintClientSecret() async throws -> GuidedRealtimeClientSecret
}

actor GuidedRealtimeSessionBrokerClient: GuidedRealtimeSecretMinting {
    static let endpoint = URL(
        string: "https://ma-session-broker.ignacio-alley.workers.dev/product/realtime/client-secret"
    )!

    private struct Response: Decodable {
        let value: String
        let expiresAt: Int
        let expectedConfigurationHash: String

        enum CodingKeys: String, CodingKey {
            case value
            case expiresAt = "expires_at"
            case expectedConfigurationHash = "expected_configuration_hash"
        }
    }

    private let session: URLSession
    private let endpoint: URL
    private let credentials: any PlannerInstallCredentialLoading
    private let now: @Sendable () -> Date
    private let diagnosticLogger = Logger(
        subsystem: "com.ia.ma",
        category: "GuidedRealtimeBroker"
    )

    init(
        session: URLSession = URLSession(configuration: .ephemeral),
        endpoint: URL = GuidedRealtimeSessionBrokerClient.endpoint,
        credentials: any PlannerInstallCredentialLoading = PlannerInstallCredentialStore(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.session = session
        self.endpoint = endpoint
        self.credentials = credentials
        self.now = now
    }

    func mintClientSecret() async throws -> GuidedRealtimeClientSecret {
        let storedToken: String?
        do {
            storedToken = try credentials.loadToken()
        } catch PlannerCredentialError.keychain(let status) {
            diagnosticLogger.error(
                "credential_load_failed keychain_status=\(status, privacy: .public)"
            )
            throw GuidedRealtimeError.missingCredential
        } catch {
            diagnosticLogger.error("credential_load_failed invalid_value")
            throw GuidedRealtimeError.missingCredential
        }
        guard let token = storedToken,
              PlannerInstallCredentialStore.isValid(token: token) else {
            throw GuidedRealtimeError.missingCredential
        }

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 12
        )
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw GuidedRealtimeError.serviceUnavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw GuidedRealtimeError.invalidBrokerResponse
        }
        switch http.statusCode {
        case 200:
            break
        case 401:
            throw GuidedRealtimeError.unauthorized
        case 429:
            throw GuidedRealtimeError.rateLimited
        case 502, 503, 504:
            throw GuidedRealtimeError.serviceUnavailable
        default:
            throw GuidedRealtimeError.invalidBrokerResponse
        }

        guard http.value(forHTTPHeaderField: "Content-Type")?
            .lowercased().hasPrefix("application/json") == true,
              data.count <= 8_192,
              Self.hasExactResponseKeys(data),
              let decoded = try? JSONDecoder().decode(Response.self, from: data),
              !decoded.value.isEmpty,
              decoded.value.count <= 2_048,
              decoded.expectedConfigurationHash.range(
                  of: #"^[a-f0-9]{64}$"#,
                  options: .regularExpression
              ) != nil else {
            throw GuidedRealtimeError.invalidBrokerResponse
        }

        let currentSeconds = Int(now().timeIntervalSince1970)
        guard decoded.expiresAt > currentSeconds + 5,
              decoded.expiresAt <= currentSeconds + 300 else {
            throw GuidedRealtimeError.invalidBrokerResponse
        }
        diagnosticLogger.notice("mint_succeeded")
        return GuidedRealtimeClientSecret(
            value: decoded.value,
            expiresAt: decoded.expiresAt,
            expectedConfigurationHash: decoded.expectedConfigurationHash
        )
    }

    private static func hasExactResponseKeys(_ data: Data) -> Bool {
        guard let value = try? JSONSerialization.jsonObject(with: data),
              let object = value as? [String: Any] else { return false }
        return Set(object.keys) == Set([
            "value",
            "expires_at",
            "expected_configuration_hash",
        ])
    }
}
