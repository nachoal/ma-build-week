import Foundation

struct ScheduledPlayoutRange: Sendable, Equatable {
    let itemID: String
    let contentIndex: Int
    let startFrame: Int64
    let endFrameExclusive: Int64
}

struct RenderedTruncationTarget: Sendable, Equatable {
    let itemID: String
    let contentIndex: Int
    let renderedGlobalFrame: Int64
    let audioEndMilliseconds: Int
}

enum RenderedPlayoutLedgerError: Error, Equatable {
    case invalidSampleRate
    case invalidIdentifier
    case invalidContentIndex
    case invalidFrameCount
    case frameOverflow
    case renderCursorMovedBackward
    case unplayedAudioMarkedRendered
}

struct RenderedPlayoutLedger: Sendable, Equatable {
    let sampleRate: Double
    private(set) var scheduledFrameCount: Int64 = 0
    private(set) var renderedFrameCount: Int64 = 0
    private(set) var ranges: [ScheduledPlayoutRange] = []

    init(sampleRate: Double) throws {
        guard sampleRate.isFinite, sampleRate > 0 else {
            throw RenderedPlayoutLedgerError.invalidSampleRate
        }
        self.sampleRate = sampleRate
    }

    @discardableResult
    mutating func schedule(
        itemID: String,
        contentIndex: Int,
        frameCount: Int64
    ) throws -> ScheduledPlayoutRange {
        guard !itemID.isEmpty, itemID.count <= 256 else {
            throw RenderedPlayoutLedgerError.invalidIdentifier
        }
        guard contentIndex >= 0 else {
            throw RenderedPlayoutLedgerError.invalidContentIndex
        }
        guard frameCount > 0 else {
            throw RenderedPlayoutLedgerError.invalidFrameCount
        }
        let (endFrame, overflow) = scheduledFrameCount.addingReportingOverflow(frameCount)
        guard !overflow else {
            throw RenderedPlayoutLedgerError.frameOverflow
        }

        let range = ScheduledPlayoutRange(
            itemID: itemID,
            contentIndex: contentIndex,
            startFrame: scheduledFrameCount,
            endFrameExclusive: endFrame
        )
        ranges.append(range)
        scheduledFrameCount = endFrame
        return range
    }

    mutating func markRendered(through globalFrame: Int64) throws {
        guard globalFrame >= renderedFrameCount else {
            throw RenderedPlayoutLedgerError.renderCursorMovedBackward
        }
        guard globalFrame <= scheduledFrameCount else {
            throw RenderedPlayoutLedgerError.unplayedAudioMarkedRendered
        }
        renderedFrameCount = globalFrame
    }

    func truncationTarget() -> RenderedTruncationTarget? {
        guard renderedFrameCount > 0,
              let renderedRange = ranges.last(where: {
                $0.startFrame < renderedFrameCount
                    && renderedFrameCount <= $0.endFrameExclusive
              }),
              let itemStart = ranges.first(where: {
                $0.itemID == renderedRange.itemID
                    && $0.contentIndex == renderedRange.contentIndex
              })?.startFrame else {
            return nil
        }

        let renderedItemFrames = renderedFrameCount - itemStart
        let milliseconds = Int(
            (Double(renderedItemFrames) * 1_000 / sampleRate).rounded(.down)
        )
        return RenderedTruncationTarget(
            itemID: renderedRange.itemID,
            contentIndex: renderedRange.contentIndex,
            renderedGlobalFrame: renderedFrameCount,
            audioEndMilliseconds: max(0, milliseconds)
        )
    }

    mutating func reset() {
        scheduledFrameCount = 0
        renderedFrameCount = 0
        ranges.removeAll(keepingCapacity: true)
    }
}
