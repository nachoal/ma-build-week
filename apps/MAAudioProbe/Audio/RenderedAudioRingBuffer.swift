import Foundation

enum RenderedAudioRingBufferError: Error, Equatable {
    case invalidConfiguration
    case invalidDuration
    case insufficientRenderedAudio
    case renderedAudioOverwritten
    case unplayedAudioRequested
}

struct RenderedAudioWindow: Sendable, Equatable {
    let sampleRate: Double
    let startFrame: UInt64
    let endFrameExclusive: UInt64
    let samples: [Float]

    var duration: TimeInterval {
        Double(samples.count) / sampleRate
    }
}

struct RenderedAudioRingBuffer: Sendable {
    let sampleRate: Double
    let capacityFrames: Int

    private var storage: [Float]
    private(set) var renderedFrameCount: UInt64 = 0

    init(sampleRate: Double, capacitySeconds: TimeInterval) throws {
        let frames = sampleRate * capacitySeconds
        guard sampleRate.isFinite,
              sampleRate > 0,
              capacitySeconds.isFinite,
              capacitySeconds > 0,
              frames <= Double(Int.max),
              frames.rounded(.up) >= 1 else {
            throw RenderedAudioRingBufferError.invalidConfiguration
        }
        self.sampleRate = sampleRate
        self.capacityFrames = Int(frames.rounded(.up))
        self.storage = [Float](repeating: 0, count: capacityFrames)
    }

    var oldestAvailableFrame: UInt64 {
        renderedFrameCount > UInt64(capacityFrames)
            ? renderedFrameCount - UInt64(capacityFrames)
            : 0
    }

    mutating func append<S: Collection>(_ samples: S) where S.Element == Float {
        for sample in samples {
            let index = Int(renderedFrameCount % UInt64(capacityFrames))
            storage[index] = sample.isFinite ? sample : 0
            renderedFrameCount &+= 1
        }
    }

    func window(
        endingAt endFrameExclusive: UInt64,
        duration: TimeInterval
    ) throws -> RenderedAudioWindow {
        let requestedFrames = duration * sampleRate
        guard duration.isFinite,
              duration > 0,
              requestedFrames <= Double(Int.max) else {
            throw RenderedAudioRingBufferError.invalidDuration
        }
        let frameCount = Int(requestedFrames.rounded())
        guard frameCount > 0, frameCount <= capacityFrames else {
            throw RenderedAudioRingBufferError.invalidDuration
        }
        guard endFrameExclusive <= renderedFrameCount else {
            throw RenderedAudioRingBufferError.unplayedAudioRequested
        }
        guard endFrameExclusive >= UInt64(frameCount) else {
            throw RenderedAudioRingBufferError.insufficientRenderedAudio
        }

        let startFrame = endFrameExclusive - UInt64(frameCount)
        guard startFrame >= oldestAvailableFrame else {
            throw RenderedAudioRingBufferError.renderedAudioOverwritten
        }

        var result: [Float] = []
        result.reserveCapacity(frameCount)
        for frame in startFrame..<endFrameExclusive {
            result.append(storage[Int(frame % UInt64(capacityFrames))])
        }
        return RenderedAudioWindow(
            sampleRate: sampleRate,
            startFrame: startFrame,
            endFrameExclusive: endFrameExclusive,
            samples: result
        )
    }
}
