import AVFoundation
import Foundation

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("PromoAudioQA: \(message)\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count >= 2 else {
    fail("usage: swift PromoAudioQA.swift AUDIO_OR_VIDEO [AUDIO_OR_VIDEO ...]")
}

for path in CommandLine.arguments.dropFirst() {
    let asset = AVURLAsset(url: URL(fileURLWithPath: path))
    guard let track = asset.tracks(withMediaType: .audio).first else {
        fail("no audio track in \(path)")
    }
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(
        track: track,
        outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsNonInterleaved: false
        ]
    )
    guard reader.canAdd(output) else { fail("cannot decode \(path)") }
    reader.add(output)
    guard reader.startReading() else { fail("cannot start \(path)") }

    var sumSquares = 0.0
    var peak = 0.0
    var count = 0
    var bucketSquares = Array(repeating: 0.0, count: 24)
    var bucketPeaks = Array(repeating: 0.0, count: 24)
    var bucketCounts = Array(repeating: 0, count: 24)
    while let sample = output.copyNextSampleBuffer(),
          let buffer = CMSampleBufferGetDataBuffer(sample) {
        let seconds = max(0, CMSampleBufferGetPresentationTimeStamp(sample).seconds)
        let bucket = min(bucketSquares.count - 1, Int(seconds / 5))
        var length = 0
        var pointer: UnsafeMutablePointer<Int8>?
        guard CMBlockBufferGetDataPointer(buffer,
                                          atOffset: 0,
                                          lengthAtOffsetOut: nil,
                                          totalLengthOut: &length,
                                          dataPointerOut: &pointer) == kCMBlockBufferNoErr,
              let pointer else { continue }
        pointer.withMemoryRebound(to: Float.self, capacity: length / 4) { samples in
            for index in 0..<(length / 4) {
                let value = Double(samples[index])
                sumSquares += value * value
                peak = max(peak, abs(value))
                bucketSquares[bucket] += value * value
                bucketPeaks[bucket] = max(bucketPeaks[bucket], abs(value))
            }
        }
        count += length / 4
        bucketCounts[bucket] += length / 4
    }
    guard reader.status == .completed, count > 0 else {
        fail("decode failed for \(path): \(reader.error?.localizedDescription ?? "unknown")")
    }
    let rms = sqrt(sumSquares / Double(count))
    let rmsDB = 20 * log10(max(rms, 0.000_000_1))
    let peakDB = 20 * log10(max(peak, 0.000_000_1))
    print("\(path): RMS \(String(format: "%.2f", rmsDB)) dBFS, " +
          "peak \(String(format: "%.2f", peakDB)) dBFS, \(count) samples")
    for bucket in bucketCounts.indices where bucketCounts[bucket] > 0 {
        let bucketRMS = sqrt(bucketSquares[bucket] / Double(bucketCounts[bucket]))
        let bucketRMSDB = 20 * log10(max(bucketRMS, 0.000_000_1))
        let bucketPeakDB = 20 * log10(max(bucketPeaks[bucket], 0.000_000_1))
        print(String(format: "  %02d–%02d s: RMS %.2f dBFS, peak %.2f dBFS",
                     bucket * 5, (bucket + 1) * 5, bucketRMSDB, bucketPeakDB))
    }
}
