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

enum ProbeRunStatus: Equatable {
    case idle
    case starting
    case active
    case stopping
    case permissionDenied
    case failed

    var label: String {
        switch self {
        case .idle: "idle"
        case .starting: "starting graph and transport"
        case .active: "live graph active"
        case .stopping: "stopping"
        case .permissionDenied: "microphone permission denied"
        case .failed: "probe failed closed"
        }
    }
}

@MainActor
@Observable
final class ProbeAppModel {
    private let credentialStore: any InstallCredentialStoring
    private let diagnostics: ProbeDiagnostics
    private let brokerClient: SessionBrokerClient
    private let transport: RealtimeWebSocketTransport
    private let outboundQueue: RealtimeOutboundCommandQueue
    private let inputPump: ProbeInputAudioPump
    private let evidenceStore: AudioGraphEvidenceStore
    private let audioGraph: AudioGraphController

    private var nextCommandSequence: UInt64 = 0
    private var activeResponseID: String?
    private var stoppedResponseIDs: Set<String> = []
    private var metricsTask: Task<Void, Never>?

    var credentialStatus: ProbeCredentialStatus = .checking
    var runStatus: ProbeRunStatus = .idle
    var activityLabel = "Ready to start the dedicated Gate 0 probe."
    var graphConfigurationHash = "pending"
    var sentMicrophoneFrameCount: UInt64 = 0
    var scheduledTutorFrameCount: UInt64 = 0
    var renderedCursorMilliseconds: Int?
    var renderedWindowAvailable = false

