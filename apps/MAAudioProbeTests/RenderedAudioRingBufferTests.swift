import Testing
@testable import MAAudioProbe

@Suite("Rendered audio ring buffer")
struct RenderedAudioRingBufferTests {
    @Test("Four-second extraction survives wraparound")
    func wraparoundExtraction() throws {
        var buffer = try RenderedAudioRingBuffer(sampleRate: 10, capacitySeconds: 6)
        buffer.append((0..<80).map(Float.init))

        let window = try buffer.window(endingAt: 80, duration: 4)

        #expect(buffer.oldestAvailableFrame == 20)
        #expect(window.startFrame == 40)
        #expect(window.endFrameExclusive == 80)
        #expect(window.samples == (40..<80).map(Float.init))
        #expect(window.duration == 4)
    }

    @Test("Decoded or scheduled future audio cannot enter a rendered window")
    func excludesUnplayedAudio() throws {
        var buffer = try RenderedAudioRingBuffer(sampleRate: 10, capacitySeconds: 6)
        buffer.append((0..<40).map(Float.init))

        #expect(throws: RenderedAudioRingBufferError.unplayedAudioRequested) {
            try buffer.window(endingAt: 41, duration: 4)
        }
    }

    @Test("Overwritten and incomplete windows fail instead of fabricating samples")
    func unavailableWindowsFail() throws {
        var buffer = try RenderedAudioRingBuffer(sampleRate: 10, capacitySeconds: 6)
        buffer.append((0..<20).map(Float.init))
        #expect(throws: RenderedAudioRingBufferError.insufficientRenderedAudio) {
            try buffer.window(endingAt: 20, duration: 4)
        }

        buffer.append((20..<90).map(Float.init))
        #expect(throws: RenderedAudioRingBufferError.renderedAudioOverwritten) {
            try buffer.window(endingAt: 50, duration: 4)
        }
    }

    @Test("Non-finite rendered samples are made inert")
    func nonFiniteSamples() throws {
        var buffer = try RenderedAudioRingBuffer(sampleRate: 1, capacitySeconds: 4)
        buffer.append([Float.nan, .infinity, -.infinity, 0.5])

        let window = try buffer.window(endingAt: 4, duration: 4)

        #expect(window.samples == [0, 0, 0, 0.5])
    }
}
