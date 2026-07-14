@preconcurrency import AVFAudio
import Foundation

struct CapturedFloatFrame: Sendable {
    let samples: [Float]
    let sampleRate: Double
    let timing: AudioTapTiming
}

final class AudioCallbackWorker: @unchecked Sendable {
    typealias InputSink = @Sendable (Data) async -> Void

    private struct ConvertedInput: Sendable {
        let data: Data
        let sourceRate: Double
        let sourceFrameCount: Int
        let timing: AudioTapTiming
    }

    private struct RenderedPacket: Sendable {
        let samples: [Float]
        let timing: AudioTapTiming
    }

    private let queue = DispatchQueue(
        label: "com.ia.ma.audio-probe.callback-worker",
        qos: .userInteractive
    )
    private let inputSink: InputSink
    private let evidenceStore: AudioGraphEvidenceStore
    private let diagnostics: ProbeDiagnostics
    private let inputContinuation: AsyncStream<ConvertedInput>.Continuation
    private let renderedContinuation: AsyncStream<RenderedPacket>.Continuation
    private var inputConsumerTask: Task<Void, Never>?
    private var renderedConsumerTask: Task<Void, Never>?
    private var converter: AVAudioConverter?
    private var converterInputRate: Double = 0
    private let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24_000,
        channels: 1,
        interleaved: false
    )!

    init(
        inputSink: @escaping InputSink,
        evidenceStore: AudioGraphEvidenceStore,
        diagnostics: ProbeDiagnostics
    ) {
        let (inputStream, inputContinuation) = AsyncStream.makeStream(
            of: ConvertedInput.self,
            bufferingPolicy: .bufferingNewest(32)
        )
        let (renderedStream, renderedContinuation) = AsyncStream.makeStream(
            of: RenderedPacket.self,
            bufferingPolicy: .bufferingNewest(64)
        )
        self.inputSink = inputSink
        self.evidenceStore = evidenceStore
        self.diagnostics = diagnostics
        self.inputContinuation = inputContinuation
        self.renderedContinuation = renderedContinuation

        inputConsumerTask = Task { [inputSink, diagnostics] in
            for await input in inputStream {
                await diagnostics.record(
                    .microphoneFrame,
                    details: [
                        "bytes": String(input.data.count),
                        "frames": String(input.sourceFrameCount),
                        "host_ns": Self.hostNanoseconds(input.timing.hostTime),
                        "host_time": input.timing.hostTime.map { String($0) } ?? "none",
                        "sample_time": input.timing.sampleTime.map { String($0) } ?? "none",
                        "source_rate": String(Int(input.sourceRate)),
                    ]
                )
                await inputSink(input.data)
            }
        }
        renderedConsumerTask = Task { [evidenceStore, diagnostics] in
            for await packet in renderedStream {
                await evidenceStore.appendRenderedMixerSamples(
                    packet.samples,
                    timing: packet.timing
                )
                await diagnostics.record(
                    .playbackRendered,
                    details: [
                        "frames": String(packet.samples.count),
                        "host_ns": Self.hostNanoseconds(packet.timing.hostTime),
                        "host_time": packet.timing.hostTime.map { String($0) } ?? "none",
                        "rate": String(Int(packet.timing.sampleRate)),
                        "sample_time": packet.timing.sampleTime.map { String($0) } ?? "none",
                    ]
                )
            }
        }
    }

    deinit {
        inputContinuation.finish()
        renderedContinuation.finish()
        inputConsumerTask?.cancel()
        renderedConsumerTask?.cancel()
    }

    func enqueueInput(_ frame: CapturedFloatFrame) {
        queue.async { [self] in
            guard let data = convertToPCM16(frame), !data.isEmpty else { return }
            let result = inputContinuation.yield(
                ConvertedInput(
                    data: data,
                    sourceRate: frame.sampleRate,
                    sourceFrameCount: frame.samples.count,
                    timing: frame.timing
                )
            )
            if case .dropped = result {
                Task { [diagnostics] in
                    await diagnostics.record(
                        .error,
                        details: ["stage": "input_stream", "category": "packet_dropped"]
                    )
                }
            }
        }
    }

    func enqueueRendered(_ samples: [Float], timing: AudioTapTiming) {
        queue.async { [evidenceStore, renderedContinuation] in
            let result = renderedContinuation.yield(
                RenderedPacket(samples: samples, timing: timing)
            )
            if case .dropped = result {
                Task { await evidenceStore.noteRenderedPacketDrop() }
            }
        }
    }

    private func convertToPCM16(_ frame: CapturedFloatFrame) -> Data? {
        guard frame.sampleRate.isFinite,
              frame.sampleRate > 0,
              !frame.samples.isEmpty,
              frame.samples.count <= 19_200,
              let inputFormat = AVAudioFormat(
                  commonFormat: .pcmFormatFloat32,
                  sampleRate: frame.sampleRate,
                  channels: 1,
                  interleaved: false
              ),
              let inputBuffer = AVAudioPCMBuffer(
                  pcmFormat: inputFormat,
                  frameCapacity: AVAudioFrameCount(frame.samples.count)
              ),
              let inputChannel = inputBuffer.floatChannelData?[0] else {
            return nil
        }

        inputBuffer.frameLength = AVAudioFrameCount(frame.samples.count)
        frame.samples.withUnsafeBufferPointer { source in
            inputChannel.update(from: source.baseAddress!, count: source.count)
        }

        if converter == nil || converterInputRate != frame.sampleRate {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            converter?.primeMethod = .none
            converterInputRate = frame.sampleRate
        }
        guard let converter else { return nil }

        let ratio = outputFormat.sampleRate / frame.sampleRate
        let outputCapacity = AVAudioFrameCount(
            max(1, Int((Double(frame.samples.count) * ratio).rounded(.up)) + 32)
        )
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: outputCapacity
        ) else {
            return nil
        }

        let supplyState = ConverterInputSupplyState()
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) {
            _, inputStatus in
            if supplyState.suppliedInput {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supplyState.suppliedInput = true
            inputStatus.pointee = .haveData
            return inputBuffer
        }
        guard conversionError == nil,
              status != .error,
              outputBuffer.frameLength > 0,
              let channel = outputBuffer.int16ChannelData?[0] else {
            return nil
        }
        return Data(
            bytes: channel,
            count: Int(outputBuffer.frameLength) * MemoryLayout<Int16>.size
        )
    }

    private static func hostNanoseconds(_ hostTime: UInt64?) -> String {
        guard let hostTime else { return "none" }
        let seconds = AVAudioTime.seconds(forHostTime: hostTime)
        guard seconds.isFinite, seconds >= 0,
              seconds <= Double(UInt64.max) / 1_000_000_000 else {
            return "none"
        }
        return String(UInt64((seconds * 1_000_000_000).rounded()))
    }
}

private final class ConverterInputSupplyState: @unchecked Sendable {
    var suppliedInput = false
}
