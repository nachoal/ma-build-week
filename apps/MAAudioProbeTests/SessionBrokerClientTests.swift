import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Session broker client", .serialized)
struct SessionBrokerClientTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)
    private let installToken = String(repeating: "t", count: 48)

    @Test("Provisioning accepts only a bounded non-empty launch token")
    func provisioningValidation() {
        #expect(InstallTokenProvisioning.normalizedToken(in: [:]) == nil)
        #expect(InstallTokenProvisioning.normalizedToken(in: ["MA_INSTALL_TOKEN": "short"]) == nil)
        #expect(
            InstallTokenProvisioning.normalizedToken(
                in: ["MA_INSTALL_TOKEN": "  \(installToken)\n"]
            ) == installToken
        )
    }

    @Test("Mint request sends only the private credential and empty policy body")
    func requestIsBounded() async throws {
        let session = Self.mockSession(
            statusCode: 200,
            body: Self.validResponse(expiresAt: 2_000_000_120)
        )
        let client = SessionBrokerClient(
            session: session,
            endpoint: URL(string: "https://broker.example/realtime/client-secret")!,
            now: { now }
        )

        let secret = try await client.mintClientSecret(installToken: installToken)

        #expect(secret.value == "ephemeral-test-value")
        #expect(secret.expiresAt == 2_000_000_120)
        let request = try #require(BrokerURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/realtime/client-secret")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(installToken)")
        #expect(BrokerURLProtocol.lastBody == Data("{}".utf8))
    }

    @Test(arguments: [401, 429, 503])
    func mapsSanitizedServiceErrors(statusCode: Int) async {
        let client = SessionBrokerClient(
            session: Self.mockSession(statusCode: statusCode, body: #"{"private":"detail"}"#),
            now: { now }
        )
        let expected: SessionBrokerError = switch statusCode {
        case 401: .unauthorized
        case 429: .rateLimited
        default: .serviceUnavailable
        }

        await #expect(throws: expected) {
            try await client.mintClientSecret(installToken: installToken)
        }
    }

    @Test("Rejects an expired or unexpectedly long-lived secret")
    func rejectsInvalidExpiry() async {
        for expiry in [1_999_999_999, 2_000_000_301] {
            let client = SessionBrokerClient(
                session: Self.mockSession(
                    statusCode: 200,
                    body: Self.validResponse(expiresAt: expiry)
                ),
                now: { now }
            )
            await #expect(throws: SessionBrokerError.invalidResponse) {
                try await client.mintClientSecret(installToken: installToken)
            }
        }
    }

    private static func validResponse(expiresAt: Int) -> String {
        """
        {
          "value": "ephemeral-test-value",
          "expires_at": \(expiresAt),
          "expected_configuration_hash": "\(String(repeating: "a", count: 64))"
        }
        """
    }

    private static func mockSession(statusCode: Int, body: String) -> URLSession {
        BrokerURLProtocol.statusCode = statusCode
        BrokerURLProtocol.body = Data(body.utf8)
        BrokerURLProtocol.lastRequest = nil
        BrokerURLProtocol.lastBody = nil

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [BrokerURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class BrokerURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

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
