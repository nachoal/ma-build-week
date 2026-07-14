import Foundation
import SwiftUI

@main
struct MAApp: App {
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["MA_UI_TEST_RESET_INTERFACE_LANGUAGE"] == "true" {
            UserDefaults.standard.removeObject(forKey: "ma.interface.language")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .preferredColorScheme(.light)
        }
    }
}
