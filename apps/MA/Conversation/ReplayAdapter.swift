import Foundation

struct ReplayConversationScript: Codable, Equatable, Sendable {
    static let maximumEventCount = 64

    let configuration: ConversationSessionConfiguration
    let events: [ConversationEvent]

    init(
        configuration: ConversationSessionConfiguration,
        events: [ConversationEvent]
    ) throws {
        self.configuration = configuration
        self.events = events
        guard Self.validate(configuration: configuration, events: events) else {
            throw ConversationProviderFailure.invalidReplayScript
        }
    }

    static func validate(
        configuration: ConversationSessionConfiguration,
        events: [ConversationEvent]
    ) -> Bool {
        guard (3...maximumEventCount).contains(events.count),
              configuration.maximumBufferedEvents >= events.count,
              configuration.maximumBufferedEvents <= maximumEventCount,
              events.first?.payload == .sessionConnecting,
              events.dropFirst().first?.payload == .sessionReady,
              events.last?.payload == .sessionEnded else { return false }

        var previousTime: UInt64 = 0
        var seenAttemptIDs: Set<UUID> = []
        var seenCorrelationIDs: Set<String> = []
        var sawTerminal = false

        for (index, event) in events.enumerated() {
            guard !sawTerminal,
                  event.isStructurallyValid,
                  event.sequence == index,
                  event.monotonicNanoseconds >= previousTime,
                  event.sessionID == configuration.sessionID,
                  event.sceneID == configuration.sceneID,
                  event.obligationID == configuration.obligationID,
                  event.source == .labeledReplay,
                  event.evidence.provenance != .providerEvent,
                  event.evidence.provenance != .renderedAudioMeasured,
                  !seenCorrelationIDs.contains(event.correlationID),
                  payloadIsBoundedAndPartialSafe(event.payload),
                  !event.supportsLiveClaim,
                  !event.supportsExactHeardClaim else { return false }
            seenCorrelationIDs.insert(event.correlationID)

            switch event.payload {
            case .backchannelDetected,
                 .takeFloorDetected,
                 .tutorTranscriptDelta,
                 .learnerSpeechStarted,
                 .learnerPartialTranscript:
                // Gate 0 PARTIAL revoked both behaviors from the product and
                // from its deterministic submission fallback.
                return false
            case .repairWindowFrozen(.renderedWindow):
                return false
            case .attemptCompleted(let attempt):
                guard attempt.provenance == .fixtureSimulation,
                      attempt.obligationID == configuration.obligationID,
                      !seenAttemptIDs.contains(attempt.id) else { return false }
                seenAttemptIDs.insert(attempt.id)
            case .sessionEnded:
                sawTerminal = true
            default:
                break
            }
            previousTime = event.monotonicNanoseconds
        }
        return sawTerminal
    }

    private static func payloadIsBoundedAndPartialSafe(
        _ payload: ConversationEventPayload
    ) -> Bool {
        switch payload {
        case .sessionFailed(let reason):
            return !reason.isEmpty && reason.count <= 160
        case .tutorOutputStarted(let line), .tutorTranscriptDelta(let line):
            return [line.japanese, line.romaji, line.spanish]
                .allSatisfy { !$0.isEmpty && $0.count <= 256 }
        case .learnerPartialTranscript(let text):
            return !text.isEmpty && text.count <= 256
        case .repairWindowFrozen(.controlledSegment(let id, let obligationID)):
            return !id.isEmpty && id.count <= 96
                && !obligationID.isEmpty && obligationID.count <= 96
        case .repairWindowFrozen(.renderedWindow(let beats)):
            return beats.count <= 64
        case .controlledSegmentPlayed(let id),
             .sceneResumeStarted(let id),
             .sceneResumed(let id):
            return !id.isEmpty && id.count <= 96
        case .attemptCompleted(let attempt):
            guard (1...20).contains(attempt.attemptNumber),
                  (0...10).contains(attempt.repairCount),
                  attempt.capturedDuration.isFinite,
                  (0...8).contains(attempt.capturedDuration),
                  !attempt.obligationID.isEmpty,
                  attempt.obligationID.count <= 96 else { return false }
            if attempt.speechPresenceDetected {
                guard let onset = attempt.estimatedVoiceOnset,
                      onset.isFinite,
                      (0...attempt.capturedDuration).contains(onset) else { return false }
            } else if attempt.estimatedVoiceOnset != nil {
                return false
            }
            return true
        case .learningActionReady(let action):
            return action.schemaVersion == 1
                && action.source == .cachedFixture
                && action.model.count <= 64
                && action.explanationES.count <= 320
                && action.evidenceReasonES.count <= 320
                && action.obligationID.count <= 96
        default:
            return true
        }
    }
}

