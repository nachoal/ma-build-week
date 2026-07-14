@preconcurrency import AVFAudio
import Foundation

struct AudioAssetDescriptor: Equatable, Sendable {
    let prompt: BundledPrompt
    let baseName: String
    let fileExtension: String
    let expectedChannels: AVAudioChannelCount
    let expectedSampleRate: Double
}

enum AudioAssetCatalog {
    static let assets: [AudioAssetDescriptor] = BundledPrompt.allCases.map {
        AudioAssetDescriptor(
            prompt: $0,
            baseName: $0.rawValue,
            fileExtension: $0.fileExtension,
            expectedChannels: 1,
            expectedSampleRate: 22_050
        )
    }

    static func descriptor(for prompt: BundledPrompt) -> AudioAssetDescriptor {
        // Every enum case is constructed above, so this is a total mapping.
        assets.first { $0.prompt == prompt }!
    }

    static func url(
        for prompt: BundledPrompt,
        bundle: Bundle = .main
    ) throws -> URL {
        let descriptor = descriptor(for: prompt)
        guard let url = bundle.url(
            forResource: descriptor.baseName,
            withExtension: descriptor.fileExtension
        ) else {
            throw ProductAudioFailure.missingAsset(prompt)
        }
        return url
    }

    static func validate(
        _ prompt: BundledPrompt,
        bundle: Bundle = .main
    ) throws -> AVAudioFramePosition {
        let descriptor = descriptor(for: prompt)
        let file = try AVAudioFile(forReading: url(for: prompt, bundle: bundle))
        guard file.length > 0,
              file.processingFormat.channelCount == descriptor.expectedChannels,
              abs(file.processingFormat.sampleRate - descriptor.expectedSampleRate) < 0.5 else {
            throw ProductAudioFailure.invalidAudioFormat
        }
        return file.length
    }
}
