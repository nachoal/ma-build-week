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
    case hardwareUnavailable
    case interrupted

    var errorDescription: String? {
        switch self {
        case .missingAsset:
            "Falta un audio incluido. Reinstala esta compilación."
        case .microphoneDenied:
            "Activa el micrófono en Ajustes para registrar tu intento."
        case .playbackInProgress:
            "Espera a que termine el audio o páralo antes de hablar."
        case .captureInProgress:
            "Termina tu intento antes de reproducir otro audio."
        case .captureNotRunning:
            "No hay un intento de voz activo."
        case .invalidAudioFormat:
            "Este audio incluido no se pudo abrir."
        case .hardwareUnavailable:
            "El audio no está disponible ahora. Inténtalo de nuevo."
        case .interrupted:
            "El audio se detuvo. Toca de nuevo cuando estés listo."
        }
    }
}

enum ProductAudioState: Equatable, Sendable {
    case idle
    case playing(BundledPrompt)
    case requestingPermission
    case capturing(CaptureRequest)
    case failed(ProductAudioFailure)
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
