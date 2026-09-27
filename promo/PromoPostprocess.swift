import Foundation
import AVFoundation
import CoreGraphics

struct Cue: Decodable {
    let t: Double
    let key: String
}

struct SoundSpec {
    let file: String
    let ext: String
    let volume: Float
}

private let soundSpecs: [String: SoundSpec] = [
    "correct": .init(file: "sfx_correct", ext: "caf", volume: 0.14),
    "wrong": .init(file: "sfx_wrong", ext: "caf", volume: 0.11),
    "explosion": .init(file: "sfx_explosion", ext: "caf", volume: 0.30),
    "extensionMoveOut": .init(file: "sfx_extension_move_out", ext: "caf", volume: 0.28),
    "itemContact": .init(file: "sfx_item_contact", ext: "caf", volume: 0.36),
    "cardReveal": .init(file: "sfx_card_reveal", ext: "caf", volume: 0.19),
    "sessionComplete": .init(file: "sfx_level_complete", ext: "caf", volume: 0.22),
    "characterUnlock": .init(file: "sfx_character_unlock", ext: "caf", volume: 0.20),
    "cardTotal": .init(file: "score_increase_in_game", ext: "caf", volume: 0.65),
    "sessionStart": .init(file: "sfx_session_start", ext: "caf", volume: 0.16)
]

private func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data(("PromoPostprocess: \(message)\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 9 else {
    fail("usage: swift PromoPostprocess.swift RAW CUES OUTPUT TRIM DURATION WIDTH HEIGHT ASSET_DIR")
}

let rawURL = URL(fileURLWithPath: CommandLine.arguments[1])
let cuesURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])
guard let trimSeconds = Double(CommandLine.arguments[4]),
      let durationSeconds = Double(CommandLine.arguments[5]),
      let width = Int(CommandLine.arguments[6]),
      let height = Int(CommandLine.arguments[7]) else {
    fail("invalid numeric argument")
}
let assetDirectory = URL(fileURLWithPath: CommandLine.arguments[8], isDirectory: true)

let rawAsset = AVURLAsset(url: rawURL)
guard let rawVideo = rawAsset.tracks(withMediaType: .video).first else {
    fail("raw capture has no video track")
}
let rawDuration = rawAsset.duration.seconds
guard trimSeconds >= 0,
      durationSeconds > 0,
      trimSeconds + durationSeconds <= rawDuration + 0.05 else {
    fail("requested time range is outside raw capture")
}

let outputDuration = CMTime(seconds: durationSeconds, preferredTimescale: 600)
let composition = AVMutableComposition()
let musicURL = assetDirectory.appendingPathComponent("music_background.m4a")
var insertedMusicTrack: AVAssetTrack?
if FileManager.default.fileExists(atPath: musicURL.path) {
    let musicAsset = AVURLAsset(url: musicURL)
    do {
        // Asset-level insertion correctly preserves this AAC file's priming
        // metadata; track-level insertion rejects it on current AVFoundation.
        try composition.insertTimeRange(CMTimeRange(start: .zero,
                                                    duration: musicAsset.duration),
                                        of: musicAsset,
                                        at: .zero)
    } catch {
        fail("could not insert background music: \(error)")
    }
    insertedMusicTrack = composition.tracks(withMediaType: .audio).first
}

guard let videoTrack = composition.addMutableTrack(
    withMediaType: .video,
    preferredTrackID: kCMPersistentTrackID_Invalid
) else { fail("could not create video composition track") }

do {
    try videoTrack.insertTimeRange(
        CMTimeRange(
            start: CMTime(seconds: trimSeconds, preferredTimescale: 600),
            duration: outputDuration
        ),
        of: rawVideo,
        at: .zero
    )
} catch {
    fail("could not insert source video: \(error)")
}

let renderSize = CGSize(width: width, height: height)
let sourceSize = rawVideo.naturalSize
let scale = max(renderSize.width / sourceSize.width,
                renderSize.height / sourceSize.height)
let scaledSize = CGSize(width: sourceSize.width * scale,
                        height: sourceSize.height * scale)
let offset = CGPoint(x: (renderSize.width - scaledSize.width) / 2,
                     y: (renderSize.height - scaledSize.height) / 2)
let transform = CGAffineTransform(scaleX: scale, y: scale)
    .concatenating(CGAffineTransform(translationX: offset.x / scale,
                                     y: offset.y / scale))

let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
layerInstruction.setTransform(transform, at: .zero)
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: outputDuration)
instruction.layerInstructions = [layerInstruction]
let videoComposition = AVMutableVideoComposition()
videoComposition.renderSize = renderSize
videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
videoComposition.instructions = [instruction]

