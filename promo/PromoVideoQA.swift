import Foundation
import AVFoundation
import AppKit

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("PromoVideoQA: \(message)\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count >= 4 else {
    fail("usage: swift PromoVideoQA.swift VIDEO OUTPUT_DIR TIME [TIME ...]")
}

let videoURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let times = CommandLine.arguments.dropFirst(3).compactMap(Double.init)
let asset = AVURLAsset(url: videoURL)
guard let track = asset.tracks(withMediaType: .video).first else { fail("no video track") }
try? FileManager.default.createDirectory(at: outputDirectory,
                                         withIntermediateDirectories: true)

let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
var contactFrames: [(time: Double, image: CGImage)] = []
for time in times {
    let safeTime = min(max(0, time), max(0, asset.duration.seconds - 0.02))
    let image = try generator.copyCGImage(at: CMTime(seconds: safeTime,
                                                      preferredTimescale: 600),
                                          actualTime: nil)
    let representation = NSBitmapImageRep(cgImage: image)
    contactFrames.append((safeTime, image))
    guard let data = representation.representation(using: .jpeg,
                                                    properties: [.compressionFactor: 0.86]) else {
        fail("could not encode frame at \(safeTime)")
    }
    let name = String(format: "t-%06.2f.jpg", safeTime)
    try data.write(to: outputDirectory.appendingPathComponent(name))
}

if !contactFrames.isEmpty {
    let columns = 4
    let tileWidth = 270
    let imageHeight = 390
    let labelHeight = 30
    let tileHeight = imageHeight + labelHeight
    let rows = Int(ceil(Double(contactFrames.count) / Double(columns)))
    let sheetWidth = columns * tileWidth
    let sheetHeight = rows * tileHeight
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                        pixelsWide: sheetWidth,
                                        pixelsHigh: sheetHeight,
                                        bitsPerSample: 8,
                                        samplesPerPixel: 4,
                                        hasAlpha: true,
                                        isPlanar: false,
                                        colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0,
                                        bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fail("could not create contact sheet")
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    NSColor(calibratedWhite: 0.07, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0,
                              width: sheetWidth, height: sheetHeight)).fill()
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold),
        .foregroundColor: NSColor.white
    ]
    for (index, frame) in contactFrames.enumerated() {
        let column = index % columns
        let row = index / columns
        let tileX = column * tileWidth
        let tileY = sheetHeight - (row + 1) * tileHeight
        let sourceSize = CGSize(width: frame.image.width, height: frame.image.height)
        let scale = min(CGFloat(tileWidth - 12) / sourceSize.width,
                        CGFloat(imageHeight - 12) / sourceSize.height)
        let drawnSize = CGSize(width: sourceSize.width * scale,
                               height: sourceSize.height * scale)
        let rect = NSRect(x: CGFloat(tileX) + (CGFloat(tileWidth) - drawnSize.width) / 2,
                          y: CGFloat(tileY + labelHeight) +
                            (CGFloat(imageHeight) - drawnSize.height) / 2,
                          width: drawnSize.width,
                          height: drawnSize.height)
        NSImage(cgImage: frame.image, size: sourceSize).draw(in: rect)
        NSString(format: "%.2f s", frame.time).draw(
            at: NSPoint(x: tileX + 10, y: tileY + 6),
            withAttributes: attributes
        )
    }
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    guard let sheetData = bitmap.representation(using: .jpeg,
                                                properties: [.compressionFactor: 0.88]) else {
        fail("could not encode contact sheet")
    }
    try sheetData.write(to: outputDirectory.appendingPathComponent("contact-sheet.jpg"))
}

let reader = try AVAssetReader(asset: asset)
let videoOutput = AVAssetReaderTrackOutput(track: track,
                                           outputSettings: [
                                            kCVPixelBufferPixelFormatTypeKey as String:
                                                kCVPixelFormatType_32BGRA
                                           ])
guard reader.canAdd(videoOutput) else { fail("cannot attach decode output") }
reader.add(videoOutput)
guard reader.startReading() else { fail("decode could not start") }
var decodedFrames = 0
while let sample = videoOutput.copyNextSampleBuffer() {
    decodedFrames += 1
    CMSampleBufferInvalidate(sample)
}
guard reader.status == .completed else {
    fail("decode failed after \(decodedFrames) frames: \(reader.error?.localizedDescription ?? "unknown")")
}

let audioTracks = asset.tracks(withMediaType: .audio)
var decodedAudioSamples = 0
if let audioTrack = audioTracks.first {
    let audioReader = try AVAssetReader(asset: asset)
    let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
    guard audioReader.canAdd(audioOutput) else { fail("cannot attach audio decode output") }
    audioReader.add(audioOutput)
    guard audioReader.startReading() else { fail("audio decode could not start") }
    while let sample = audioOutput.copyNextSampleBuffer() {
        decodedAudioSamples += 1
        CMSampleBufferInvalidate(sample)
    }
    guard audioReader.status == .completed else {
        fail("audio decode failed: \(audioReader.error?.localizedDescription ?? "unknown")")
    }
}

print("decoded \(videoURL.lastPathComponent): \(decodedFrames) video frames, " +
      "\(decodedAudioSamples) audio samples, \(Int(track.naturalSize.width))x\(Int(track.naturalSize.height)), " +
      "nominal \(String(format: "%.3f", track.nominalFrameRate)) fps, " +
      "\(String(format: "%.3f", asset.duration.seconds)) s")
