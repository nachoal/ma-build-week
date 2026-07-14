import Darwin
import Foundation
import OSLog
import SwiftUI

@main
struct MAApp: App {
    init() {
        let credentialStore = PlannerInstallCredentialStore()
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        let deleteRequested = environment["MA_UI_TEST_DELETE_INSTALL_TOKEN"] == "true"
        let provisioningWillFollow = environment[PlannerInstallCredentialStore.environmentKey] != nil
        let deletionSucceeded = !deleteRequested || Self.deleteTestCredential(
            using: credentialStore,
            provisioningWillFollow: provisioningWillFollow
        )
        #else
        let deletionSucceeded = true
        #endif

        if deletionSucceeded {
            do {
                try credentialStore.provisionFromProcessEnvironment()
                #if DEBUG
                if environment["MA_UI_TEST_PROVISION_ONLY"] == "true",
                   try credentialStore.loadToken() != nil {
                    try Self.removeItemIfPresent(at: Self.credentialDeletedSentinelURL)
                    try Data("ready".utf8).write(
                        to: Self.credentialReadySentinelURL,
                        options: .atomic
                    )
                }
                #endif
            } catch PlannerCredentialError.keychain(let status) {
                Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                    "provision_failed keychain_status=\(status, privacy: .public)"
                )
            } catch {
                Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                    "provision_failed invalid_input_or_confirmation"
                )
            }
        } else {
            // The provisioning store normally clears this in a defer. If the
            // prerequisite deletion failed, do not leave the launch-only
            // credential resident in the app process environment.
            unsetenv(PlannerInstallCredentialStore.environmentKey)
        }

        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] == "true" {
            UserDefaults.standard.removeObject(forKey: "ma.interface.language")
        }
        #endif
    }

    #if DEBUG
    private static func deleteTestCredential(
        using credentialStore: PlannerInstallCredentialStore,
        provisioningWillFollow: Bool
    ) -> Bool {
        do {
            // Delete the old proof first. A crash or a locked-device launch can
            // therefore never leave a stale marker that looks like success.
            try removeItemIfPresent(at: credentialDeletedSentinelURL)
            try credentialStore.deleteToken()
            guard try credentialStore.loadToken() == nil else {
                throw CredentialConfirmationError.deletionNotVerified
            }
            try removeItemIfPresent(at: credentialReadySentinelURL)
            if !provisioningWillFollow {
                try Data("deleted".utf8).write(
                    to: credentialDeletedSentinelURL,
                    options: .atomic
                )
            }
            return true
        } catch PlannerCredentialError.keychain(let status) {
            Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                "test_cleanup_failed keychain_status=\(status, privacy: .public)"
            )
        } catch {
            Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                "test_cleanup_failed verification_or_confirmation"
            )
        }
        return false
    }

    private static func removeItemIfPresent(at url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private static var credentialReadySentinelURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ma-private-credential-ready")
    }

    private static var credentialDeletedSentinelURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ma-private-credential-deleted")
    }

    private enum CredentialConfirmationError: Error {
        case deletionNotVerified
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .preferredColorScheme(.light)
        }
    }
}
