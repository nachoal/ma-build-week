import SwiftUI

enum ProbeGateState {
    static let liveProductBindingUnlocked = false
    static let gateLabel = "running — PARTIAL transport pending"
}

struct ProbeGateView: View {
    let model: ProbeAppModel

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
                    Text("Fixture product UI is authorized. Live microphone/provider binding and overlap claims stay gated until the written verdict permits them.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("MA Audio Probe")
        }
    }
}

#Preview {
    ProbeGateView(model: ProbeAppModel())
}
