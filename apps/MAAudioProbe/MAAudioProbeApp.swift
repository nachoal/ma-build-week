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
                        if environment[ProbeConfiguration.autoStopEnvironmentKey] == "1" {
                            await runAutomatedStopSequence()
                        }
                    }
                }
        }
    }

    @MainActor
    private func runAutomatedStopSequence() async {
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        while model.scheduledTutorFrameCount < 12_000,
              model.runStatus == .active,
              ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard model.scheduledTutorFrameCount >= 12_000,
              model.runStatus == .active else {
            await model.prepareEvidenceExport()
            return
        }
        try? await Task.sleep(for: .milliseconds(200))
        await model.localStop()
        await model.prepareEvidenceExport()
    }
}
