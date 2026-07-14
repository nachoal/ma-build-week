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
    let renderedPacketDropCount: UInt64
}

enum AudioGraphEvidenceStoreError: Error, Equatable {
    case staleEpoch
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
    private(set) var renderedPacketDropCount: UInt64 = 0

    init(playbackSampleRate: Double = 24_000) {
        self.ledger = try! RenderedPlayoutLedger(sampleRate: playbackSampleRate)
    }

    @discardableResult
    func configureMixer(
        sampleRate: Double,
        capacitySeconds: TimeInterval = 12
    ) throws -> UInt64 {
        epoch &+= 1
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        ringBuffer = try RenderedAudioRingBuffer(
            sampleRate: sampleRate,
            capacitySeconds: capacitySeconds
        )
        mixerRenderedFrameCount = 0
        lastMixerTiming = nil
        renderedPacketDropCount = 0
        return epoch
    }

    func schedule(
        itemID: String,
        contentIndex: Int,
        frameCount: Int64,
        playerStartFrame: Int64,
        expectedEpoch: UInt64
    ) throws {
        guard expectedEpoch == epoch else {
            throw AudioGraphEvidenceStoreError.staleEpoch
        }
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

    func noteRenderedPacketDrop() {
        renderedPacketDropCount &+= 1
    }

    func stop(
        playerRenderedFrame: Int64,
        expectedEpoch: UInt64
    ) throws -> AudioGraphStopEvidence {
        guard expectedEpoch == epoch else {
            throw AudioGraphEvidenceStoreError.staleEpoch
        }
        let boundedPlayerFrame = max(0, playerRenderedFrame)
        let contentRenderedFrame = contentFrame(for: boundedPlayerFrame)
        try ledger.markRendered(through: contentRenderedFrame)
        let truncationTarget = ledger.truncationTarget()
        // The asynchronous mixer handoff is not a device-boundary freeze
        // barrier. Keep collecting characterization samples, but never expose
        // an "exact heard window" until a physical Experiment D seals it.
        let renderedWindow: RenderedAudioWindow? = nil

        let stoppedEpoch = epoch
        let stoppedDropCount = renderedPacketDropCount
        epoch &+= 1
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        renderedPacketDropCount = 0
        return AudioGraphStopEvidence(
            epoch: stoppedEpoch,
            playerRenderedFrame: boundedPlayerFrame,
            truncationTarget: truncationTarget,
            renderedWindow: renderedWindow,
            renderedPacketDropCount: stoppedDropCount
        )
    }

    func resetForLifecycle() {
        epoch &+= 1
        ledger.reset()
        playerContentRanges.removeAll(keepingCapacity: true)
        ringBuffer = nil
        mixerRenderedFrameCount = 0
        lastMixerTiming = nil
        renderedPacketDropCount = 0
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
