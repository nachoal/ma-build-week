@preconcurrency import AVFAudio
import Foundation

struct RealtimeCaptureSnapshot: Sendable {
    let duration: TimeInterval
    let estimatedVoiceOnset: TimeInterval?
    let speechPresence: Bool
    let sourceSampleRate: Double
    let pcm16Data: Data
    let overflowed: Bool
}

/// Converts the explicit learner turn to bounded 24 kHz mono PCM16 off the
/// realtime callback. PCM is held only in memory until the turn is committed.
final class RealtimeCaptureWorker: @unchecked Sendable {
    private let queue = DispatchQueue(
        label: "com.ia.ma.realtime-capture",
        qos: .userInitiated
    )
    private let maximumPCMBytes = 576_000
    private let outputFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24_000,
        channels: 1,
        interleaved: false
    )!

    private var converter: AVAudioConverter?
    private var converterInputRate: Double = 0
    private var pcm16Data = Data()
    private var totalFrames: Int64 = 0
    private var firstVoiceFrame: Int64?
    private var voicedPacketCount = 0
    private var sampleRate: Double = 0
    private var overflowed = false

    func enqueue(samples: [Float], sampleRate: Double) {
        guard !samples.isEmpty,
              samples.count <= 8_192,
              sampleRate.isFinite,
              sampleRate > 0 else { return }
        queue.async { [self] in
            if self.sampleRate == 0 {
                self.sampleRate = sampleRate
            }
            guard abs(self.sampleRate - sampleRate) < 0.5 else { return }

            var energy: Double = 0
            for sample in samples where sample.isFinite {
                let value = Double(sample)
                energy += value * value
            }
            let rms = sqrt(energy / Double(samples.count))
            if rms >= 0.025 {
                if firstVoiceFrame == nil {
                    firstVoiceFrame = totalFrames
                }
                voicedPacketCount += 1
            }
            totalFrames += Int64(samples.count)

            guard !overflowed,
                  let converted = convertToPCM16(samples, sampleRate: sampleRate) else {
                return
            }
            guard pcm16Data.count + converted.count <= maximumPCMBytes else {
                overflowed = true
                pcm16Data.removeAll(keepingCapacity: false)
                return
            }
            pcm16Data.append(converted)
        }
    }

    func finishSnapshot() -> RealtimeCaptureSnapshot {
        queue.sync {
            defer { pcm16Data.removeAll(keepingCapacity: false) }
            let rate = sampleRate
            let presence = voicedPacketCount >= 2
            return RealtimeCaptureSnapshot(
                duration: rate > 0 ? Double(totalFrames) / rate : 0,
                estimatedVoiceOnset: presence
                    ? firstVoiceFrame.map { Double($0) / rate }
                    : nil,
                speechPresence: presence,
                sourceSampleRate: rate,
                pcm16Data: pcm16Data,
                overflowed: overflowed
            )
        }
    }

    private func convertToPCM16(
        _ samples: [Float],
        sampleRate: Double
    ) -> Data? {
        guard let inputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ),
              let inputBuffer = AVAudioPCMBuffer(
                  pcmFormat: inputFormat,
                  frameCapacity: AVAudioFrameCount(samples.count)
              ),
              let inputChannel = inputBuffer.floatChannelData?[0] else {
            return nil
        }

        inputBuffer.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { source in
            if let baseAddress = source.baseAddress {
                inputChannel.update(from: baseAddress, count: source.count)
            }
        }

        if converter == nil || abs(converterInputRate - sampleRate) >= 0.5 {
            converter = AVAudioConverter(from: inputFormat, to: outputFormat)
            converter?.primeMethod = .none
            converterInputRate = sampleRate
        }
        guard let converter else { return nil }

        let ratio = outputFormat.sampleRate / sampleRate
        let capacity = AVAudioFrameCount(
            max(1, Int((Double(samples.count) * ratio).rounded(.up)) + 32)
        )
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: capacity
        ) else { return nil }

        let supply = RealtimeConverterSupplyState()
        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) {
            _, inputStatus in
            if supply.supplied {
                inputStatus.pointee = .noDataNow
                return nil
            }
            supply.supplied = true
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
}

private final class RealtimeConverterSupplyState: @unchecked Sendable {
    var supplied = false
}
