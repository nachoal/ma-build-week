import SwiftUI

@main
struct MAAudioProbeApp: App {
    @State private var model = ProbeAppModel()

    var body: some Scene {
        WindowGroup {
            ProbeGateView(model: model)
                .task {
                    model.prepareCredentials()
                }
        }
    }
}
