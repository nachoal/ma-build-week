import Foundation

struct RealtimeClientSecret: Sendable, Equatable {
    let value: String
    let expiresAt: Int
    let expectedConfigurationHash: String
}

enum SessionBrokerError: LocalizedError, Equatable {
    case invalidInstallCredential
    case unauthorized
    case rateLimited
    case serviceUnavailable
    case invalidResponse
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidInstallCredential:
            "The private probe credential is unavailable."
        case .unauthorized:
            "The private probe credential was rejected."
        case .rateLimited:
            "The session broker is temporarily rate limited."
        case .serviceUnavailable:
            "The session broker is temporarily unavailable."
        case .invalidResponse:
            "The session broker returned an invalid response."
        case .requestFailed:
            "The session broker request failed."
        }
    }
}

actor SessionBrokerClient {
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
    private let now: @Sendable () -> Date

    init(
        session: URLSession = URLSession(configuration: .ephemeral),
        endpoint: URL = ProbeConfiguration.brokerClientSecretURL,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.session = session
        self.endpoint = endpoint
        self.now = now
    }

    func mintClientSecret(installToken: String) async throws -> RealtimeClientSecret {
        guard installToken.count >= 32, installToken.count <= 512 else {
            throw SessionBrokerError.invalidInstallCredential
        }

        var request = URLRequest(
            url: endpoint,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 12
        )
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue("Bearer \(installToken)", forHTTPHeaderField: "Authorization")
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
            throw SessionBrokerError.requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SessionBrokerError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw SessionBrokerError.unauthorized
        case 429:
            throw SessionBrokerError.rateLimited
        case 502, 503, 504:
            throw SessionBrokerError.serviceUnavailable
        default:
            throw SessionBrokerError.requestFailed
        }

        guard data.count <= 8_192,
              let decoded = try? JSONDecoder().decode(Response.self, from: data),
              !decoded.value.isEmpty,
              decoded.expectedConfigurationHash.range(
                of: #"^[a-f0-9]{64}$"#,
                options: .regularExpression
              ) != nil else {
            throw SessionBrokerError.invalidResponse
        }

        let currentSeconds = Int(now().timeIntervalSince1970)
        guard decoded.expiresAt > currentSeconds + 5,
              decoded.expiresAt <= currentSeconds + 300 else {
            throw SessionBrokerError.invalidResponse
        }

        return RealtimeClientSecret(
            value: decoded.value,
            expiresAt: decoded.expiresAt,
            expectedConfigurationHash: decoded.expectedConfigurationHash
        )
    }
}
