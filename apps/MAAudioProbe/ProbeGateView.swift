import SwiftUI
import UIKit

enum ProbeGateState {
    static let liveProductBindingUnlocked = false
    static let gateLabel = "running — PARTIAL transport pending"
}

struct ProbeGateView: View {
    let model: ProbeAppModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section("Existential question") {
                    Text("Can a physical iPhone hear a harmless Japanese backchannel without stopping tutor audio, yet yield promptly to a real interruption?")
                }

                Section("Required proof") {
                    Label("はい is captured during output", systemImage: "waveform.badge.mic")
                    Label("Tutor playback remains continuous", systemImage: "speaker.wave.3")
                    Label("すみません takes the floor promptly", systemImage: "hand.raised")
                    Label("The last heard four-second beat is replayable", systemImage: "gobackward.5")
                    Label("Nine of ten randomized trials pass", systemImage: "checkmark.seal")
                }

                Section("Status") {
                    LabeledContent(
                        "Gate",
                        value: ProbeGateState.liveProductBindingUnlocked
                            ? "live binding unlocked by written verdict"
                            : ProbeGateState.gateLabel
                    )
                    LabeledContent("Target", value: "Physical iPhone")
                    LabeledContent("Broker credential", value: model.credentialStatus.label)
                    LabeledContent("Probe", value: model.runStatus.label)
                    LabeledContent("Graph hash", value: String(model.graphConfigurationHash.prefix(12)))
                    LabeledContent(
                        "Mic PCM sent",
                        value: "\(model.sentMicrophoneFrameCount) frames"
                    )
                    LabeledContent(
                        "Tutor PCM scheduled",
                        value: "\(model.scheduledTutorFrameCount) frames"
                    )
                    LabeledContent(
                        "Last stop cursor",
                        value: model.renderedCursorMilliseconds.map { "\($0) ms" } ?? "none"
                    )
                    LabeledContent(
                        "Four-second window",
                        value: model.renderedWindowAvailable ? "captured" : "not proven"
                    )
                    Text(model.activityLabel)
                        .foregroundStyle(.secondary)
                    Text("This dedicated probe may exercise the live microphone and provider. MA product binding and overlap claims remain gated by the written verdict.")
                        .foregroundStyle(.secondary)
                }

                Section("Physical probe controls") {
                    Button("Start live probe") {
                        Task { await model.startLiveProbe() }
                    }
                    .disabled(
                        model.credentialStatus != .ready
                            || !(model.runStatus == .idle
                                || model.runStatus == .failed
                                || model.runStatus == .permissionDenied)
                    )

                    Button("Request tutor") {
                        Task { await model.requestTutor() }
                    }
                    .disabled(model.runStatus != .active)

                    Button("Local stop", role: .destructive) {
                        Task { await model.localStop() }
                    }
                    .disabled(model.runStatus != .active)

                    Button("Stop probe") {
                        Task { await model.stopLiveProbe() }
                    }
                    .disabled(model.runStatus == .idle)

                    if model.runStatus == .permissionDenied,
                       let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        Button("Open microphone settings") {
                            openURL(settingsURL)
                        }
                    }
                }
            }
            .navigationTitle("MA Audio Probe")
        }
    }
}

#Preview {
    ProbeGateView(model: ProbeAppModel())
}
