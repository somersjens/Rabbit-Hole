#if DEBUG
import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

/// Launch-argument-only App Store capture. Nothing in this namespace is
/// reachable from a Release build.
enum PromoMode {
    static let launchArgument = "-RabbitHolePromo"
    static let iPadFormatArgument = "-RabbitHolePromoFormat-ipad"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static var format: PromoFormat {
        ProcessInfo.processInfo.arguments.contains(iPadFormatArgument) ? .iPad : .iPhone
    }
}

enum PromoFormat: String {
    case iPhone = "iphone"
    case iPad = "ipad"

    var isPad: Bool { self == .iPad }

    var outputPixels: CGSize {
        switch self {
        case .iPhone: return CGSize(width: 886, height: 1920)
        case .iPad: return CGSize(width: 1200, height: 1600)
        }
    }

    var fileName: String {
        switch self {
        case .iPhone: return "rabbit-hole-app-store-teaser-886x1920.mp4"
        case .iPad: return "rabbit-hole-app-store-teaser-1200x1600.mp4"
        }
    }

    var safeTop: CGFloat { isPad ? 24 : 47 }
    var safeBottom: CGFloat { isPad ? 20 : 34 }
    var framesPerSecond: Int { 30 }
}

/// Timestamps of production SFX, measured from the first captured frame.
enum PromoAudioLog {
    private static let lock = NSLock()
    private static var start: TimeInterval?
    private static var events: [(time: Double, key: String)] = []

    static func reset() {
        lock.lock()
        start = nil
        events = []
        lock.unlock()
    }

    static func markStart() {
        lock.lock()
        start = CACurrentMediaTime()
        events = []
        lock.unlock()
    }

    static func record(_ key: String) {
        lock.lock()
        guard let start else {
            lock.unlock()
            return
        }
        events.append((CACurrentMediaTime() - start, key))
        lock.unlock()
    }

    static func snapshot() -> [[String: Any]] {
        lock.lock()
        let copy = events
        lock.unlock()
        return copy.map { ["t": $0.time, "key": $0.key] }
    }

    static var elapsed: Double {
        lock.lock()
        let origin = start
        lock.unlock()
        guard let origin else { return 0 }
        return CACurrentMediaTime() - origin
    }
}

enum PromoScript {
    static let headlineGrab = "Grab the correct carrot"
    static let headlineUnlock = "Unlock new characters"
    static let headlineDynamite = "Watch out for dynamite!"

    /// The first production floor uses all eight normal swing pockets. Its
    /// answers are arranged so each target is reached by the ordinary hook.
    static let firstFloorByPocket: [Int: String] = [
        0: "48",
        1: "18",
        2: "52",
        3: "56",
        // pocket 4 is dynamite
        // The first four scripted actions follow adjacent natural swing lanes:
        // 15 → wrong 12 → Octopus 18, then back toward Frog 56.
        5: "13",
        6: "12",
        7: "15"
    ]

    static let lowerFloorByPocket: [Int: String] = [
        // At the landing the ordinary swing is crossing centre toward the
        // left. Place the montage along that real direction so the claw owns
        // each next lane naturally while the previous score flies upward.
        0: "18",
        1: "13",
        3: "15"
        // pocket 4 is the final dynamite
    ]

    static var rounds: [GameRound] {
        [
            makeRound(1, "9 + 6 = ?", "15", ["14", "16", "17"], .addition),
            makeRound(2, "26 − 8 = ?", "18", ["12", "16", "20"], .subtraction),
            makeRound(3, "7 × 8 = ?", "56", ["48", "54", "63"], .multiplication),
            makeRound(4, "5 × 3 = ?", "15", ["10", "20", "25"], .multiplication),
            makeRound(5, "9 × 2 = ?", "18", ["16", "20", "27"], .multiplication),
            makeRound(6, "17 − 4 = ?", "13", ["11", "12", "14"], .subtraction)
        ]
    }

    static var sessionRequest: GameSessionRequest {
        GameSessionRequest(level: MathLevel(topic: .addition, index: 9), mode: .order)
    }

    private static func makeRound(_ number: Int,
                                  _ prompt: String,
                                  _ correct: String,
                                  _ distractors: [String],
                                  _ kind: QuestionKind) -> GameRound {
        let question = MathQuestion(prompt: prompt,
                                    correctAnswer: correct,
                                    distractors: distractors,
                                    sourceLevel: 1,
                                    kind: kind)
        var options = [AnswerOption(text: correct, isCorrect: true)]
        options.append(contentsOf: distractors.map {
            AnswerOption(text: $0, isCorrect: false)
        })
        return GameRound(number: number, question: question, options: options)
    }
}
#endif