enum ReplayDelivery: Equatable, Sendable {
    case immediate
    /// Preserves normalized event spacing while capping each visual pause.
    case paced(timeScale: Double, maximumDelay: Duration)
}

actor ReplayAdapter: ConversationProvider {
    nonisolated let capabilities = ConversationCapabilitySnapshot.labeledReplay
    nonisolated let events: AsyncStream<ConversationEvent>

    private enum State: Equatable {
        case idle
        case connected
        case replaying
        case finished
        case disconnected
    }

    private let continuation: AsyncStream<ConversationEvent>.Continuation
    private let script: ReplayConversationScript
    private let delivery: ReplayDelivery
    private var state: State = .idle
    private var generation = 0

    init(
        script: ReplayConversationScript = KaiwaLoopReplayFixture.script,
        delivery: ReplayDelivery = .immediate
    ) {
        self.script = script
        self.delivery = delivery
        let pair = AsyncStream.makeStream(
            of: ConversationEvent.self,
            bufferingPolicy: .bufferingOldest(ReplayConversationScript.maximumEventCount)
        )
        events = pair.stream
        continuation = pair.continuation
    }

    func connect(configuration: ConversationSessionConfiguration) async throws {
        guard state == .idle else { throw ConversationProviderFailure.alreadyConnected }
        guard configuration == script.configuration,
              ReplayConversationScript.validate(
                configuration: configuration,
                events: script.events
              ) else { throw ConversationProviderFailure.invalidConfiguration }

        state = .connected
        try yield(script.events[0])
        try yield(script.events[1])
    }

    func send(_ intent: ConversationIntent) async throws {
        _ = intent
        throw ConversationProviderFailure.unsupportedIntent
    }

    func requestResponse() async throws {
        guard state == .connected else {
            if state == .replaying || state == .finished {
                throw ConversationProviderFailure.responseAlreadyRequested
            }
            throw ConversationProviderFailure.notConnected
        }

        state = .replaying
        let requestGeneration = generation
        var previous = script.events[1].monotonicNanoseconds

        for event in script.events.dropFirst(2) {
            guard generation == requestGeneration, state == .replaying else {
                throw ConversationProviderFailure.cancelled
            }
            try await wait(from: previous, to: event.monotonicNanoseconds)
            guard generation == requestGeneration, state == .replaying else {
                throw ConversationProviderFailure.cancelled
            }
            try yield(event)
            previous = event.monotonicNanoseconds
        }
        state = .finished
        continuation.finish()
    }

    func cancelResponse() async throws {
        guard state == .replaying else {
            if state == .connected { return }
            throw ConversationProviderFailure.notConnected
        }
        generation += 1
        // Cancellation is terminal for this single-use stream. Restarting a
        // replay creates a fresh adapter, which prevents duplicate sequence
        // and correlation IDs from ever entering one AsyncStream.
        state = .finished
        continuation.finish()
    }

    func disconnect() async {
        generation += 1
        state = .disconnected
        continuation.finish()
    }

    private func yield(_ event: ConversationEvent) throws {
        switch continuation.yield(event) {
        case .enqueued:
            return
        case .dropped, .terminated:
            throw ConversationProviderFailure.invalidReplayScript
        @unknown default:
            throw ConversationProviderFailure.invalidReplayScript
        }
    }

    private func wait(from start: UInt64, to end: UInt64) async throws {
        guard end > start else { return }
        guard case .paced(let timeScale, let maximumDelay) = delivery else { return }
        guard timeScale.isFinite, timeScale >= 0 else {
            throw ConversationProviderFailure.invalidReplayScript
        }
        let scaledSeconds = (Double(end - start) / 1_000_000_000) * timeScale
        let desired = Duration.seconds(scaledSeconds)
        let delay = min(desired, maximumDelay)
        if delay > .zero {
            try await ContinuousClock().sleep(for: delay)
        }
    }
}
