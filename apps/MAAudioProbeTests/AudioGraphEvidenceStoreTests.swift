import Testing
@testable import MAAudioProbe

@Suite("Audio graph evidence mapping")
struct AudioGraphEvidenceStoreTests {
    @Test("Player timeline gaps never mark unscheduled content rendered")
    func gapAwareMapping() async throws {
        let store = AudioGraphEvidenceStore(playbackSampleRate: 1_000)
        try await store.schedule(
            itemID: "item_1",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 0
        )
        try await store.schedule(
            itemID: "item_2",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 200
        )

        let inGap = try await store.stop(playerRenderedFrame: 150)

        #expect(inGap.truncationTarget?.itemID == "item_1")
        #expect(inGap.truncationTarget?.audioEndMilliseconds == 100)
    }

    @Test("Cursor inside a later range maps to item-relative content time")
    func laterRangeMapping() async throws {
        let store = AudioGraphEvidenceStore(playbackSampleRate: 1_000)
        try await store.schedule(
            itemID: "item_1",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 0
        )
        try await store.schedule(
            itemID: "item_2",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 200
        )

        let evidence = try await store.stop(playerRenderedFrame: 250)

        #expect(evidence.truncationTarget?.itemID == "item_2")
        #expect(evidence.truncationTarget?.audioEndMilliseconds == 50)
    }

    @Test("Mixer reconfiguration starts a fresh playout epoch")
    func mixerReconfigurationResetsLedger() async throws {
        let store = AudioGraphEvidenceStore(playbackSampleRate: 1_000)
        try await store.schedule(
            itemID: "old_item",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 0
        )

        try await store.configureMixer(sampleRate: 48_000)
        try await store.schedule(
            itemID: "new_item",
            contentIndex: 0,
            frameCount: 100,
            playerStartFrame: 0
        )
        let evidence = try await store.stop(playerRenderedFrame: 50)

        #expect(evidence.truncationTarget?.itemID == "new_item")
        #expect(evidence.truncationTarget?.audioEndMilliseconds == 50)
    }
}
