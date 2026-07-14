import Foundation

/// Model features, audio-topology evidence, and measured floor behavior are
/// deliberately separate. A model name can never imply an audio or floor
/// capability.
struct RealtimeModelCapabilities: Codable, Equatable, Sendable {
    let supportsManualResponseControl: Bool
    let supportsServerManagedTruncation: Bool
    let providesExactWordTiming: Bool
    let supportsTools: Bool
    let supportsReasoning: Bool

    static let unavailable = RealtimeModelCapabilities(
        supportsManualResponseControl: false,
        supportsServerManagedTruncation: false,
        providesExactWordTiming: false,
        supportsTools: false,
        supportsReasoning: false
    )
}

struct AudioTopologyCapabilities: Codable, Equatable, Sendable {
    let exposesPostAECSamples: Bool
    let supportsOverlappingCapture: Bool
    let supportsImmediateLocalStop: Bool
    let exposesRenderedCursor: Bool
    let supportsExactRenderedReplay: Bool

    static let unavailable = AudioTopologyCapabilities(
        exposesPostAECSamples: false,
        supportsOverlappingCapture: false,
        supportsImmediateLocalStop: false,
        exposesRenderedCursor: false,
        supportsExactRenderedReplay: false
    )

    static let gate0PartialLocal = AudioTopologyCapabilities(
        exposesPostAECSamples: false,
        supportsOverlappingCapture: false,
        supportsImmediateLocalStop: true,
        exposesRenderedCursor: false,
        supportsExactRenderedReplay: false
    )
}

struct FloorLatencyThresholds: Codable, Equatable, Sendable {
    let decisionP95Milliseconds: Int?
    let audibleStopP95Milliseconds: Int?

    static let unmeasured = FloorLatencyThresholds(
        decisionP95Milliseconds: nil,
        audibleStopP95Milliseconds: nil
    )
}

enum FloorEvidenceVerdict: String, Codable, Equatable, Sendable {
    case pass
    case partial
    case characterizationOnlyPartial = "characterization_only_partial"
    case unavailable
}

struct FloorPolicyCapabilities: Codable, Equatable, Sendable {
    let validatedPhrases: [String]
    let classifierVersion: String?
    let frozenConfigurationHash: String?
    let distinguishesBackchannels: Bool
    let measuredLatencyAndErrorThresholds: FloorLatencyThresholds
    let evidenceVerdict: FloorEvidenceVerdict

    static let gate0Partial = FloorPolicyCapabilities(
        validatedPhrases: [],
        classifierVersion: nil,
        frozenConfigurationHash: nil,
        distinguishesBackchannels: false,
        measuredLatencyAndErrorThresholds: .unmeasured,
        evidenceVerdict: .characterizationOnlyPartial
    )

    static let unavailable = FloorPolicyCapabilities(
        validatedPhrases: [],
        classifierVersion: nil,
        frozenConfigurationHash: nil,
        distinguishesBackchannels: false,
        measuredLatencyAndErrorThresholds: .unmeasured,
        evidenceVerdict: .unavailable
    )
}

struct ConversationCapabilitySnapshot: Codable, Equatable, Sendable {
    let model: RealtimeModelCapabilities
    let audioTopology: AudioTopologyCapabilities
    let floorPolicy: FloorPolicyCapabilities

    static let gate0PartialLocal = ConversationCapabilitySnapshot(
        model: .unavailable,
        audioTopology: .gate0PartialLocal,
        floorPolicy: .gate0Partial
    )

    /// A labeled replay has no model, device audio, or measured floor facts.
    static let labeledReplay = ConversationCapabilitySnapshot(
        model: .unavailable,
        audioTopology: .unavailable,
        floorPolicy: .unavailable
    )
}
