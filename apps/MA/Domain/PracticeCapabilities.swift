import Foundation

/// Product permissions frozen by the written Gate 0 verdict. These are data,
/// not feature flags: the submission target has no path that can turn the
/// unproven live or exact capabilities on.
struct PracticeCapabilities: Codable, Equatable, Sendable {
    enum TutorSource: String, Codable, Sendable {
        case bundledLocal
    }

    enum RepairSource: String, Codable, Sendable {
        case controlledLabeledSegment
    }

    let tutorSource: TutorSource
    let repairSource: RepairSource
    let allowsProviderFreeLearnerCapture: Bool
    let allowsLiveRealtime: Bool
    let allowsOverlapFloorPolicy: Bool
    let allowsExactRenderedWindowReplay: Bool
    let allowsPostLessonPlanner: Bool
    let conversation: ConversationCapabilitySnapshot

    static let gate0Partial = PracticeCapabilities(
        tutorSource: .bundledLocal,
        repairSource: .controlledLabeledSegment,
        allowsProviderFreeLearnerCapture: true,
        allowsLiveRealtime: false,
        allowsOverlapFloorPolicy: false,
        allowsExactRenderedWindowReplay: false,
        allowsPostLessonPlanner: true,
        conversation: .gate0PartialLocal
    )

    var tutorBadge: String { "LOCAL · AUDIO INCLUIDO" }
    var repairBadge: String { "REPLAY · DEMOSTRACIÓN" }
}