var audioParameters: [AVMutableAudioMixInputParameters] = []

if let musicTrack = insertedMusicTrack {
    let parameters = AVMutableAudioMixInputParameters(track: musicTrack)
    parameters.setVolume(0, at: .zero)
    parameters.setVolumeRamp(fromStartVolume: 0,
                             toEndVolume: 0.45,
                             timeRange: CMTimeRange(start: .zero,
                                                    duration: CMTime(seconds: 0.45,
                                                                     preferredTimescale: 600)))
    let fadeStart = CMTime(seconds: max(0, durationSeconds - 0.75), preferredTimescale: 600)
    parameters.setVolumeRamp(fromStartVolume: 0.45,
                             toEndVolume: 0,
                             timeRange: CMTimeRange(start: fadeStart,
                                                    duration: CMTimeSubtract(outputDuration,
                                                                             fadeStart)))
    audioParameters.append(parameters)
}

let cues: [Cue]
do {
    cues = try JSONDecoder().decode([Cue].self, from: Data(contentsOf: cuesURL))
} catch {
    fail("could not decode cue log: \(error)")
}

struct EffectLane {
    let track: AVMutableCompositionTrack
    let parameters: AVMutableAudioMixInputParameters
    var availableAt: CMTime
}

var effectLanes: [EffectLane] = []
let finalCarrotContact = cues.last(where: { $0.key == "itemContact" })?.t
for cue in cues.sorted(by: { $0.t < $1.t }) {
    // The last accelerated pickup reads visually one frame after its callback.
    // Move only its contact/correct transients two frames later; the winch cue
    // remains locked to the actual start of the extension.
    let delaysFinalCarrotSound = finalCarrotContact.map {
        abs(cue.t - $0) < 0.08 && (cue.key == "itemContact" || cue.key == "correct")
    } ?? false
    let cueTime = cue.t + (delaysFinalCarrotSound ? 0.07 : 0)
    guard cueTime >= 0, cueTime < durationSeconds,
          let spec = soundSpecs[cue.key] else { continue }
    let url = assetDirectory.appendingPathComponent("\(spec.file).\(spec.ext)")
    let asset = AVURLAsset(url: url)
    guard let source = asset.tracks(withMediaType: .audio).first else { continue }
    let start = CMTime(seconds: cueTime, preferredTimescale: 600)
    let slice = CMTimeMinimum(asset.duration, CMTimeSubtract(outputDuration, start))
    guard slice.seconds > 0 else { continue }
    let laneIndex: Int
    if let reusable = effectLanes.firstIndex(where: { $0.availableAt <= start }) {
        laneIndex = reusable
    } else {
        guard let track = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { continue }
        let parameters = AVMutableAudioMixInputParameters(track: track)
        parameters.setVolume(0, at: CMTime.zero)
        effectLanes.append(EffectLane(track: track,
                                      parameters: parameters,
                                      availableAt: .zero))
        laneIndex = effectLanes.count - 1
    }
    let lane = effectLanes[laneIndex]
    do {
        try lane.track.insertTimeRange(CMTimeRange(start: .zero, duration: slice),
                                       of: source,
                                       at: start)
    } catch {
        fail("could not place cue \(cue.key) at \(cue.t): \(error)")
    }
    lane.parameters.setVolume(spec.volume, at: start)
    effectLanes[laneIndex].availableAt = CMTimeAdd(start, slice)
}
audioParameters.append(contentsOf: effectLanes.map(\.parameters))

let audioMix = AVMutableAudioMix()
audioMix.inputParameters = audioParameters

try? FileManager.default.removeItem(at: outputURL)
try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                         withIntermediateDirectories: true)
guard let exporter = AVAssetExportSession(asset: composition,
                                          presetName: AVAssetExportPresetHighestQuality) else {
    fail("could not create exporter")
}
exporter.outputURL = outputURL
exporter.outputFileType = .mp4
exporter.shouldOptimizeForNetworkUse = true
exporter.timeRange = CMTimeRange(start: .zero, duration: outputDuration)
exporter.videoComposition = videoComposition
exporter.audioMix = audioMix

let semaphore = DispatchSemaphore(value: 0)
exporter.exportAsynchronously { semaphore.signal() }
semaphore.wait()
guard exporter.status == .completed else {
    fail("export failed: \(String(describing: exporter.error))")
}
print("exported \(outputURL.path) — \(width)x\(height), 30 fps, \(String(format: "%.3f", durationSeconds)) s")
