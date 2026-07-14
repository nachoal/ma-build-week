import Foundation
import Observation

enum ProbeCredentialStatus: Equatable {
    case checking
    case ready
    case missing
    case failed

    var label: String {
        switch self {
        case .checking:
            "checking"
        case .ready:
            "provisioned in Keychain"
        case .missing:
            "launch provisioning required"
        case .failed:
            "secure storage unavailable"
        }
    }
}

@MainActor
@Observable
final class ProbeAppModel {
    private let credentialStore: any InstallCredentialStoring

    var credentialStatus: ProbeCredentialStatus = .checking

    init(credentialStore: any InstallCredentialStoring = InstallCredentialStore()) {
        self.credentialStore = credentialStore
    }

    func prepareCredentials(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        do {
            let result = try credentialStore.provisionFromProcessEnvironment(environment)
            credentialStatus = result == .missing ? .missing : .ready
        } catch {
            credentialStatus = .failed
        }
    }
}
