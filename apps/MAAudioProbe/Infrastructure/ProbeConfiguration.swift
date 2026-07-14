import Foundation

enum ProbeConfiguration {
    static let autoStartEnvironmentKey = "MA_GATE0_AUTOSTART"
    static let autoRequestTutorEnvironmentKey = "MA_GATE0_AUTOREQUEST_TUTOR"
    static let autoStopEnvironmentKey = "MA_GATE0_AUTOSTOP"
    static let brokerClientSecretURL = URL(
        string: "https://ma-session-broker.ignacio-alley.workers.dev/realtime/client-secret"
    )!
    static let realtimeWebSocketURL = URL(
        string: "wss://api.openai.com/v1/realtime?model=gpt-realtime-2.1"
    )!
    static let realtimeModel = "gpt-realtime-2.1"
}
