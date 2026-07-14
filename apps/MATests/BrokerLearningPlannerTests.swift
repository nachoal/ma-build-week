import Foundation
import Testing
@testable import MA

@Suite("Learning broker client", .serialized)
struct BrokerLearningPlannerTests {
    private let installToken = String(repeating: "p", count: 48)

    @Test("Request sends only the bounded report and private authorization")
    func boundedRequest() async throws {
        let report = makePlannerTestReport()
        let response = DeterministicPedagogyPolicy().make(
            report: report,
            action: .advance,
            reason: .completedAfterRepair,
            source: .model,
            model: "gpt-5.6-sol"
        )
        let data = try JSONEncoder().encode(response)
        let planner = BrokerLearningPlanner(
            session: Self.mockSession(statusCode: 200, body: data),
            endpoint: URL(string: "https://broker.example/learning/next")!,
            credentials: StubPlannerCredentials(token: installToken)
        )

        let result = try await planner.requestNextAction(for: report)

        #expect(result == response)
        let request = try #require(LearningURLProtocol.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/learning/next")
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "Bearer \(installToken)"
        )
        #expect(request.value(forHTTPHeaderField: "Cache-Control") == "no-store")
        let requestBody = try #require(LearningURLProtocol.lastBody)
        #expect(try JSONDecoder().decode(LearningReport.self, from: requestBody) == report)
        let bodyText = try #require(String(data: requestBody, encoding: .utf8))
        #expect(!bodyText.contains(installToken))
        #expect(!bodyText.contains("transcript"))
    }

    @Test("Missing credential fails before any request")
    func missingCredential() async {
        LearningURLProtocol.lastRequest = nil
        let planner = BrokerLearningPlanner(
            session: Self.mockSession(statusCode: 200, body: Data()),
            credentials: StubPlannerCredentials(token: nil)
        )

        await #expect(throws: BrokerLearningPlannerError.missingCredential) {
            try await planner.requestNextAction(for: makePlannerTestReport())
        }
        #expect(LearningURLProtocol.lastRequest == nil)
    }

    @Test(arguments: [401, 429, 503])
    func mapsSanitizedErrors(statusCode: Int) async {
        let planner = BrokerLearningPlanner(
            session: Self.mockSession(
                statusCode: statusCode,
                body: Data(#"{"private":"detail"}"#.utf8)
            ),
            credentials: StubPlannerCredentials(token: installToken)
        )
        let expected: BrokerLearningPlannerError = switch statusCode {
        case 401: .unauthorized
        case 429: .rateLimited
        default: .serviceUnavailable
        }

        await #expect(throws: expected) {
            try await planner.requestNextAction(for: makePlannerTestReport())
        }
    }

    @Test("Extra response fields are rejected before model output is trusted")
    func rejectsExtraResponseFields() async throws {
        let report = makePlannerTestReport()
        let action = DeterministicPedagogyPolicy().make(
            report: report,
            action: .advance,
            reason: .completedAfterRepair,
            source: .model,
            model: "gpt-5.6-sol"
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(action))
                as? [String: Any]
        )
        object["score"] = 99
        let data = try JSONSerialization.data(withJSONObject: object)
        let planner = BrokerLearningPlanner(
            session: Self.mockSession(statusCode: 200, body: data),
            credentials: StubPlannerCredentials(token: installToken)
        )

        await #expect(throws: BrokerLearningPlannerError.invalidResponse) {
            try await planner.requestNextAction(for: report)
        }
    }

    @Test("Install token validation is bounded and whitespace-free")
    func credentialValidation() {
        #expect(!PlannerInstallCredentialStore.isValid(token: "short"))
        #expect(!PlannerInstallCredentialStore.isValid(
            token: String(repeating: "x", count: 31) + " "
        ))
        #expect(PlannerInstallCredentialStore.isValid(token: installToken))
    }

    private static func mockSession(
        statusCode: Int,
        body: Data
    ) -> URLSession {
        LearningURLProtocol.statusCode = statusCode
        LearningURLProtocol.body = body
        LearningURLProtocol.lastRequest = nil
        LearningURLProtocol.lastBody = nil

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LearningURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private struct StubPlannerCredentials: PlannerInstallCredentialLoading {
    let token: String?

    func provisionFromProcessEnvironment() throws {}
    func loadToken() throws -> String? { token }
}

private final class LearningURLProtocol: URLProtocol, @unchecked Sendable {
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
