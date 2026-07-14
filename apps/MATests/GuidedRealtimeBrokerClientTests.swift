import Foundation
import Testing
@testable import MA

@Suite("Guided Realtime broker client", .serialized)
struct GuidedRealtimeBrokerClientTests {
    private let token = String(repeating: "r", count: 48)
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test("Product mint sends only an empty body and private role token")
    func boundedProductMint() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "value": "ek_short_lived_secret",
            "expires_at": 2_000_000_120,
            "expected_configuration_hash": String(repeating: "a", count: 64),
        ])
        let client = GuidedRealtimeSessionBrokerClient(
            session: mockSession(statusCode: 200, body: body),
            endpoint: URL(string: "https://broker.example/product/realtime/client-secret")!,
            credentials: StubGuidedBrokerCredentials(token: token),
            now: { now }
        )

        let secret = try await client.mintClientSecret()

        #expect(secret.value == "ek_short_lived_secret")
        #expect(secret.expiresAt == 2_000_000_120)
        #expect(secret.expectedConfigurationHash == String(repeating: "a", count: 64))
        let request = try #require(GuidedBrokerURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/product/realtime/client-secret")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
        #expect(request.value(forHTTPHeaderField: "Cache-Control") == "no-store")
        #expect(GuidedBrokerURLProtocol.lastBody == Data("{}".utf8))
    }

    @Test("Missing credentials fail before a network request")
    func missingCredential() async {
        GuidedBrokerURLProtocol.lastRequest = nil
        let client = GuidedRealtimeSessionBrokerClient(
            session: mockSession(statusCode: 200, body: Data()),
            credentials: StubGuidedBrokerCredentials(token: nil),
            now: { now }
        )

        await #expect(throws: GuidedRealtimeError.missingCredential) {
            try await client.mintClientSecret()
        }
        #expect(GuidedBrokerURLProtocol.lastRequest == nil)
    }

    @Test(arguments: [401, 429, 503])
    func sanitizedStatusMapping(statusCode: Int) async {
        let client = GuidedRealtimeSessionBrokerClient(
            session: mockSession(
                statusCode: statusCode,
                body: Data(#"{"private":"detail"}"#.utf8)
            ),
            credentials: StubGuidedBrokerCredentials(token: token),
            now: { now }
        )
        let expected: GuidedRealtimeError = switch statusCode {
        case 401: .unauthorized
        case 429: .rateLimited
        default: .serviceUnavailable
        }

        await #expect(throws: expected) {
            try await client.mintClientSecret()
        }
    }

    @Test("Extra response fields and implausible expiry fail closed")
    func strictResponseShapeAndExpiry() async throws {
        let extra = try JSONSerialization.data(withJSONObject: [
            "value": "ek_secret",
            "expires_at": 2_000_000_120,
            "expected_configuration_hash": String(repeating: "a", count: 64),
            "provider": "do-not-forward",
        ])
        let farFuture = try JSONSerialization.data(withJSONObject: [
            "value": "ek_secret",
            "expires_at": 2_000_001_000,
            "expected_configuration_hash": String(repeating: "a", count: 64),
        ])

        for body in [extra, farFuture] {
            let client = GuidedRealtimeSessionBrokerClient(
                session: mockSession(statusCode: 200, body: body),
                credentials: StubGuidedBrokerCredentials(token: token),
                now: { now }
            )
            await #expect(throws: GuidedRealtimeError.invalidBrokerResponse) {
                try await client.mintClientSecret()
            }
        }
    }

    private func mockSession(statusCode: Int, body: Data) -> URLSession {
        GuidedBrokerURLProtocol.statusCode = statusCode
        GuidedBrokerURLProtocol.body = body
        GuidedBrokerURLProtocol.lastRequest = nil
        GuidedBrokerURLProtocol.lastBody = nil
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [GuidedBrokerURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private struct StubGuidedBrokerCredentials: PlannerInstallCredentialLoading {
    let token: String?

    func provisionFromProcessEnvironment() throws {}
    func loadToken() throws -> String? { token }
}

private final class GuidedBrokerURLProtocol: URLProtocol, @unchecked Sendable {
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
            headerFields: [
                "Content-Type": "application/json; charset=utf-8",
                "Cache-Control": "no-store",
            ]
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
