import Foundation

struct AudioTapTiming: Sendable, Equatable {
    let sampleTime: Int64?
    let hostTime: UInt64?
    let sampleRate: Double
}

struct AudioGraphStopEvidence: Sendable, Equatable {
    let epoch: UInt64
    let playerRenderedFrame: Int64
    let truncationTarget: RenderedTruncationTarget?
    let renderedWindow: RenderedAudioWindow?
}

actor AudioGraphEvidenceStore {
    private struct PlayerContentRange: Sendable {
        let playerStartFrame: Int64
        let playerEndFrameExclusive: Int64
        let contentStartFrame: Int64
        let contentEndFrameExclusive: Int64
    }

    private var ledger: RenderedPlayoutLedger
    private var playerContentRanges: [PlayerContentRange] = []
    private var ringBuffer: RenderedAudioRingBuffer?
    private var epoch: UInt64 = 0
    private(set) var mixerRenderedFrameCount: UInt64 = 0
    private(set) var lastMixerTiming: AudioTapTiming?

    init(playbackSampleRate: Double = 24_000) {
        self.ledger = try! RenderedPlayoutLedger(sampleRate: playbackSampleRate)
    }

    func configureMixer(sampleRate: Double, capacitySeconds: TimeInterval = 12) throws {
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        ringBuffer = try RenderedAudioRingBuffer(
            sampleRate: sampleRate,
            capacitySeconds: capacitySeconds
        )
        mixerRenderedFrameCount = 0
        lastMixerTiming = nil
    }

    func schedule(
        itemID: String,
        contentIndex: Int,
        frameCount: Int64,
        playerStartFrame: Int64
    ) throws {
        let contentRange = try ledger.schedule(
            itemID: itemID,
            contentIndex: contentIndex,
            frameCount: frameCount
        )
        guard playerStartFrame >= 0 else {
            throw RenderedPlayoutLedgerError.invalidFrameCount
        }
        if let lastRange = playerContentRanges.last,
           playerStartFrame < lastRange.playerEndFrameExclusive {
            throw RenderedPlayoutLedgerError.renderCursorMovedBackward
        }
        let (playerEndFrame, overflow) = playerStartFrame.addingReportingOverflow(frameCount)
        guard !overflow else { throw RenderedPlayoutLedgerError.frameOverflow }
        playerContentRanges.append(
            PlayerContentRange(
                playerStartFrame: playerStartFrame,
                playerEndFrameExclusive: playerEndFrame,
                contentStartFrame: contentRange.startFrame,
                contentEndFrameExclusive: contentRange.endFrameExclusive
            )
        )
    }

    func appendRenderedMixerSamples(_ samples: [Float], timing: AudioTapTiming) {
        guard !samples.isEmpty else { return }
        ringBuffer?.append(samples)
        mixerRenderedFrameCount &+= UInt64(samples.count)
        lastMixerTiming = timing
    }

    func stop(playerRenderedFrame: Int64) throws -> AudioGraphStopEvidence {
        let boundedPlayerFrame = max(0, playerRenderedFrame)
        let contentRenderedFrame = contentFrame(for: boundedPlayerFrame)
        try ledger.markRendered(through: contentRenderedFrame)
        let truncationTarget = ledger.truncationTarget()
        let renderedWindow: RenderedAudioWindow?
        if let ringBuffer {
            renderedWindow = try? ringBuffer.window(
                endingAt: ringBuffer.renderedFrameCount,
                duration: 4
            )
        } else {
            renderedWindow = nil
        }

        let stoppedEpoch = epoch
        epoch &+= 1
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        return AudioGraphStopEvidence(
            epoch: stoppedEpoch,
            playerRenderedFrame: boundedPlayerFrame,
            truncationTarget: truncationTarget,
            renderedWindow: renderedWindow
        )
    }

    func resetForLifecycle() {
        epoch &+= 1
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        ringBuffer = nil
        mixerRenderedFrameCount = 0
        lastMixerTiming = nil
    }

    private func contentFrame(for playerFrame: Int64) -> Int64 {
        var renderedContentFrame: Int64 = 0
        for range in playerContentRanges {
            guard playerFrame > range.playerStartFrame else { break }
            if playerFrame >= range.playerEndFrameExclusive {
                renderedContentFrame = range.contentEndFrameExclusive
                continue
            }
            let framesInsideRange = playerFrame - range.playerStartFrame
            return range.contentStartFrame + max(0, framesInsideRange)
        }
        return renderedContentFrame
    }
}