    init(credentialStore: any InstallCredentialStoring = InstallCredentialStore()) {
        let diagnostics = ProbeDiagnostics()
        let transport = RealtimeWebSocketTransport(diagnostics: diagnostics)
        let outboundQueue = RealtimeOutboundCommandQueue(transport: transport)
        let evidenceStore = AudioGraphEvidenceStore()

        self.credentialStore = credentialStore
        self.diagnostics = diagnostics
        self.brokerClient = SessionBrokerClient()
        self.transport = transport
        self.outboundQueue = outboundQueue
        self.inputPump = ProbeInputAudioPump(
            outboundQueue: outboundQueue,
            diagnostics: diagnostics
        )
        self.evidenceStore = evidenceStore
        self.audioGraph = AudioGraphController(
            diagnostics: diagnostics,
            evidenceStore: evidenceStore
        )
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

    func startLiveProbe() async {
        guard runStatus == .idle || runStatus == .failed || runStatus == .permissionDenied else {
            return
        }
        guard credentialStatus == .ready else {
            activityLabel = "Provision the private broker credential before starting."
            return
        }

        runStatus = .starting
        activityLabel = "Requesting microphone access and starting one audio graph…"
        renderedCursorMilliseconds = nil
        renderedWindowAvailable = false
        stoppedResponseIDs.removeAll(keepingCapacity: true)

        do {
            let runtime = try await audioGraph.start { [inputPump] data in
                await inputPump.accept(data)
            }
            graphConfigurationHash = runtime.configurationHash
            activityLabel = "VoiceProcessingIO active; connecting Realtime…"

            guard let installToken = try credentialStore.loadToken() else {
                throw SessionBrokerError.invalidInstallCredential
            }
            let clientSecret = try await brokerClient.mintClientSecret(
                installToken: installToken
            )
            try await transport.connect(clientSecret: clientSecret) { [weak self] event in
                await self?.handleProviderEvent(event)
            }
            await inputPump.setEnabled(true)
            runStatus = .active
            activityLabel = "Live. Request tutor audio, then speak near the phone."
            startMetricsPolling()
        } catch AudioGraphControllerError.microphoneDenied {
            runStatus = .permissionDenied
            activityLabel = "Enable microphone access in Settings, then retry."
            await stopResources(preserveStatus: true)
        } catch {
            runStatus = .failed
            activityLabel = "The graph or transport failed closed. Retry after checking the route."
            await diagnostics.record(
                .error,
                details: ["stage": "probe_start", "category": "failed_closed"]
            )
            await stopResources(preserveStatus: true)
        }
    }

    func requestTutor() async {
        guard runStatus == .active else { return }
        do {
            let command = try RealtimeClientCommand.createResponse(
                eventID: nextCommandID(prefix: "response")
            )
            try await outboundQueue.send(command)
            activityLabel = "Tutor response requested; waiting for rendered PCM…"
        } catch {
            runStatus = .failed
            activityLabel = "Tutor request failed closed."
        }
    }

    func localStop() async {
        guard runStatus == .active else { return }
        runStatus = .stopping
        do {
            let responseID = activeResponseID
            let evidence = try await audioGraph.localStop()
            if let responseID {
                stoppedResponseIDs.insert(responseID)
            }

            var commands: [Data] = [
                try RealtimeClientCommand.cancelResponse(
                    responseID: responseID,
                    eventID: nextCommandID(prefix: "cancel")
                ),
            ]
            if let target = evidence.truncationTarget {
                commands.append(
                    try RealtimeClientCommand.truncateItem(
                        itemID: target.itemID,
                        contentIndex: target.contentIndex,
                        audioEndMilliseconds: target.audioEndMilliseconds,
                        eventID: nextCommandID(prefix: "truncate")
                    )
                )
                renderedCursorMilliseconds = target.audioEndMilliseconds
            } else {
                renderedCursorMilliseconds = nil
            }
            try await outboundQueue.sendBatch(commands)

            renderedWindowAvailable = evidence.renderedWindow != nil
            activeResponseID = nil
            runStatus = .active
            activityLabel = evidence.truncationTarget == nil
                ? "Output stopped locally; no defensible truncate cursor was available."
                : "Output stopped locally; cancel and one render-derived truncate sent."
        } catch {
            runStatus = .failed
            activityLabel = "Local stop occurred, but provider control failed closed."
        }
    }

    func stopLiveProbe() async {
        runStatus = .stopping
        await stopResources(preserveStatus: false)
    }

    private func handleProviderEvent(_ event: RealtimeServerEvent) async {
        switch event {
        case .sessionConfiguration:
            activityLabel = "Realtime policy verified; one graph is active."
        case .outputAudio(let chunk):
            if let responseID = chunk.responseID,
               stoppedResponseIDs.contains(responseID) {
                await diagnostics.record(
                    .providerEvent,
                    details: ["disposition": "stale_output_rejected"]
                )
                return
            }
            do {
                try await audioGraph.schedule(chunk)
                scheduledTutorFrameCount &+= UInt64(
                    chunk.pcm16Data.count / MemoryLayout<Int16>.size
                )
                activityLabel = "Tutor PCM scheduled on the measured player path."
            } catch {
                runStatus = .failed
                activityLabel = "Untraceable tutor audio was rejected."
            }
        case .inputSpeechStarted:
            activityLabel = "Server VAD observed learner speech on the processed uplink."
        case .inputSpeechStopped:
            activityLabel = "Server VAD ended the learner segment; server owns commit."
        case .responseStarted(_, let responseID):
            activeResponseID = responseID
            activityLabel = "Tutor response active."
        case .responseFinished(_, let responseID, let status):
            if activeResponseID == responseID {
                activeResponseID = nil
            }
            activityLabel = "Tutor response finished (\(status ?? "unknown"))."
        case .outputItemAdded:
            break
        case .outputItemFinished:
            break
        case .providerError:
            runStatus = .failed
            activityLabel = "Realtime returned a sanitized provider error."
        case .ignored:
            break
        }
    }

    private func nextCommandID(prefix: String) -> String {
        defer { nextCommandSequence &+= 1 }
        return "evt_\(prefix)_\(nextCommandSequence)"
    }

    private func startMetricsPolling() {
        metricsTask?.cancel()
        metricsTask = Task { [weak self, inputPump] in
            while !Task.isCancelled {
                let frameCount = await inputPump.sentFrameCount
                guard let self else { return }
                self.sentMicrophoneFrameCount = frameCount
                if !self.audioGraph.isRunning, self.runStatus == .active {
                    self.runStatus = .failed
                    self.activityLabel = "The audio route changed; restart the probe to rebuild."
                    return
                }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func stopResources(preserveStatus: Bool) async {
        metricsTask?.cancel()
        metricsTask = nil
        await inputPump.reset()
        await transport.disconnect()
        await audioGraph.teardown()
        activeResponseID = nil
        if !preserveStatus {
            runStatus = .idle
            activityLabel = "Stopped. The audio session and graph are inactive."
        }
    }
}
