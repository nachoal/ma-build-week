import Foundation

struct ConversationSessionConfiguration: Codable, Equatable, Sendable {
    let sessionID: UUID
    let sceneID: SceneID
    let obligationID: String
    let localeIdentifier: String
    let maximumBufferedEvents: Int

    init(
        sessionID: UUID,
        sceneID: SceneID,
        obligationID: String,
        localeIdentifier: String = "es-MX",
        maximumBufferedEvents: Int = 128
    ) {
        self.sessionID = sessionID
        self.sceneID = sceneID
        self.obligationID = obligationID
        self.localeIdentifier = localeIdentifier
        self.maximumBufferedEvents = maximumBufferedEvents
    }
}

enum ConversationAudioControl: Equatable, Sendable {
    case startLearnerCapture
    case stopLearnerCapture
    case stopTutorLocally
    case playControlledSegment(String)
}

enum ConversationIntent: Equatable, Sendable {
    case text(String)
    case audioControl(ConversationAudioControl)
}

enum ConversationProviderFailure: Error, Equatable, Sendable {
    case invalidConfiguration
    case invalidReplayScript
    case notConnected
    case alreadyConnected
    case responseAlreadyRequested
    case unsupportedIntent
    case cancelled
}

protocol ConversationProvider: Sendable {
    var capabilities: ConversationCapabilitySnapshot { get }
    var events: AsyncStream<ConversationEvent> { get }

    func connect(configuration: ConversationSessionConfiguration) async throws
    func disconnect() async
    func send(_ intent: ConversationIntent) async throws
    func requestResponse() async throws
    func cancelResponse() async throws
}
