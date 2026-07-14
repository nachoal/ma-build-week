import Foundation
import Testing
@testable import MAAudioProbe

@Suite("Realtime policy verifier")
struct RealtimePolicyVerifierTests {
    private let workerPolicyHash = "c21f6f941eea87222619b915285fb965eae52b1529948dc31585dd6061b857d6"

    @Test("Swift canonical policy matches the deployed Worker policy")
    func canonicalHashMatchesWorker() throws {
        let hash = try RealtimePolicyVerifier.configurationHash(
            for: FixedRealtimeSessionPolicy.expected
        )

        #expect(hash == workerPolicyHash)
    }

    @Test("Session events verify only when the projected policy is unchanged")
    func sessionVerification() throws {
        let matching = try eventData(policy: .expected)
        let verification = try RealtimePolicyVerifier.verify(
            eventData: matching,
            expectedHash: workerPolicyHash
        )
        #expect(verification.matches)

        var changedObject = try #require(
            JSONSerialization.jsonObject(with: matching) as? [String: Any]
        )
        var session = try #require(changedObject["session"] as? [String: Any])
        session["model"] = "different-model"
        changedObject["session"] = session
        let changed = try JSONSerialization.data(withJSONObject: changedObject)

        let changedVerification = try RealtimePolicyVerifier.verify(
            eventData: changed,
            expectedHash: workerPolicyHash
        )
        #expect(!changedVerification.matches)
    }

    @Test("Wrong event types and malformed expected hashes fail closed")
    func invalidInputsFailClosed() throws {
        let event = try eventData(policy: .expected, type: "response.created")
        #expect(throws: RealtimePolicyVerificationError.unsupportedEventType) {
            try RealtimePolicyVerifier.verify(eventData: event, expectedHash: workerPolicyHash)
        }
        #expect(throws: RealtimePolicyVerificationError.invalidExpectedHash) {
            try RealtimePolicyVerifier.verify(eventData: event, expectedHash: "short")
        }
    }

    private func eventData(
        policy: FixedRealtimeSessionPolicy,
        type: String = "session.created"
    ) throws -> Data {
        let encoder = JSONEncoder()
        let policyData = try encoder.encode(policy)
        let policyObject = try JSONSerialization.jsonObject(with: policyData)
        return try JSONSerialization.data(
            withJSONObject: [
                "type": type,
                "event_id": "evt_safe",
                "session": policyObject,
            ]
        )
    }
}
