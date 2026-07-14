import Testing
@testable import MAAudioProbe

@MainActor
@Suite("Probe app model")
struct ProbeAppModelTests {
    @Test("Missing launch credential produces an actionable state")
    func missingCredential() {
        let model = ProbeAppModel(credentialStore: StubCredentialStore(result: .missing))

        model.prepareCredentials(environment: [:])

        #expect(model.credentialStatus == .missing)
        #expect(model.credentialStatus.label == "launch provisioning required")
    }
}

private struct StubCredentialStore: InstallCredentialStoring {
    let result: InstallCredentialProvisioningResult

    func provisionFromProcessEnvironment(
        _ environment: [String: String]
    ) throws -> InstallCredentialProvisioningResult {
        result
    }

    func loadToken() throws -> String? {
        nil
    }
}
