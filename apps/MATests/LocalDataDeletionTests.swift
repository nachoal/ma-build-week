import Foundation
import Testing
@testable import MA

@Suite("Verified local data deletion", .serialized)
struct LocalDataDeletionTests {
    private enum TestFailure: Error, Equatable {
        case blocked
    }

    @Test("Local state resets only after verified credential deletion")
    func resetIsCommitAfterDeletion() throws {
        var resetCount = 0
        try LocalDataDeletionTransaction(deleteCredential: {}).perform {
            resetCount += 1
        }
        #expect(resetCount == 1)

        #expect(throws: TestFailure.blocked) {
            try LocalDataDeletionTransaction(deleteCredential: {
                throw TestFailure.blocked
            }).perform {
                resetCount += 1
            }
        }
        #expect(resetCount == 1)
    }

    @Test("Deletion verification propagates delete and reload failures")
    func verificationPropagatesFailures() {
        var loadCalls = 0
        #expect(throws: TestFailure.blocked) {
            try PlannerInstallCredentialStore.verifyDeletion(
                delete: { throw TestFailure.blocked },
                load: {
                    loadCalls += 1
                    return nil
                }
            )
        }
        #expect(loadCalls == 0)

        #expect(throws: TestFailure.blocked) {
            try PlannerInstallCredentialStore.verifyDeletion(
                delete: {},
                load: { throw TestFailure.blocked }
            )
        }
    }

    @Test("A credential still present after delete fails closed")
    func credentialStillPresentFailsClosed() {
        #expect(throws: PlannerCredentialError.deletionNotVerified) {
            try PlannerInstallCredentialStore.verifyDeletion(
                delete: {},
                load: { String(repeating: "x", count: 48) }
            )
        }
    }

    @Test("The real Keychain store deletes and reloads a dummy credential")
    func keychainIntegration() throws {
        let store = PlannerInstallCredentialStore(
            service: "com.ia.ma.tests.\(UUID().uuidString)",
            account: "dummy-delete-verification"
        )
        defer { try? store.deleteToken() }
        let dummyToken = String(repeating: "d", count: 48)

        try store.saveTokenForTesting(dummyToken)
        #expect(try store.loadToken() == dummyToken)
        try store.deleteTokenAndVerify()
        #expect(try store.loadToken() == nil)
    }
}
