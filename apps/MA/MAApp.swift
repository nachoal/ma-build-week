import Foundation
import OSLog
import SwiftUI

@main
struct MAApp: App {
    init() {
        let credentialStore = PlannerInstallCredentialStore()
        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_DELETE_INSTALL_TOKEN"] == "true" {
            try? credentialStore.deleteToken()
            try? FileManager.default.removeItem(at: Self.credentialSentinelURL)
        }
        #endif

        do {
            try credentialStore.provisionFromProcessEnvironment()
            #if DEBUG
            if ProcessInfo.processInfo.environment["MA_UI_TEST_PROVISION_ONLY"] == "true",
               try credentialStore.loadToken() != nil {
                try Data("ready".utf8).write(
                    to: Self.credentialSentinelURL,
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
                "provision_failed invalid_input"
            )
        }

        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] == "true" {
            UserDefaults.standard.removeObject(forKey: "ma.interface.language")
        }
        #endif
    }

    #if DEBUG
    private static var credentialSentinelURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ma-private-credential-ready")
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .preferredColorScheme(.light)
        }
    }
}
