import SwiftUI

@main
struct MAAudioProbeApp: App {
    @State private var model = ProbeAppModel()

    var body: some Scene {
        WindowGroup {
            ProbeGateView(model: model)
                .task {
                    let environment = ProcessInfo.processInfo.environment
                    model.prepareCredentials(environment: environment)
                    guard environment[ProbeConfiguration.autoStartEnvironmentKey] == "1" else {
                        return
                    }
                    await model.startLiveProbe()
                    if model.runStatus == .active,
                       environment[ProbeConfiguration.autoRequestTutorEnvironmentKey] == "1" {
                        await model.requestTutor()
                    }
                }
        }
    }
}
