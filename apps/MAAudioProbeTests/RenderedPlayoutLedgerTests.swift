import Testing
@testable import MAAudioProbe

@Suite("Rendered playout ledger")
struct RenderedPlayoutLedgerTests {
    @Test("Truncation is derived from the rendered cursor within one item")
    func renderDerivedTruncation() throws {
        var ledger = try RenderedPlayoutLedger(sampleRate: 24_000)
        try ledger.schedule(itemID: "item_1", contentIndex: 0, frameCount: 24_000)
        try ledger.schedule(itemID: "item_1", contentIndex: 0, frameCount: 24_000)
        try ledger.markRendered(through: 30_000)

        #expect(
            ledger.truncationTarget() == RenderedTruncationTarget(
                itemID: "item_1",
                contentIndex: 0,
                renderedGlobalFrame: 30_000,
                audioEndMilliseconds: 1_250
            )
        )
    }

    @Test("An item boundary resolves to the item actually rendered")
    func itemBoundary() throws {
        var ledger = try RenderedPlayoutLedger(sampleRate: 24_000)
        try ledger.schedule(itemID: "item_1", contentIndex: 0, frameCount: 12_000)
        try ledger.schedule(itemID: "item_2", contentIndex: 0, frameCount: 12_000)

        try ledger.markRendered(through: 12_000)
        #expect(ledger.truncationTarget()?.itemID == "item_1")
        #expect(ledger.truncationTarget()?.audioEndMilliseconds == 500)

        try ledger.markRendered(through: 18_000)
        #expect(ledger.truncationTarget()?.itemID == "item_2")
        #expect(ledger.truncationTarget()?.audioEndMilliseconds == 250)
    }

    @Test("Decoded or scheduled future frames cannot become rendered evidence")
    func rejectsFutureAndBackwardCursors() throws {
        var ledger = try RenderedPlayoutLedger(sampleRate: 24_000)
        try ledger.schedule(itemID: "item_1", contentIndex: 0, frameCount: 24_000)
        try ledger.markRendered(through: 12_000)

        #expect(throws: RenderedPlayoutLedgerError.unplayedAudioMarkedRendered) {
            try ledger.markRendered(through: 24_001)
        }
        #expect(throws: RenderedPlayoutLedgerError.renderCursorMovedBackward) {
            try ledger.markRendered(through: 11_999)
        }
    }

    @Test("Reset invalidates the old player timeline")
    func reset() throws {
        var ledger = try RenderedPlayoutLedger(sampleRate: 24_000)
        try ledger.schedule(itemID: "item_1", contentIndex: 0, frameCount: 24_000)
        try ledger.markRendered(through: 12_000)

        ledger.reset()

        #expect(ledger.scheduledFrameCount == 0)
        #expect(ledger.renderedFrameCount == 0)
        #expect(ledger.ranges.isEmpty)
        #expect(ledger.truncationTarget() == nil)
    }
}
