import Foundation

/// Replay never touches AVAudioSession, playback, capture, or permission APIs.
@MainActor
final class ReplayDisabledAudioController: ProductAudioControlling {
    let state: ProductAudioState = .idle
    let events: AsyncStream<ProductAudioEvent>

    init() {
        events = AsyncStream { continuation in continuation.finish() }
    }

    func play(_ prompt: BundledPrompt) async throws {
        _ = prompt
        throw ProductAudioFailure.hardwareUnavailable
    }

    func startCapture(_ request: CaptureRequest) async throws {
        _ = request
        throw ProductAudioFailure.hardwareUnavailable
    }

    func finishCapture(
        _ disposition: CaptureDisposition
    ) async throws -> CaptureReceipt? {
        _ = disposition
        throw ProductAudioFailure.hardwareUnavailable
    }

    func stop(_ reason: AudioStopReason) async { _ = reason }
    func handleLifecycle(_ event: AudioLifecycleEvent) async { _ = event }
}
