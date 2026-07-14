@preconcurrency import AVFAudio
import Foundation

enum BundledPrompt: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
    case hitoriDesu = "hitori-desu"
    case tutorTurn = "tutor-turn"
    case repairBeat = "repair-beat"
    case tutorResume = "tutor-resume"

    var fileExtension: String { "m4a" }

    var provenanceLabel: String {
        self == .repairBeat
            ? PracticeCapabilities.gate0Partial.repairBadge
            : PracticeCapabilities.gate0Partial.tutorBadge
    }
}

struct CaptureRequest: Equatable, Sendable {
    let id: UUID
    let sceneID: SceneID
    let obligationID: String
    let scaffold: ScaffoldLevel
    let attemptNumber: Int
    let maximumDuration: Duration

    init(
        id: UUID = UUID(),
        sceneID: SceneID = .restaurant,
        obligationID: String,
        scaffold: ScaffoldLevel,
        attemptNumber: Int,
        maximumDuration: Duration = .seconds(8)
    ) {
        self.id = id
        self.sceneID = sceneID
        self.obligationID = obligationID
        self.scaffold = scaffold
        self.attemptNumber = attemptNumber
        self.maximumDuration = maximumDuration
    }
}

enum CaptureDisposition: Equatable, Sendable {
    case completed
    case cancelled
    case timeLimit
    case lifecycle
}

struct CaptureReceipt: Equatable, Sendable, Identifiable {
    let id: UUID
    let request: CaptureRequest
    let startedAt: Date
    let endedAt: Date
    let capturedDuration: TimeInterval
    /// Energy-threshold estimate only. It is never a transcript, pronunciation
    /// score, or proof that the obligation was completed.
    let estimatedVoiceOnset: TimeInterval?
    let speechPresenceDetected: Bool
    let sampleRate: Double
    let disposition: CaptureDisposition
    let rawAudioRetained: Bool
}

enum AudioStopReason: String, Equatable, Sendable {
    case explicitRepair
    case replacement
    case restart
    case exit
    case lifecycle
}

enum AudioLifecycleEvent: Equatable, Sendable {
    case enteredBackground
    case interruptionBegan
    case routeChanged
    case mediaServicesReset
}

enum ProductAudioFailure: Error, LocalizedError, Equatable, Sendable {
    case missingAsset(BundledPrompt)
    case microphoneDenied
    case playbackInProgress
    case captureInProgress
    case captureNotRunning
    case invalidAudioFormat
    case invalidProviderAudio
    case hardwareUnavailable
    case interrupted

    var errorDescription: String? {
        message(in: .english)
    }

    func message(in language: MAInterfaceLanguage) -> String {
        switch self {
        case .missingAsset:
            language.text(
                english: "An included audio file is missing. Reinstall this build.",
                spanish: "Falta un audio incluido. Reinstala esta compilación."
            )
        case .microphoneDenied:
            language.text(
                english: "Enable the microphone in Settings to record your attempt.",
                spanish: "Activa el micrófono en Ajustes para registrar tu intento."
            )
        case .playbackInProgress:
            language.text(
                english: "Wait for the audio to finish, or stop it before speaking.",
                spanish: "Espera a que termine el audio o páralo antes de hablar."
            )
        case .captureInProgress:
            language.text(
                english: "Finish your attempt before playing another audio clip.",
                spanish: "Termina tu intento antes de reproducir otro audio."
            )
        case .captureNotRunning:
            language.text(
                english: "There is no active speaking attempt.",
                spanish: "No hay un intento de voz activo."
            )
        case .invalidAudioFormat:
            language.text(
                english: "This included audio file could not be opened.",
                spanish: "Este audio incluido no se pudo abrir."
            )
        case .invalidProviderAudio:
            language.text(
                english: "The spoken response was not in a playable format.",
                spanish: "La respuesta de voz no tenía un formato reproducible."
            )
        case .hardwareUnavailable:
            language.text(
                english: "Audio is unavailable right now. Try again.",
                spanish: "El audio no está disponible ahora. Inténtalo de nuevo."
            )
        case .interrupted:
            language.text(
                english: "The audio stopped. Tap again when you’re ready.",
                spanish: "El audio se detuvo. Toca de nuevo cuando estés listo."
            )
        }
    }
}

enum ProductAudioState: Equatable, Sendable {
    case idle
    case playing(BundledPrompt)
    case playingRealtime
    case requestingPermission
    case capturing(CaptureRequest)
    case failed(ProductAudioFailure)
}

struct RealtimeCapturePayload: Equatable, Sendable {
    let receipt: CaptureReceipt
    /// Ephemeral 24 kHz mono PCM16. It exists only long enough to send this
    /// explicit learner turn to OpenAI and is never written to disk.
    let pcm16Data: Data
}

enum ProductAudioEvent: Equatable, Sendable {
    case stateChanged(ProductAudioState)
    case playbackFinished(BundledPrompt)
    case captureFinished(CaptureReceipt)
    case lifecycleStopped(AudioLifecycleEvent)
}

@MainActor
protocol ProductAudioControlling: AnyObject {
    var state: ProductAudioState { get }
    var events: AsyncStream<ProductAudioEvent> { get }

    func play(_ prompt: BundledPrompt) async throws
    func startCapture(_ request: CaptureRequest) async throws
    func finishCapture(_ disposition: CaptureDisposition) async throws -> CaptureReceipt?
    func stop(_ reason: AudioStopReason) async
    func handleLifecycle(_ event: AudioLifecycleEvent) async
}

@MainActor
protocol GuidedLessonAudioControlling: AnyObject {
    var state: ProductAudioState { get }
    var events: AsyncStream<ProductAudioEvent> { get }

    func play(_ prompt: BundledPrompt) async throws
    func startRealtimeCapture(_ request: CaptureRequest) async throws
    func finishRealtimeCapture(
        _ disposition: CaptureDisposition
    ) async throws -> RealtimeCapturePayload?
    func playRealtimePCM16(_ data: Data) async throws
    func stop(_ reason: AudioStopReason) async
}

@MainActor
protocol RecordPermissionProviding: Sendable {
    func requestPermission() async -> Bool
}

struct SystemRecordPermissionProvider: RecordPermissionProviding {
    func requestPermission() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            true
        case .denied:
            false
        case .undetermined:
            await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            false
        }
    }
}
