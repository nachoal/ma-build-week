import Darwin
import Foundation
import OSLog
import SwiftUI

@main
struct MAApp: App {
    init() {
        let credentialStore = PlannerInstallCredentialStore()
        let environment = ProcessInfo.processInfo.environment
        let provisioningRequested = environment[PlannerInstallCredentialStore.environmentKey] != nil
        let provisioningNonce = ProductInstallProvisioningMarker.validatedNonce(
            environment[ProductInstallProvisioningMarker.environmentKey]
        )
        do {
            try ProductInstallProvisioningMarker.removeReceipts(
                in: ProductInstallProvisioningMarker.documentsDirectory
            )
        } catch {
            Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                "provision_receipt_cleanup_failed"
            )
        }
        unsetenv(ProductInstallProvisioningMarker.environmentKey)

        #if DEBUG
        let deleteRequested = environment["MA_UI_TEST_DELETE_INSTALL_TOKEN"] == "true"
        let provisioningWillFollow = environment[PlannerInstallCredentialStore.environmentKey] != nil
        let deletionSucceeded = !deleteRequested || Self.deleteTestCredential(
            using: credentialStore,
            provisioningWillFollow: provisioningWillFollow
        )
        if deletionSucceeded {
            Self.provision(
                credentialStore: credentialStore,
                environment: environment,
                provisioningRequested: provisioningRequested,
                provisioningNonce: provisioningNonce
            )
        } else {
            // The provisioning store normally clears this in a defer. If the
            // prerequisite deletion failed, do not leave the launch-only
            // credential resident in the app process environment.
            unsetenv(PlannerInstallCredentialStore.environmentKey)
        }
        #else
        Self.provision(
            credentialStore: credentialStore,
            environment: environment,
            provisioningRequested: provisioningRequested,
            provisioningNonce: provisioningNonce
        )
        #endif

        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_SEED_ONBOARDING_COMPLETED"]
            == "true" {
            UserDefaults.standard.set(true, forKey: "ma.onboarding.completed")
        }
        if ProcessInfo.processInfo.environment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] == "true" {
            UserDefaults.standard.removeObject(forKey: "ma.interface.language")
        }
        #endif
    }

    private static func provision(
        credentialStore: PlannerInstallCredentialStore,
        environment: [String: String],
        provisioningRequested: Bool,
        provisioningNonce: String?
    ) {
        do {
            try credentialStore.provisionFromProcessEnvironment()
            if let provisioningNonce {
                if provisioningRequested {
                    try ProductInstallProvisioningMarker.writeStoredReceipt(
                        nonce: provisioningNonce,
                        in: ProductInstallProvisioningMarker.documentsDirectory
                    )
                } else {
                    verifyPrivateReviewAccess(
                        nonce: provisioningNonce,
                        credentialStore: credentialStore
                    )
                }
            }
            #if DEBUG
            if environment["MA_UI_TEST_PROVISION_ONLY"] == "true",
               try credentialStore.loadToken() != nil {
                try removeItemIfPresent(at: credentialDeletedSentinelURL)
                try Data("ready".utf8).write(
                    to: credentialReadySentinelURL,
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
    }

    private static func verifyPrivateReviewAccess(
        nonce: String,
        credentialStore: PlannerInstallCredentialStore
    ) {
        Task {
            let provider = DidacticRealtimeProvider(
                broker: GuidedRealtimeSessionBrokerClient(
                    credentials: credentialStore
                )
            )
            do {
                // This credential-free verification launch must load the token
                // from Keychain, mint a short-lived secret, open the Realtime
                // WebSocket, and verify the session.created policy hash.
                try await provider.connect()
                await provider.disconnect()
                try ProductInstallProvisioningMarker.writeReadyReceipt(
                    nonce: nonce,
                    in: ProductInstallProvisioningMarker.documentsDirectory
                )
                Logger(subsystem: "com.ia.ma", category: "PrivateCredential").notice(
                    "private_review_access_verified"
                )
            } catch let error as GuidedRealtimeError {
                await provider.disconnect()
                Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                    "private_review_access_failed code=\(error.diagnosticCode, privacy: .public)"
                )
            } catch {
                await provider.disconnect()
                Logger(subsystem: "com.ia.ma", category: "PrivateCredential").error(
                    "private_review_access_failed code=unexpected"
                )
            }
        }
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
            try credentialStore.deleteTokenAndVerify()
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
    #endif

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .preferredColorScheme(.light)
        }
    }
}
