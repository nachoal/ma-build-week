import CryptoKit
import Foundation

struct AudioGraphConfiguration: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let audioDeviceOwner: String
    let transport: String
    let mediaLibrary: String
    let model: String
    let vadType: String
    let createResponse: Bool
    let interruptResponse: Bool
    let category: String
    let mode: String
    let options: [String]
    let inputRouteTypes: [String]
    let outputRouteTypes: [String]
    let sessionSampleRate: Double
    let inputChannelCount: Int
    let outputChannelCount: Int
    let ioBufferDuration: Double
    let inputLatency: Double
    let outputLatency: Double
    let playerPresentationLatency: Double
    let inputNodeSampleRate: Double
    let inputNodeChannelCount: Int
    let mixerSampleRate: Double
    let mixerChannelCount: Int
    let playbackSampleRate: Double
    let playbackChannelCount: Int
    let inputVoiceProcessingEnabled: Bool
    let outputVoiceProcessingEnabled: Bool
    let inputVoiceProcessingBypassed: Bool
    let inputVoiceProcessingMuted: Bool

    func configurationHash() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(self)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
