//
//  RabbitHoleArena.swift
//  Rabbit Hole
//
//  The underground round: a crane trolley aiming over a variable set of carrots and one
//  stick of dynamite, laid in a zipper the boom can reach. Taps freeze the
//  trolley and extend the claw. The right carrot flies up to the score; a
//  wrong one is thrown away; dynamite — grabbed or timed out — blows the
//  floor open across the pit. The digger falls along the walls onto the
//  next layer waiting below.
//

import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Scene pieces

struct RabbitHoleItem: Identifiable {
    enum Kind {
        case carrot
        case dynamite
    }

    enum Flight {
        case none
        case tossCorrect
        case tossWrong
        case blast
    }

    let id: UUID
    var kind: Kind
    var text: String
    var index: Int
    var isFinalDynamite: Bool
    var isPresent: Bool
    var rest: CGPoint
    var position: CGPoint
    var scale: CGFloat
    var spin: Double
    var opacity: Double
    var flight: Flight
    var flightAge: Double
    var flightDuration: Double
    var flightFrom: CGPoint
    var flightTo: CGPoint
    var blastVelocity: CGSize

    var isDynamite: Bool { kind == .dynamite }
}

struct RabbitHoleParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGSize
    var age: Double
    var life: Double
    var radius: CGFloat
    var spin: Double
    var kind: Kind

    enum Kind {
        case dust
        case spark
        case clod
        case confetti
        case fire
        case smoke
        case shard
    }
}

enum RabbitHoleHookMode: Equatable {
    case swinging
    case dropping
    case wriggling
    case raisingCarry
    case raisingEmpty
    case tossingCorrect
    case tossingWrong
    case exploding
    case falling
    case celebrating
    case entering
}

/// Shared 1552×1531 art canvas. Each character's body, poke stick and operator
/// arm were drawn on that canvas — see `ExcavatorKit`. The trolley interpolates
/// the left / centre / right toppart poses in polar space around the yellow
/// hub, then those pose images are thrown away.
enum RabbitHoleCraneLayout {
    static let canvasSize = CGSize(width: 1552, height: 1531)
    /// Designed height of the machine in the canvas (crop of the tracks).
    static let canvasBodyHeight: CGFloat = 1140
    static let canvasHub = CGPoint(x: 1190.5, y: 860.4)
    static let canvasTracksY: CGFloat = 1447
    /// Optical centre of the two crawler tracks on the shared artwork canvas.
    static let canvasTracksCenterX: CGFloat = 500
    /// Same graphic as the centre toppart pose, cropped.
    static let topArt = CGSize(width: 130, height: 218)
    static let clawArt = CGSize(width: 403, height: 407)
    /// Opaque centroid of the cropped toppart, as a unit point.
    static let topCentroid = UnitPoint(x: 0.4923, y: 0.5550)
    static let clawBarX: CGFloat = 0.5347
    static let clawTopY: CGFloat = 0.0074
    static let clawGripY: CGFloat = 0.6980
    /// Bottom-centre of the striped block on the cropped toppart.
    static let topGlue = UnitPoint(x: 0.496, y: 0.959)
    static func trackSink(isPad: Bool) -> CGFloat { isPad ? 16 : 12 }

    static func mainHeight(isPad: Bool) -> CGFloat { isPad ? 214 : 163 }

    static func canvasScale(isPad: Bool) -> CGFloat {
        mainHeight(isPad: isPad) / canvasBodyHeight
    }

    static func topSize(isPad: Bool) -> CGSize {
        let s = canvasScale(isPad: isPad)
        return CGSize(width: topArt.width * s, height: topArt.height * s)
    }

    static func clawSize(isPad: Bool) -> CGSize {
        let s = canvasScale(isPad: isPad)
        return CGSize(width: clawArt.width * s, height: clawArt.height * s)
    }

    static func pinHeightAboveTracks(isPad: Bool) -> CGFloat {
        (canvasTracksY - canvasHub.y) * canvasScale(isPad: isPad)
    }

    static func clawTopToGrip(isPad: Bool) -> CGFloat {
        clawSize(isPad: isPad).height * (clawGripY - clawTopY)
    }

    static func restHang(isPad: Bool) -> Double {
        let pose = trolleyPose(boom: .zero, angle: 0, isPad: isPad)
        return Double(hypot(pose.glue.x, pose.glue.y) + clawTopToGrip(isPad: isPad))
    }

    struct TopKeyframe {
        var centroid: CGPoint
    }

    /// Measured from `toppart_left` / `_center` / `_right` on the shared canvas.
    static let topLeft = TopKeyframe(centroid: CGPoint(x: 1057.2, y: 975.8))
    static let topCenter = TopKeyframe(centroid: CGPoint(x: 1186.0, y: 1012.0))
    static let topRight = TopKeyframe(centroid: CGPoint(x: 1289.6, y: 949.3))

    /// World pose of the trolley. A quadratic through the three poses keeps the
    /// authored centre without pausing there; polar space keeps it on the hub.
    static func trolleyPose(boom: CGPoint, angle: Double, isPad: Bool) -> (centroid: CGPoint, rotation: Double, glue: CGPoint, hang: Double) {
        let amp = max(0.001, GameConfig.rabbitHoleSwingAmplitude)
        let t = max(-1, min(1, angle / amp))
        let left = polar(topLeft.centroid)
        let mid = polar(topCenter.centroid)
        let right = polar(topRight.centroid)
        let hang = quadLerp(left.angle, mid.angle, right.angle, t)
        let radius = quadLerp(left.radius, mid.radius, right.radius, t)
        let centroidCanvas = cartesian(radius: radius, angle: hang)
        let rotation = -(hang - mid.angle)
        let centroid = worldPoint(centroidCanvas, boom: boom, isPad: isPad)
        let size = topSize(isPad: isPad)
        let dx = (topGlue.x - topCentroid.x) * size.width
        let dy = (topGlue.y - topCentroid.y) * size.height
        let c = cos(rotation)
        let s = sin(rotation)
        let glue = CGPoint(x: centroid.x + dx * c - dy * s,
                           y: centroid.y + dx * s + dy * c)
        return (centroid, rotation, glue, hang)
    }

    static func worldPoint(_ canvas: CGPoint, boom: CGPoint, isPad: Bool) -> CGPoint {
        let s = canvasScale(isPad: isPad)
        return CGPoint(x: boom.x + (canvas.x - canvasHub.x) * s,
                       y: boom.y + (canvas.y - canvasHub.y) * s)
    }

    static func canvasFrameCenter(boom: CGPoint, isPad: Bool) -> CGPoint {
        let s = canvasScale(isPad: isPad)
        return CGPoint(x: boom.x - (canvasHub.x - canvasSize.width / 2) * s,
                       y: boom.y - (canvasHub.y - canvasSize.height / 2) * s)
    }

    static func displayedCanvasSize(isPad: Bool) -> CGSize {
        let s = canvasScale(isPad: isPad)
        return CGSize(width: canvasSize.width * s, height: canvasSize.height * s)
    }

    /// Quadratic through left (-1), centre (0), right (+1).
    private static func quadLerp(_ left: Double, _ center: Double, _ right: Double, _ t: Double) -> Double {
        let a = (left + right) / 2 - center
        let b = (right - left) / 2
        return center + b * t + a * t * t
    }

    private static func polar(_ point: CGPoint) -> (radius: Double, angle: Double) {
        let dx = Double(point.x - canvasHub.x)
        let dy = Double(point.y - canvasHub.y)
        return (hypot(dx, dy), atan2(dx, dy))
    }

    private static func cartesian(radius: Double, angle: Double) -> CGPoint {
        CGPoint(x: canvasHub.x + CGFloat(sin(angle) * radius),
                y: canvasHub.y + CGFloat(cos(angle) * radius))
    }
}

// MARK: - Arena

@MainActor
final class RabbitHoleArena: ObservableObject {

    private(set) var items: [RabbitHoleItem] = []
    private(set) var particles: [RabbitHoleParticle] = []

    private(set) var hookX: CGFloat = 0.5
    private(set) var drop: CGFloat = 0
    /// Operator poke: 0 at rest, 1 while the claw is down. Independent of the
    /// hook's wriggle, so the stick does one smooth push-and-return.
    private(set) var poke: CGFloat = 0
    private(set) var swingAngle: Double = 0
    private var dropAngle: Double = 0
    private(set) var mode: RabbitHoleHookMode = .swinging
    private(set) var actionProgress: Double = 0
    private(set) var swingClock: Double = 0
    @Published private(set) var clock: Double = 0
    private(set) var dynamiteTime: Double = GameConfig.rabbitHoleDynamiteSeconds
    private(set) var floorIndex = 0
    private(set) var floorCount = 4
    private(set) var fallShift: CGFloat = 0
    private(set) var excavatorDrop: CGFloat = 0
    private(set) var excavatorSquash: CGFloat = 1
    private(set) var excavatorEntrance: CGFloat = 0
    private(set) var excavatorTilt: Double = 0
    private(set) var celebrateHop: CGFloat = 0
    /// Finale-only transform. The normal entrance and underground camera keep
    /// using their established coordinates; these values carry the complete
    /// rig out of the shaft, onto the right bank, and off screen.
    private(set) var finaleTravelX: CGFloat = 0
    private(set) var finaleFlip: Double = 0
    /// Reveals the original surface only when the reverse shaft trip has
    /// genuinely reached daylight. Its remaining crater sits on the left,
    /// leaving a real strip of grass for the landing.
    private(set) var finaleSurfaceReveal: CGFloat = 0
    private(set) var holeOpen: CGFloat = 0
    /// How far the blown earth has fallen (0 = still under the rabbit, 1 = gone).
    private(set) var slabFall: CGFloat = 0
    /// The standing earth has dropped away; the new floor is not in yet.
    private(set) var floorDropped = false
    private(set) var flash: Double = 0
    /// Expanding fireball, 0...1, while the dynamite is going off.
    private(set) var blastPulse: CGFloat = 0
    private(set) var blastOrigin: CGPoint = .zero
    /// Screen shake in points during the blast.
    private(set) var shake: CGFloat = 0
    private(set) var isCelebrating = false
    /// Remains true after the motion finishes so the result card stays over
    /// the right-hand landing world instead of snapping back to the shaft.
    private(set) var finaleSceneActive = false
    /// 1 = surface daylight. It decreases per floor but keeps a non-zero
    /// minimum because the shaft remains open to the sky above.
    private(set) var skyAmount: CGFloat = 1
    /// 0 = pit lip still at the grass line. 1 = lip at the top of the shaft.
    /// The first fall eases this so the walls never jump ahead of the digger.
    private(set) var shaftReveal: CGFloat = 0
    /// Cumulative camera travel through the shaft. The playfield uses this to
    /// scroll wall details while the otherwise continuous walls stay fixed.
    private(set) var shaftScroll: CGFloat = 0
    /// Extra hook rotation while tugging a carrot free of its pocket.
    private(set) var hookWiggle: Double = 0

    var onCorrect: ((UUID) -> Bool)?
    var onWrong: ((String) -> Void)?
    var onDynamiteMistake: (() -> Void)?
    var onTimeout: (() -> Void)?
    var onShellArrived: (() -> Void)?
    var onDrop: (() -> Void)?
    var onExplode: (() -> Void)?
    var onTutorialEvent: ((CrabTutorialEvent) -> Void)?
    var onEntranceComplete: (() -> Void)?
    var onLevelCompletionStarted: (() -> Void)?
    var onLevelCompletionFinished: (() -> Void)?

    private(set) var pocketRests: [CGPoint] = []
    private(set) var dynamitePocketIndex = 3
    private var pocketLayout = RabbitHoleLayout(units: [], dynamiteIndex: 3)
    private var remainingQuestions: [MathQuestion] = []
    private var configuredMaximum = 0
    private var floorCarrotCounts: [Int] = []
    private var wrongCarrotCount = 0
    private var reportedWrongCarrotCount = 0
    private var currentRound: GameRound?
    private var size: CGSize = .zero
    private var field: CGRect = .zero
    private var surface: CGRect = .zero
    private var isPad = false
    private var isLive = false
    private var reduceMotion = false
    private var speedMultiplier: Double = 1
    private var scoreTarget: CGPoint?
    private var heldID: UUID?
    private var dropTargetID: UUID?
    private var dropGrabLength: Double = 0
    private var dropStartAngle: Double = 0
    private var dropEndAngle: Double = 0
    private var wriggleFrom: CGPoint = .zero
    private var grabbedCorrect = false
    private var pendingCompletion = false
    private var completionStartedNotified = false
    private var tutorialArmed = false
    private var spawnedNextFloor = false
    private var collapseSpawned = false
    private var fallTravel: CGFloat = 0
    private var fallStartShaftScroll: CGFloat = 0
    private var celebrationStartShaftScroll: CGFloat = 0
    private var celebrationStartFloorIndex = 0
    private var celebrationLanded = false
    private var celebrationFinished = false

    /// One source of truth for both the artwork on the floor and the terminal
    /// explosion. `floorIndex` is zero-based; `floorCount` is a count.
    private var isLastFloor: Bool {
        floorIndex >= max(0, floorCount - 1)
    }

#if canImport(UIKit)
    private final class DisplayLinkTarget: NSObject {
        weak var owner: RabbitHoleArena?
        init(owner: RabbitHoleArena) { self.owner = owner }
        @objc func advance(_ displayLink: CADisplayLink) {
            guard let owner else {
                displayLink.invalidate()
                return
            }
            owner.advance(displayLink)
        }
    }
    private lazy var displayLinkTarget = DisplayLinkTarget(owner: self)
    private var displayLink: CADisplayLink?
    private var lastFrameTargetTimestamp: CFTimeInterval?
#else
    private var timer: Timer?
#endif

    var boomPoint: CGPoint {
        // The boom's right-hand pin sits in the middle of the grass lip.
        CGPoint(x: surface.midX,
                y: surface.maxY - RabbitHoleCraneLayout.pinHeightAboveTracks(isPad: isPad)
                    + RabbitHoleCraneLayout.trackSink(isPad: isPad)
                    + excavatorDrop)
    }

    /// Rest hang is the trolley on the boom pin. Grab hang is the claw on a
    /// carrot leaf, so a tap extends along the aim it already has.
    private var ropeLengths: (rest: Double, grab: Double) {
        let pivot = boomPoint
        var farthest = 0.0
        let rests = items.isEmpty ? pocketLayout.points(in: field) : items.map(\.rest)
        for rest in rests {
            let leaf = leafTowardBoom(from: rest)
            let distance = hypot(Double(leaf.x - pivot.x), Double(leaf.y - pivot.y))
            farthest = max(farthest, distance)
        }
        let restLength = RabbitHoleCraneLayout.restHang(isPad: isPad)
        let grabLength = max(restLength + 24, farthest + 8)
        return (restLength, grabLength)
    }

    var hookPoint: CGPoint {
        let pivot = boomPoint
        let lengths = ropeLengths
        let grab = dropGrabLength > 0 ? dropGrabLength : lengths.grab
        let length = lengths.rest + (grab - lengths.rest) * Double(drop)
        let angle = (mode == .swinging || mode == .entering) ? swingAngle : dropAngle
        return CGPoint(x: pivot.x + CGFloat(sin(angle) * length),
                       y: pivot.y + CGFloat(cos(angle) * length))
    }

    var currentAnswer: String? { currentRound?.question.correctAnswer }

    /// How far above a carrot's rest the leafy tuft sits, so the hook aims
    /// at the greens instead of the body.
    private var leafLift: CGFloat { isPad ? 54 : 42 }

    /// Leafy top along the boom ray, so a tilted carrot is still grabbed by its head.
    private func leafTowardBoom(from rest: CGPoint, lift: CGFloat? = nil) -> CGPoint {
        let lift = lift ?? leafLift
        let pivot = boomPoint
        let dx = pivot.x - rest.x
        let dy = pivot.y - rest.y
        let len = hypot(dx, dy)
        guard len > 1 else {
            return CGPoint(x: rest.x, y: rest.y - lift)
        }
        return CGPoint(x: rest.x + dx / len * lift,
                       y: rest.y + dy / len * lift)
    }

    private func leafPoint(of item: RabbitHoleItem) -> CGPoint {
        let lift = item.isDynamite ? leafLift * 0.6 : leafLift
        return leafTowardBoom(from: item.rest, lift: lift)
    }

    /// Degrees of clockwise tilt that aims a carrot's leaves at the boom.
    private func facingDegrees(at rest: CGPoint) -> Double {
        let dx = Double(boomPoint.x - rest.x)
        let dy = Double(boomPoint.y - rest.y)
        return atan2(dx, -dy) * 180 / .pi
    }

    private var hookRayAngle: Double {
        (mode == .swinging || mode == .entering) ? swingAngle : dropAngle
    }

    private func hangingCenter(from hook: CGPoint) -> CGPoint {
        let angle = hookRayAngle
        let lift = Double(leafLift)
        return CGPoint(x: hook.x + CGFloat(sin(angle) * lift),
                       y: hook.y + CGFloat(cos(angle) * lift))
    }

    var currentAnswerAvailable: Bool {
        guard let answer = currentAnswer else { return false }
        let wanted = AnswerValue(answer)
        return items.contains {
            $0.isPresent && !$0.isDynamite && AnswerValue($0.text) == wanted
        }
    }

    // MARK: - Layout

    func layout(size: CGSize, field: CGRect, surface: CGRect, isPad: Bool) {
        self.size = size
        self.field = field
        self.surface = surface
        self.isPad = isPad
        repositionRests()
        if hookX == 0.5 || hookX == 0 {
            hookX = field.midX
        }
        objectWillChange.send()
    }

    func setRemainingQuestions(_ questions: [MathQuestion], maximum: Int, mistakes: Int) {
        remainingQuestions = questions
        reportedWrongCarrotCount = max(0, mistakes)
        wrongCarrotCount = max(wrongCarrotCount, mistakes)
        if configuredMaximum != maximum || floorCarrotCounts.isEmpty {
            configuredMaximum = maximum
            floorCarrotCounts = makeCarrotDistribution(maximum: maximum)
            floorCount = floorCarrotCounts.count
        }
        restockFloorIfNeeded()
    }

    func setRound(_ round: GameRound?) {
        currentRound = round
    }

    func setLive(_ live: Bool) { isLive = live }
    func setReduceMotion(_ reduce: Bool) { reduceMotion = reduce }
    func setSpeedMultiplier(_ multiplier: Double) {
        // Rabbit Hole keeps one swing pace. Callers may still pass a
        // multiplier; it is ignored so leftover streak wiring cannot speed
        // the crane up.
        _ = multiplier
        speedMultiplier = 1
    }
    func setScoreTarget(_ target: CGPoint?) { scoreTarget = target }
    func setTutorialActive(_ active: Bool) { tutorialArmed = active }

    func beginEntrance(completion: @escaping () -> Void) {
        onEntranceComplete = completion
        floorIndex = 0
        wrongCarrotCount = reportedWrongCarrotCount
        if configuredMaximum > 0 {
            floorCarrotCounts = makeCarrotDistribution(maximum: configuredMaximum)
            floorCount = floorCarrotCounts.count
        }
        skyAmount = 1
        shaftReveal = 0
        shaftScroll = 0
        dynamiteTime = GameConfig.rabbitHoleDynamiteSeconds
        particles.removeAll()
        holeOpen = 0
        slabFall = 0
        floorDropped = false
        fallShift = 0
        excavatorDrop = 0
        excavatorSquash = 1
        excavatorTilt = 0
        blastPulse = 0
        shake = 0
        collapseSpawned = false
        fallTravel = 0
        celebrateHop = 0
        finaleTravelX = 0
        finaleFlip = 0
        finaleSurfaceReveal = 0
        isCelebrating = false
        finaleSceneActive = false
        celebrationLanded = false
        celebrationFinished = false
        pendingCompletion = false
        completionStartedNotified = false
        spawnedNextFloor = false
        items.removeAll()
        mode = .entering
        actionProgress = 0
        excavatorEntrance = reduceMotion ? 1 : 0
        drop = 0
        poke = 0
        heldID = nil
        dropTargetID = nil
        dropGrabLength = 0
        hookWiggle = 0
        swingAngle = 0
        dropAngle = 0
        restockFloorIfNeeded()
        objectWillChange.send()
        completion()
    }

    func beginCelebration(reduceMotion: Bool, started: @escaping () -> Void, finished: @escaping () -> Void) {
        self.reduceMotion = reduceMotion
        onLevelCompletionStarted = started
        onLevelCompletionFinished = finished

        // Completing the last sum can arrive while its carrot is still being
        // tossed. Do not replace that state with `.celebrating`: doing so
        // prevents `beginExplosion` from ever running and leaves the final
        // dynamite visibly sitting at the bottom of the shaft. The celebration
        // request first forces the terminal blast; `stepExplode` starts the
        // flight only after the fireball has finished.
        guard !pendingCompletion, !celebrationFinished, mode != .celebrating else { return }
        isCelebrating = true
        pendingCompletion = true
        if !completionStartedNotified {
            completionStartedNotified = true
            started()
        }

        if mode != .exploding && mode != .falling {
            beginExplosion(isFinaleLaunch: true)
        }
        objectWillChange.send()
    }

    private func startCelebrationAfterExplosion() {
        guard pendingCompletion else { return }
        pendingCompletion = false
        finaleSceneActive = true
        celebrationStartShaftScroll = shaftScroll
        celebrationStartFloorIndex = floorIndex
        celebrationLanded = false
        celebrationFinished = false
        celebrateHop = 0
        finaleTravelX = 0
        finaleFlip = 0
        finaleSurfaceReveal = 0
        excavatorSquash = 1
        excavatorTilt = 0

        // Nothing from the destroyed bottom may travel with the rabbit. In
        // particular this removes the green pocket slab and the old bomb from
        // the finale scene; only the empty shaft and blast particles remain.
        items.removeAll()
        pocketRests.removeAll()
        pocketLayout = RabbitHoleLayout(units: [], dynamiteIndex: -1)
        dynamitePocketIndex = -1
        floorDropped = true
        slabFall = 1
        holeOpen = 1
        fallShift = 0
        mode = .celebrating
        actionProgress = 0
        objectWillChange.send()
    }

    func endCelebration() {
        pendingCompletion = false
        isCelebrating = false
        if !celebrationFinished { finaleSceneActive = false }
        if mode == .celebrating { mode = .swinging }
        objectWillChange.send()
    }

    // MARK: - Input

    func tap() {
        guard isLive, mode == .swinging, !isCelebrating else { return }
        dropStartAngle = swingAngle
        let lengths = ropeLengths
        if let id = itemAlongRay(angle: swingAngle, maxLength: lengths.grab) {
            dropTargetID = id
            if let item = items.first(where: { $0.id == id }) {
                let leaf = leafPoint(of: item)
                dropEndAngle = atan2(Double(leaf.x - boomPoint.x), Double(leaf.y - boomPoint.y))
                dropGrabLength = hypot(Double(leaf.x - boomPoint.x), Double(leaf.y - boomPoint.y))
            } else {
                dropEndAngle = swingAngle
                dropGrabLength = lengths.grab
            }
        } else {
            dropTargetID = nil
            dropEndAngle = swingAngle
            dropGrabLength = lengths.grab
        }
        dropAngle = dropStartAngle
        mode = .dropping
        actionProgress = 0
        onDrop?()
        objectWillChange.send()
    }

    // MARK: - Running

    func setRunning(_ running: Bool) {
        if running {
#if canImport(UIKit)
            guard displayLink == nil else { return }
            lastFrameTargetTimestamp = nil
            let link = CADisplayLink(target: displayLinkTarget,
                                     selector: #selector(DisplayLinkTarget.advance(_:)))
            let fps = Float(ArenaPerformanceBudget.preferredFramesPerSecond)
            link.preferredFrameRateRange = CAFrameRateRange(minimum: fps, maximum: fps, preferred: fps)
            link.add(to: .main, forMode: .common)
            displayLink = link
#else
            guard timer == nil else { return }
            let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick(dt: 1.0 / 60.0) }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer
#endif
        } else {
#if canImport(UIKit)
            displayLink?.invalidate()
            displayLink = nil
            lastFrameTargetTimestamp = nil
#else
            timer?.invalidate()
            timer = nil
#endif
        }
    }

    func stop() {
        setRunning(false)
    }

#if canImport(UIKit)
    private func advance(_ displayLink: CADisplayLink) {
        let target = displayLink.targetTimestamp
        let measured = lastFrameTargetTimestamp.map { target - $0 } ?? (target - displayLink.timestamp)
        lastFrameTargetTimestamp = target
        tick(dt: min(max(measured, 1.0 / 120.0), 1.0 / 30.0))
    }
#endif

    private func tick(dt: Double) {
        clock += dt
        moveParticles(dt)
        moveFlights(dt)
        flash = max(0, flash - dt * 2.4)
        if mode != .exploding {
            blastPulse = max(0, blastPulse - CGFloat(dt) * 2.8)
            shake = max(0, shake - CGFloat(dt) * 28)
        }

        switch mode {
        case .entering:
            stepEntrance(dt)
        case .swinging:
            stepSwing(dt)
            tickFuse(dt)
        case .dropping:
            stepDrop(dt)
            tickFuse(dt)
        case .wriggling:
            stepWriggle(dt)
            tickFuse(dt)
        case .raisingCarry:
            stepRaiseCarry(dt)
            tickFuse(dt)
        case .raisingEmpty:
            stepRaiseEmpty(dt)
            tickFuse(dt)
        case .tossingCorrect:
            stepTossCorrect(dt)
        case .tossingWrong:
            stepTossWrong(dt)
            tickFuse(dt)
        case .exploding:
            stepExplode(dt)
        case .falling:
            stepFall(dt)
        case .celebrating:
            stepCelebrate(dt)
        }

        objectWillChange.send()
    }

    // MARK: - Steps

    private func stepEntrance(_ dt: Double) {
        let duration = reduceMotion ? 0.12 : GameConfig.rabbitHoleEntranceDuration
        actionProgress = min(1, actionProgress + dt / duration)
        let u = actionProgress
        excavatorEntrance = 1 - pow(1 - u, 3)
        excavatorSquash = 1 + sin(u * .pi) * 0.06
        if actionProgress >= 1 {
            excavatorEntrance = 1
            excavatorSquash = 1
            mode = .swinging
        }
    }

    private func stepSwing(_ dt: Double) {
        if items.contains(where: { $0.isDynamite && $0.isPresent && $0.flight == .none }),
           !items.contains(where: { !$0.isDynamite && $0.isPresent && $0.flight == .none }) {
            beginExplosion()
            return
        }
        swingClock += dt * speedMultiplier
        let period = GameConfig.rabbitHoleSwingPeriod / speedMultiplier
        let phase = (swingClock / period) * .pi * 2
        swingAngle = GameConfig.rabbitHoleSwingAmplitude * sin(phase)
        drop = max(0, drop - dt * 4)
        poke = 0
        hookWiggle = 0
        excavatorSquash = 1
        excavatorDrop = 0
        excavatorTilt = 0
        hookX = hookPoint.x
        for index in items.indices where items[index].isPresent
            && items[index].flight == .none
            && !items[index].isDynamite
            && items[index].id != heldID {
            items[index].spin = facingDegrees(at: items[index].rest)
        }
    }

    private func stepDrop(_ dt: Double) {
        let previousHook = hookPoint
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleDropDuration)
        let u = actionProgress
        drop = CGFloat(1 - pow(1 - u, 2.2))
        poke = drop
        dropAngle = dropStartAngle + (dropEndAngle - dropStartAngle) * (1 - pow(1 - u, 1.6))
        // Once a carrot lane has been positively locked, incidental overlap
        // with nearby bomb artwork must never replace that valid grab.
        let lockedOntoCarrot = dropTargetID.flatMap { target in
            items.first(where: { $0.id == target })
        }.map { !$0.isDynamite } ?? false
        if !lockedOntoCarrot, dynamiteTouchesHook(from: previousHook, to: hookPoint) {
            beginExplosion()
            return
        }
        if actionProgress >= 1 {
            dropAngle = dropEndAngle
            resolveGrab()
        }
    }

    /// Test the moving claw against the solid body of the bomb throughout the
    /// drop. The old full-artwork rectangle included transparent space and the
    /// fuse, which made nearby correct lanes explode too readily.
    private func dynamiteTouchesHook(from start: CGPoint, to end: CGPoint) -> Bool {
        let claw = RabbitHoleCraneLayout.clawSize(isPad: isPad)
        let itemHeight = GameConfig.rabbitHoleDisplayedItemLength(isPad: isPad)
        let travel = hypot(end.x - start.x, end.y - start.y)
        let steps = max(1, Int(ceil(travel / 3)))

        for item in items where item.isDynamite && item.isPresent && item.flight == .none {
            let bombHeight = itemHeight * (item.isFinalDynamite ? 1.12 : 1)
            let bodyHalfWidth = bombHeight * (item.isFinalDynamite ? 0.25 : 0.215)
                + claw.width * 0.13
            let bodyHalfHeight = bombHeight * (item.isFinalDynamite ? 0.415 : 0.38)
                + claw.height * 0.07
            let bodyCenterOffset = bombHeight * (item.isFinalDynamite ? 0.074 : 0.088)
            let radians = CGFloat(item.spin * .pi / 180)
            let cosine = cos(radians)
            let sine = sin(radians)

            for step in 0...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let point = CGPoint(x: start.x + (end.x - start.x) * t,
                                    y: start.y + (end.y - start.y) * t)
                let dx = point.x - item.position.x
                let dy = point.y - item.position.y
                // Undo the artwork rotation, then compare against only the
                // red bundle/body. Small claw padding represents the tips.
                let localX = dx * cosine + dy * sine
                let localY = -dx * sine + dy * cosine
                if abs(localX) < bodyHalfWidth,
                   abs(localY - bodyCenterOffset) < bodyHalfHeight {
                    return true
                }
            }
        }
        return false
    }

    private func stepWriggle(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleWriggleDuration)
        let u = actionProgress
        let tug = sin(u * .pi * 5)
        drop = 1 - 0.07 * CGFloat(abs(tug))
        poke = 1
        hookWiggle = tug * 4
        if let id = heldID, let index = items.firstIndex(where: { $0.id == id }) {
            let unstick = min(1, u / 0.42)
            let eased = 1 - pow(1 - unstick, 2)
            let hang = hangingCenter(from: hookPoint)
            items[index].position = CGPoint(
                x: wriggleFrom.x + (hang.x - wriggleFrom.x) * eased,
                y: wriggleFrom.y + (hang.y - wriggleFrom.y) * eased
            )
            items[index].spin = facingDegrees(at: items[index].rest) + tug * 5 * (1 - 0.35 * unstick)
            items[index].scale = 1 + 0.02 * CGFloat(abs(tug))
        }
        if actionProgress >= 1 {
            hookWiggle = 0
            mode = .raisingCarry
            actionProgress = 0
        }
    }

    private func stepRaiseCarry(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleRaiseDuration)
        drop = CGFloat(pow(1 - actionProgress, 1.35))
        poke = drop
        hookWiggle = sin(clock * 16) * 1.2 * (1 - actionProgress)
        if let id = heldID, let index = items.firstIndex(where: { $0.id == id }) {
            items[index].position = hangingCenter(from: hookPoint)
            items[index].spin = facingDegrees(at: items[index].position) + sin(clock * 18) * 2.5 * (1 - actionProgress)
            items[index].scale = 1
        }
        if actionProgress >= 1 {
            hookWiggle = 0
            if grabbedCorrect {
                if let id = heldID { launchCorrect(id: id) }
            } else if let id = heldID {
                launchWrong(id: id)
            } else {
                resumeSwing()
            }
        }
    }

    private func stepRaiseEmpty(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleRaiseDuration)
        drop = CGFloat(1 - actionProgress)
        poke = drop
        if actionProgress >= 1 {
            resumeSwing()
        }
    }

    private func stepTossCorrect(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleCorrectTossDuration)
        // Raise already retracted the claw; do not drop it down the grab ray again.
        drop = 0
        poke = 0
        if actionProgress >= 1 {
            finishCorrectToss()
        }
    }

    private func stepTossWrong(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleWrongTossDuration)
        drop = 0
        poke = 0
        if actionProgress >= 1 {
            if let id = heldID, let index = items.firstIndex(where: { $0.id == id }) {
                items[index].isPresent = false
                items[index].opacity = 0
                items[index].flight = .none
            }
            heldID = nil
            continueOrClearFloor()
        }
    }

    private func stepExplode(_ dt: Double) {
        let duration = reduceMotion ? 0.16 : GameConfig.rabbitHoleExplosionDuration
        actionProgress = min(1, actionProgress + dt / duration)
        let u = actionProgress
        let mega = isLastFloor

        if u < (mega ? 0.30 : 0.24) {
            blastPulse = CGFloat(min(1, u / (mega ? 0.10 : 0.16)))
        } else {
            blastPulse = CGFloat(max(0, 1 - (u - (mega ? 0.30 : 0.24))
                                          / (mega ? 0.95 : 0.50)))
        }
        flash = max(flash, max(0, (mega ? 1.55 : 1.15) - u * (mega ? 1.65 : 1.6)))
        shake = reduceMotion ? 0 : CGFloat((1 - min(1, u / (mega ? 0.72 : 0.55)))
                                           * (mega ? 19 : 11))

        // The blast removes the floor, but the rabbit remains the camera's
        // fixed anchor. The apparent fall starts when the shaft moves past it.
        excavatorDrop = 0
        if u < 0.18 {
            slabFall = 0
        } else {
            let dropU = min(1, (u - 0.18) / 0.22)
            slabFall = CGFloat(dropU * dropU * (3 - 2 * dropU))
        }
        holeOpen = slabFall
        floorDropped = slabFall > 0.18
        if u < 0.38 {
            excavatorTilt = sin(u * 38) * 3.2 * (1 - u)
            excavatorSquash = 1 + CGFloat(sin(u * .pi * 7)) * 0.04 * CGFloat(1 - u)
        } else {
            excavatorTilt = sin((u - 0.38) * 14) * 3
            excavatorSquash = 1.08
        }

        if u >= 0.18, !collapseSpawned {
            collapseSpawned = true
            spawnSurfaceCollapse()
        }

        if isLastFloor {
            if pendingCompletion, actionProgress >= 0.58 {
                // Launch while the fireball is still large, so the machine's
                // first upward frame reads as a direct reaction to the blast.
                startCelebrationAfterExplosion()
                return
            }
            if actionProgress >= 1 {
                if pendingCompletion {
                    // The blast is the first beat of the finale. Start the
                    // upward flight on the following frame, never underneath
                    // an intact bomb or a cross-faded floor.
                    startCelebrationAfterExplosion()
                    return
                }
                onTimeout?()
                mode = .swinging
                // Leave the lower fireball and recoil alive for the first
                // frames of the launch. The normal display-link decay removes
                // both while the excavator is visibly travelling away from it.
                blastPulse = max(blastPulse, reduceMotion ? 0 : 0.26)
                shake = reduceMotion ? 0 : 5
                excavatorTilt = 0
                excavatorDrop = 0
                excavatorSquash = 1
            }
            return
        }

        // The next floor waits below and the moving shaft will bring it up to
        // the stationary rabbit.
        if u >= 0.40 || actionProgress >= 1 {
            mode = .falling
            actionProgress = 0
            fallTravel = landingDepth()
            fallStartShaftScroll = shaftScroll
            blastPulse = 0
            shake = max(shake, 2)
            slabFall = 1
            holeOpen = 1
            floorIndex += 1
            floorDropped = false
            spawnedNextFloor = true
            fallShift = fallTravel
            spawnFloor()
        }
    }

    /// The next floor waits one additional viewport below the bottom edge. The
    /// world then travels twice the visible distance past the stationary rabbit.
    private func landingDepth() -> CGFloat {
        max(0, size.height - surface.maxY) * 2
    }

    private func stepFall(_ dt: Double) {
        // A physical fall takes the square root of the distance. Express the
        // acceleration in machine-heights per second² so it feels consistent
        // across phone and iPad sizes, then reserve a short fixed impact beat.
        let travel = fallTravel > 0 ? fallTravel : landingDepth()
        let machineHeight = RabbitHoleCraneLayout.mainHeight(isPad: isPad)
        let gravity = max(1, Double(machineHeight) * 11)
        let physicalFall = sqrt(2 * Double(max(0, travel)) / gravity)
        let tunedFall = physicalFall * GameConfig.rabbitHoleFallDuration
        let fallDuration = min(1.08, max(0.78, tunedFall))
        let impactDuration = 0.18
        let duration = reduceMotion ? 0.28 : fallDuration + impactDuration
        actionProgress = min(1, actionProgress + dt / duration)
        let u = actionProgress
        slabFall = 1
        holeOpen = 1

        // The machine is the fixed camera anchor. The complete shaft and the
        // waiting floor move upward, creating the fall without ever changing
        // the rabbit's screen position. The surface rim uses the exact same
        // progress, so its final distance is already correct at impact.
        let landU = reduceMotion ? 0.78 : fallDuration / duration
        let cameraProgress: CGFloat
        if u < landU {
            let t = CGFloat(u / max(0.001, landU))
            // Constant acceleration from rest: the scenery gains speed until
            // it meets the tracks, without an ease-out before impact.
            cameraProgress = t * t
            excavatorSquash = 1 + 0.04 * t
            excavatorTilt = 2.5 * sin(Double(t) * .pi)
        } else {
            cameraProgress = 1
            let impact = (u - landU) / max(0.001, 1 - landU)
            let bounce = exp(-4.2 * impact) * cos(impact * .pi * 4)
            excavatorSquash = 1 - 0.14 * CGFloat(bounce)
            excavatorTilt = 0
        }
        fallShift = travel * (1 - cameraProgress)
        excavatorDrop = 0
        shaftScroll = fallStartShaftScroll + travel * cameraProgress
        updateShaftReveal(cameraProgress: cameraProgress)
        skyAmount = max(0.38, 1 - 0.16 * CGFloat(floorIndex - 1) - 0.16 * cameraProgress)
        if actionProgress >= 1 {
            fallShift = 0
            excavatorDrop = 0
            excavatorSquash = 1
            excavatorTilt = 0
            holeOpen = 1
            slabFall = 1
            drop = 0
            poke = 0
            shake = 0
            blastPulse = 0
            shaftScroll = fallStartShaftScroll + travel
            skyAmount = max(0.38, 1 - 0.16 * CGFloat(floorIndex))
            shaftReveal = 1
            dynamiteTime = GameConfig.rabbitHoleDynamiteSeconds
            mode = .swinging
        }
    }

    /// The original grass lip belongs to the moving world, so it reaches the
    /// top of the shaft on the same frame that the new floor reaches the rabbit.
    private func updateShaftReveal(cameraProgress: CGFloat) {
        if floorIndex > 1 {
            shaftReveal = 1
            return
        }
        shaftReveal = max(shaftReveal, cameraProgress)
    }

    private func stepCelebrate(_ dt: Double) {
        actionProgress = min(1, actionProgress + dt / GameConfig.rabbitHoleYayDuration)
        let u = actionProgress

        let ascentEnd = reduceMotion ? 0.46 : 0.56
        let jumpEnd = reduceMotion ? 0.68 : 0.79
        let landingEnd = reduceMotion ? 0.80 : 0.87
        let landingX = size.width * (isPad ? 0.31 : 0.43)
        let exitX = size.width + RabbitHoleCraneLayout.displayedCanvasSize(isPad: isPad).width
        let shaftFlightLift = min(surface.height * 0.74,
                                  RabbitHoleCraneLayout.mainHeight(isPad: isPad) * 1.28)
        // One continuous clockwise revolution starts at the explosion and is
        // completed at touchdown. This avoids the old upright ascent followed
        // by a disconnected, mechanical-looking spin above ground.
        let spinT = min(1, max(0, u / jumpEnd))
        let spinProgress = 1 - pow(1 - spinT, 1.45)
        let continuousFlip = reduceMotion ? sin(spinT * .pi) * 10 : 360 * spinProgress

        if u < ascentEnd {
            // This is the actual route back up, not a scene replacement. The
            // downward journey accumulated one `landingDepth` per floor in
            // `shaftScroll`; running that value back to zero sends every wall
            // root and stratum past the rabbit in the opposite direction.
            let t = smoothstep(u / ascentEnd)
            let remaining = celebrationStartShaftScroll * CGFloat(1 - t)
            let floorTravel = max(1, landingDepth())
            let remainingFloors = max(0, remaining / floorTravel)
            shaftScroll = remaining
            floorIndex = max(1, min(celebrationStartFloorIndex,
                                    Int(ceil(remainingFloors))))
            shaftReveal = remainingFloors < 1 ? remainingFloors : 1
            skyAmount = max(0.38, 1 - 0.16 * remainingFloors)
            // Grow only the grass caps during the final part of the climb.
            // The shaft itself remains the scene, so both rims are already
            // visible before the machine crosses the opening.
            finaleSurfaceReveal = CGFloat(smoothstep((t - 0.66) / 0.34))

            finaleTravelX = 0
            // The rabbit itself leaves the blast and climbs into the upper
            // part of the viewport. After that the camera follows it through
            // the long empty shaft; importantly, no floor is attached to this
            // transform, so the destroyed bottom remains behind below.
            let ascentRaw = min(1, max(0, u / ascentEnd))
            let screenRise = 1 - pow(1 - ascentRaw, 3.2)
            celebrateHop = shaftFlightLift * CGFloat(screenRise)
                + CGFloat(sin(t * .pi * 7)) * 3 * CGFloat(1 - t)
            finaleFlip = continuousFlip
            excavatorSquash = 1.06 - CGFloat(t) * 0.03
                + CGFloat(sin(t * .pi * 10)) * 0.012 * CGFloat(1 - t)
            excavatorTilt = 0
        } else if u < jumpEnd {
            // Continue the same revolution along a cubic arc from the top of
            // the empty shaft to the right-hand grass bank.
            let t = smoothstep((u - ascentEnd) / max(0.001, jumpEnd - ascentEnd))
            shaftScroll = 0
            shaftReveal = 0
            floorIndex = 1
            skyAmount = 1
            finaleSurfaceReveal = 1
            let arc = cubic(
                CGPoint(x: 0, y: shaftFlightLift),
                CGPoint(x: landingX * 0.14, y: shaftFlightLift * 1.34),
                CGPoint(x: landingX * 0.78, y: shaftFlightLift * 1.12),
                CGPoint(x: landingX, y: 0),
                t
            )
            finaleTravelX = arc.x
            celebrateHop = arc.y
            finaleFlip = continuousFlip
            excavatorSquash = 1
            excavatorTilt = 0
        } else if u < landingEnd {
            let t = (u - jumpEnd) / max(0.001, landingEnd - jumpEnd)
            let damp = exp(-4.4 * t)
            shaftScroll = 0
            shaftReveal = 0
            floorIndex = 1
            skyAmount = 1
            finaleSurfaceReveal = 1
            finaleTravelX = landingX
            celebrateHop = CGFloat(abs(sin(t * .pi * 2)) * 7 * damp)
            finaleFlip = reduceMotion ? 0 : 360
            excavatorSquash = 1 - CGFloat(sin(t * .pi) * 0.12 * damp)
            excavatorTilt = 0
            if !celebrationLanded, t >= 0.08 {
                celebrationLanded = true
                let tracks = RabbitHoleCraneLayout.worldPoint(
                    CGPoint(x: RabbitHoleCraneLayout.canvasTracksCenterX,
                            y: RabbitHoleCraneLayout.canvasTracksY),
                    boom: boomPoint,
                    isPad: isPad
                )
                spawnLandingDust(atX: tracks.x + landingX)
            }
        } else {
            let t = smoothstep((u - landingEnd) / max(0.001, 1 - landingEnd))
            shaftScroll = 0
            shaftReveal = 0
            floorIndex = 1
            skyAmount = 1
            finaleSurfaceReveal = 1
            finaleTravelX = landingX + (exitX - landingX) * CGFloat(t)
            celebrateHop = 0
            finaleFlip = reduceMotion ? 0 : 360
            excavatorSquash = 1 + CGFloat(sin(t * .pi * 8)) * 0.012 * CGFloat(1 - t)
            excavatorTilt = sin(t * .pi * 6) * 0.8 * (1 - t)
        }

        if actionProgress >= 1, !celebrationFinished {
            celebrationFinished = true
            isCelebrating = false
            onLevelCompletionFinished?()
        }
    }

    /// Cubic easing shared by the finale's camera reveal and travel. The
    /// display link supplies every intermediate value, so the flip never asks
    /// SwiftUI to interpolate across the 360° wrap itself.
    private func smoothstep(_ value: Double) -> Double {
        let t = min(1, max(0, value))
        return t * t * (3 - 2 * t)
    }

    private func tickFuse(_ dt: Double) {
        guard items.contains(where: { $0.isDynamite && $0.isPresent && $0.flight == .none }) else { return }
        guard mode != .exploding, mode != .falling, mode != .celebrating, mode != .entering else { return }
        dynamiteTime = max(0, dynamiteTime - dt)
        if dynamiteTime <= 0 {
            beginExplosion()
        }
    }

    // MARK: - Grab

    /// The item whose swing lane the hook is in. Lanes are evenly spaced, so
    /// the closest angle wins only when it is clearly closer than its neighbour
    /// — halfway between two carrots is a miss, not a steal.
    private func itemAlongRay(angle: Double, maxLength: Double) -> UUID? {
        let pivot = boomPoint
        let ux = CGFloat(sin(angle))
        let uy = CGFloat(cos(angle))
        var scored: [(id: UUID, isDynamite: Bool, dAngle: Double, along: CGFloat, perp: CGFloat)] = []
        for item in items where item.isPresent && item.flight == .none {
            let leaf = leafPoint(of: item)
            let dx = leaf.x - pivot.x
            let dy = leaf.y - pivot.y
            let itemAngle = atan2(Double(dx), Double(dy))
            let dAngle = abs(atan2(sin(itemAngle - angle), cos(itemAngle - angle)))
            let along = dx * ux + dy * uy
            guard along > 36, along < CGFloat(maxLength) + 28 else { continue }
            let perp = abs(dx * uy - dy * ux)
            scored.append((item.id, item.isDynamite, dAngle, along, perp))
        }
        guard !scored.isEmpty else { return nil }
        scored.sort { $0.dAngle < $1.dAngle }
        let best = scored[0]
        let neighbor = scored.count > 1 ? scored[1].dAngle : GameConfig.rabbitHoleLaneGap
        let catchAngle = best.isDynamite
            ? GameConfig.rabbitHoleDynamiteGrabAngle
            : GameConfig.rabbitHoleGrabAngle
        // `0.94` leaves only a slim neutral seam at an exact midpoint. The old
        // 0.52 multiplier reduced a carrot to roughly one third of its lane.
        guard best.dAngle < min(catchAngle, neighbor * 0.94) else { return nil }
        let maxPerp = GameConfig.rabbitHoleItemRadius(isPad: isPad)
            * (best.isDynamite ? 1.05 : 1.60)
        guard best.perp < maxPerp else { return nil }
        return best.id
    }

    private func resolveGrab() {
        let lengths = ropeLengths
        let targetID = dropTargetID ?? itemAlongRay(angle: dropAngle, maxLength: dropGrabLength > 0 ? dropGrabLength : lengths.grab)
        dropTargetID = nil
        guard let targetID, let offset = items.firstIndex(where: { $0.id == targetID && $0.isPresent && $0.flight == .none }) else {
            mode = .raisingEmpty
            actionProgress = 0
            return
        }

        let item = items[offset]
        if item.isDynamite {
            beginExplosion()
            return
        }

        heldID = item.id
        wriggleFrom = items[offset].position
        items[offset].isPresent = true
        spawnUnstickDust(at: items[offset].rest)
        let isCorrect = currentAnswer.map { AnswerValue(item.text) == AnswerValue($0) } ?? false
        if isCorrect {
            grabbedCorrect = true
            let optionID = currentRound?.correctOption?.id
            var counted = false
            if let optionID {
                counted = onCorrect?(optionID) ?? false
            }
            if !counted { grabbedCorrect = false }
            if tutorialArmed { onTutorialEvent?(.clearedWave) }
        } else {
            grabbedCorrect = false
            wrongCarrotCount += 1
            onWrong?(item.text)
            if tutorialArmed {
                onTutorialEvent?(.smashedWrongCrab)
                onTutorialEvent?(.clearedWave)
            }
        }
        mode = .wriggling
        actionProgress = 0
    }

    private func launchCorrect(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].flight = .tossCorrect
        items[index].flightAge = 0
        items[index].flightDuration = GameConfig.rabbitHoleCorrectTossDuration
        items[index].flightFrom = items[index].position
        items[index].flightTo = scoreTarget ?? CGPoint(x: size.width * 0.16, y: 64)
        mode = .tossingCorrect
        actionProgress = 0
    }

    private func launchWrong(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let from = items[index].position
        let away: CGFloat = from.x < size.width * 0.5 ? -120 : size.width + 120
        items[index].flight = .tossWrong
        items[index].flightAge = 0
        items[index].flightDuration = GameConfig.rabbitHoleWrongTossDuration
        items[index].flightFrom = from
        items[index].flightTo = CGPoint(x: away, y: from.y - 90)
        mode = .tossingWrong
        actionProgress = 0
    }

    private func finishCorrectToss() {
        if let id = heldID, let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isPresent = false
            items[index].opacity = 0
            items[index].flight = .none
            onShellArrived?()
        }
        heldID = nil
        continueOrClearFloor()
    }

    /// Once the last carrot has left the soil, the bomb takes over without an
    /// extra tap. A winning final floor may already be celebrating; the
    /// explosion guard deliberately leaves that mode alone.
    private func continueOrClearFloor() {
        let hasCarrots = items.contains {
            !$0.isDynamite && $0.isPresent && $0.flight == .none
        }
        if hasCarrots {
            resumeSwing()
        } else {
            beginExplosion()
        }
    }

    private func resumeSwing() {
        drop = 0
        poke = 0
        dropGrabLength = 0
        hookWiggle = 0
        heldID = nil
        let amp = GameConfig.rabbitHoleSwingAmplitude
        let ratio = max(-1, min(1, dropAngle / amp))
        let period = GameConfig.rabbitHoleSwingPeriod / max(0.001, speedMultiplier)
        // asin() only covers the rightward half of the sine. Keep the
        // direction the hook already had, so a grab never turns it around.
        let priorPhase = (swingClock / period) * .pi * 2
        let goingRight = cos(priorPhase) >= 0
        let phase = goingRight ? asin(ratio) : (.pi - asin(ratio))
        swingClock = (phase / (2 * .pi)) * period
        swingAngle = dropAngle
        mode = .swinging
    }

    private func beginExplosion(isFinaleLaunch: Bool = false) {
        guard mode != .exploding, mode != .falling, mode != .celebrating else { return }
        // A bomb detonated while carrots remain is a player mistake. The
        // automatic detonation after a cleared floor has no carrots and is
        // therefore just the normal transition to the next floor.
        if !isFinaleLaunch,
           items.contains(where: { !$0.isDynamite && $0.isPresent }) {
            wrongCarrotCount += 1
            onDynamiteMistake?()
        }
        mode = .exploding
        actionProgress = 0
        flash = isLastFloor ? 1.55 : 1
        holeOpen = 0
        slabFall = 0
        floorDropped = false
        blastPulse = isLastFloor ? 0.32 : 0.2
        shake = reduceMotion ? 0 : (isLastFloor ? 20 : 12)
        collapseSpawned = false
        heldID = nil
        drop = 0
        poke = 0
        blastOrigin = items.first(where: { $0.isDynamite })?.position
            ?? CGPoint(x: field.midX, y: field.midY)
        spawnBlast()
        onExplode?()
        for index in items.indices where items[index].isPresent {
            items[index].flight = .blast
            items[index].flightAge = 0
            items[index].flightFrom = items[index].position
            if items[index].isDynamite {
                items[index].flightDuration = reduceMotion ? 0.18 : 0.32
                items[index].blastVelocity = .zero
            } else {
                items[index].flightDuration = reduceMotion ? 0.28 : 0.70
                let angle = Double.random(in: -3.0...0.05)
                let speed = Double.random(in: 320...620)
                items[index].blastVelocity = CGSize(width: cos(angle) * speed,
                                                    height: sin(angle) * speed)
            }
            items[index].isPresent = true
        }
        onDrop?()
    }

    /// Lays a floor whenever the pockets are empty, and again during the
    /// entrance walk so Play Again — which already has its sums before the
    /// digger walks on — does not open on bare soil.
    private func restockFloorIfNeeded() {
        guard mode != .falling, mode != .exploding, mode != .celebrating else { return }
        guard !remainingQuestions.isEmpty else { return }
        guard items.isEmpty || mode == .entering else { return }
        spawnFloor()
        dynamiteTime = GameConfig.rabbitHoleDynamiteSeconds
        objectWillChange.send()
    }

    private func spawnFloor() {
        let lingering = items.filter {
            ($0.flight == .blast || $0.flight == .tossCorrect)
                && $0.flightAge < $0.flightDuration
        }
        let nominalCount = floorCarrotCounts.indices.contains(floorIndex)
            ? floorCarrotCounts[floorIndex]
            : GameConfig.rabbitHoleMinimumCarrotCount
        let unusedCorrections = isLastFloor
            ? max(0, GameConfig.rabbitHoleCorrectionCarrots
                    - min(wrongCarrotCount, GameConfig.rabbitHoleCorrectionCarrots))
            : 0
        let carrotCount = max(GameConfig.rabbitHoleMinimumCarrotCount,
                              nominalCount - unusedCorrections)
        let random = RandomSource()
        let packed = RabbitHolePlanner.makeFloor(
            remaining: remainingQuestions,
            carrotCount: carrotCount,
            isLast: isLastFloor,
            floorIndex: floorIndex,
            field: field,
            pivot: boomPoint,
            itemRadius: GameConfig.rabbitHoleItemRadius(isPad: isPad),
            carrotLength: GameConfig.rabbitHoleCarrotLength(isPad: isPad),
            random: random
        )
        pocketLayout = packed.layout
        pocketRests = packed.layout.points(in: field)
        dynamitePocketIndex = packed.layout.dynamiteIndex
        items = packed.slots.compactMap { slot in
            guard !slot.isEmpty else { return nil }
            let rest = packed.layout.point(index: slot.index, in: field)
            let text = slot.text ?? ""
            return RabbitHoleItem(
                id: slot.id,
                kind: slot.isDynamite ? .dynamite : .carrot,
                text: text,
                index: slot.index,
                isFinalDynamite: slot.isFinalDynamite,
                isPresent: true,
                rest: rest,
                position: rest,
                scale: 1,
                spin: slot.isDynamite
                    ? random.double(in: -13..<13)
                    : facingDegrees(at: rest),
                opacity: 1,
                flight: .none,
                flightAge: 0,
                flightDuration: 1,
                flightFrom: rest,
                flightTo: rest,
                blastVelocity: .zero
            )
        }
        items.append(contentsOf: lingering)
    }

    /// Randomly partitions `maximum + 2` over the campaign. Every floor stays
    /// within 4...7, and the final nominal floor has at least six so its
    /// flawless two-carrot reduction can never dip below four.
    private func makeCarrotDistribution(maximum: Int,
                                        random: RandomSource = RandomSource()) -> [Int] {
        let count = GameConfig.rabbitHoleFloorCount(maximum: maximum)
        guard count > 0 else { return [] }
        let total = maximum + GameConfig.rabbitHoleCorrectionCarrots

        for _ in 0..<80 {
            var result = [Int](repeating: GameConfig.rabbitHoleMinimumCarrotCount,
                               count: count)
            result[count - 1] = max(result[count - 1],
                                    GameConfig.rabbitHoleMinimumCarrotCount
                                        + GameConfig.rabbitHoleCorrectionCarrots)
            var left = total - result.reduce(0, +)
            while left > 0 {
                let candidates = random.shuffled(Array(result.indices)).filter {
                    result[$0] < GameConfig.rabbitHoleCarrotCount
                }
                guard let index = candidates.first else { break }
                result[index] += 1
                left -= 1
            }
            guard left == 0,
                  result.last ?? 0 >= GameConfig.rabbitHoleMinimumCarrotCount
                    + GameConfig.rabbitHoleCorrectionCarrots,
                  Set(result).count > 1 else { continue }
            return result
        }

        // The four supported scoreboards always fit the constraints. This
        // fallback keeps custom/debug boards playable as well.
        var fallback = [Int](repeating: GameConfig.rabbitHoleMinimumCarrotCount,
                             count: count)
        fallback[count - 1] = min(GameConfig.rabbitHoleCarrotCount,
                                  GameConfig.rabbitHoleMinimumCarrotCount
                                    + GameConfig.rabbitHoleCorrectionCarrots)
        var left = max(0, total - fallback.reduce(0, +))
        var cursor = 0
        while left > 0, fallback.contains(where: { $0 < GameConfig.rabbitHoleCarrotCount }) {
            let index = cursor % count
            if fallback[index] < GameConfig.rabbitHoleCarrotCount {
                fallback[index] += 1
                left -= 1
            }
            cursor += 1
        }
        return fallback
    }

    private func repositionRests() {
        pocketRests = pocketLayout.points(in: field)
        for index in items.indices {
            let rest = pocketLayout.point(index: items[index].index, in: field)
            items[index].rest = rest
            if items[index].flight == .none, items[index].isPresent, items[index].id != heldID {
                items[index].position = rest
                if !items[index].isDynamite {
                    items[index].spin = facingDegrees(at: rest)
                }
            }
        }
    }

    // MARK: - Flight / particles

    private func moveFlights(_ dt: Double) {
        for index in items.indices {
            guard items[index].flight != .none else { continue }
            items[index].flightAge += dt
            let u = min(1, items[index].flightAge / max(0.001, items[index].flightDuration))
            switch items[index].flight {
            case .none:
                break
            case .tossCorrect:
                let from = items[index].flightFrom
                let to = items[index].flightTo
                let lift = min(70, max(36, (from.y - to.y) * 0.22))
                let peak = CGPoint(x: from.x + (to.x - from.x) * 0.45,
                                   y: max(12, min(from.y, to.y) - lift))
                items[index].position = cubic(from, peak, CGPoint(x: to.x, y: peak.y + 18), to, u)
                items[index].spin = u * 200
                let endScale = (isPad ? 34 : 26) / GameConfig.rabbitHoleCarrotSize(isPad: isPad)
                items[index].scale = 1 + (endScale - 1) * CGFloat(u * u)
            case .tossWrong:
                let from = items[index].flightFrom
                let to = items[index].flightTo
                let peak = CGPoint(x: (from.x + to.x) / 2, y: from.y - 110)
                items[index].position = quad(from, peak, to, u)
                items[index].spin = u * 420
                items[index].scale = 1 - 0.35 * CGFloat(u)
                items[index].opacity = 1 - u
            case .blast:
                if items[index].isDynamite {
                    items[index].scale = max(0.2, 1 - CGFloat(u) * 1.1)
                    items[index].opacity = 1 - u
                    items[index].spin = 0
                } else {
                    let v = items[index].blastVelocity
                    items[index].position.x += v.width * dt
                    items[index].position.y += v.height * dt
                    items[index].blastVelocity.height += 520 * dt
                    items[index].spin += dt * 280
                    items[index].scale = max(0.15, 1 - CGFloat(u) * 0.7)
                    items[index].opacity = 1 - u
                }
                if u >= 1 {
                    items[index].isPresent = false
                    items[index].flight = .none
                    items[index].opacity = 0
                }
            }
        }
    }

    private func moveParticles(_ dt: Double) {
        for index in particles.indices.reversed() {
            particles[index].age += dt
            particles[index].position.x += particles[index].velocity.width * dt
            particles[index].position.y += particles[index].velocity.height * dt
            switch particles[index].kind {
            case .fire:
                particles[index].velocity.height += 90 * dt
                particles[index].velocity.width *= (1 - dt * 1.4)
                particles[index].radius = max(1, particles[index].radius - CGFloat(dt) * 6)
            case .smoke:
                particles[index].velocity.height -= 55 * dt
                particles[index].velocity.width *= (1 - dt * 0.8)
                particles[index].radius += CGFloat(dt) * 22
            case .spark:
                particles[index].velocity.height += 240 * dt
            case .shard:
                particles[index].velocity.height += 620 * dt
                particles[index].spin += dt * 220
            default:
                particles[index].velocity.height += 380 * dt
                particles[index].spin += dt * 90
            }
            if particles[index].age >= particles[index].life {
                particles.remove(at: index)
            }
        }
    }

    private func spawnUnstickDust(at origin: CGPoint) {
        for _ in 0..<7 {
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: origin,
                velocity: CGSize(width: CGFloat.random(in: -70...70),
                                 height: CGFloat.random(in: -90...(-10))),
                age: 0,
                life: Double.random(in: 0.22...0.4),
                radius: CGFloat.random(in: 3...7),
                spin: Double.random(in: 0...360),
                kind: .dust
            ))
        }
    }

    private func spawnBlast() {
        let origin = blastOrigin
        let tight = ArenaPerformanceBudget.isConstrained
        let mega = isLastFloor
        let margin = size.width * 0.06
        let burst = mega ? (tight ? 34 : 58) : (tight ? 22 : 38)
        for _ in 0..<burst {
            let x = CGFloat.random(in: margin...(size.width - margin))
            let y = origin.y + CGFloat.random(in: -50...50)
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: mega ? 220...680 : 140...460)
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: x, y: y),
                velocity: CGSize(width: cos(angle) * speed, height: sin(angle) * speed - 80),
                age: 0,
                life: Double.random(in: mega ? 0.55...1.05 : 0.40...0.85),
                radius: CGFloat.random(in: mega ? 7...18 : 5...14),
                spin: Double.random(in: 0...360),
                kind: Bool.random() ? .dust : .clod
            ))
        }
        let sparks = mega ? (tight ? 22 : 38) : (tight ? 14 : 24)
        for _ in 0..<sparks {
            let x = CGFloat.random(in: margin...(size.width - margin))
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: x, y: origin.y + CGFloat.random(in: -24...24)),
                velocity: CGSize(width: CGFloat.random(in: -280...280),
                                 height: CGFloat.random(in: mega ? -560...(-80) : -380...(-40))),
                age: 0,
                life: Double.random(in: 0.28...0.55),
                radius: CGFloat.random(in: 2...5),
                spin: 0,
                kind: .spark
            ))
        }
        let flames = mega ? (tight ? 22 : 36) : (tight ? 14 : 22)
        for _ in 0..<flames {
            let x = CGFloat.random(in: margin...(size.width - margin))
            let angle = Double.random(in: -2.6...(-0.5))
            let speed = Double.random(in: mega ? 150...380 : 90...260)
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: x, y: origin.y + CGFloat.random(in: -20...20)),
                velocity: CGSize(width: cos(angle) * speed * 0.45, height: sin(angle) * speed),
                age: 0,
                life: Double.random(in: 0.22...0.48),
                radius: CGFloat.random(in: 10...22),
                spin: Double.random(in: 0...360),
                kind: .fire
            ))
        }
        let puffs = mega ? (tight ? 14 : 24) : (tight ? 8 : 14)
        for _ in 0..<puffs {
            let x = CGFloat.random(in: margin...(size.width - margin))
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: x, y: origin.y),
                velocity: CGSize(width: CGFloat.random(in: -90...90),
                                 height: CGFloat.random(in: -140...(-10))),
                age: 0,
                life: Double.random(in: 0.55...1.05),
                radius: CGFloat.random(in: 12...22),
                spin: 0,
                kind: .smoke
            ))
        }
    }

    /// The standing slab shears away across the pit, leaving only the side walls.
    private func spawnSurfaceCollapse() {
        let y = surface.maxY
        let margin = size.width * 0.06
        let tight = ArenaPerformanceBudget.isConstrained
        let chunks = tight ? 16 : 28
        for _ in 0..<chunks {
            let big = Bool.random()
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: margin...(size.width - margin)),
                                  y: y + CGFloat.random(in: -10...18)),
                velocity: CGSize(width: CGFloat.random(in: -110...110),
                                 height: CGFloat.random(in: 40...280)),
                age: 0,
                life: Double.random(in: 0.55...1.15),
                radius: big ? CGFloat.random(in: 11...20) : CGFloat.random(in: 5...12),
                spin: Double.random(in: 0...360),
                kind: .shard
            ))
        }
        for _ in 0..<(tight ? 8 : 14) {
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: margin...(size.width - margin)),
                                  y: y + CGFloat.random(in: -6...10)),
                velocity: CGSize(width: CGFloat.random(in: -80...80),
                                 height: CGFloat.random(in: 30...180)),
                age: 0,
                life: Double.random(in: 0.45...0.85),
                radius: CGFloat.random(in: 7...14),
                spin: Double.random(in: 0...360),
                kind: .clod
            ))
        }
        for _ in 0..<(tight ? 10 : 16) {
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: margin...(size.width - margin)),
                                  y: y),
                velocity: CGSize(width: CGFloat.random(in: -50...50),
                                 height: CGFloat.random(in: 20...150)),
                age: 0,
                life: Double.random(in: 0.40...0.80),
                radius: CGFloat.random(in: 4...10),
                spin: Double.random(in: 0...360),
                kind: .dust
            ))
        }
    }

    private func spawnConfetti() {
        let count = ArenaPerformanceBudget.isConstrained ? 18 : 28
        for _ in 0..<count {
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: surface.midX + CGFloat.random(in: -80...80),
                                  y: surface.midY),
                velocity: CGSize(width: CGFloat.random(in: -90...90),
                                 height: CGFloat.random(in: -260...(-80))),
                age: 0,
                life: Double.random(in: 0.7...1.3),
                radius: CGFloat.random(in: 4...8),
                spin: Double.random(in: 0...360),
                kind: .confetti
            ))
        }
    }

    private func spawnLandingDust(atX x: CGFloat) {
        let count = ArenaPerformanceBudget.isConstrained ? 9 : 15
        let groundY = surface.maxY - 4
        for _ in 0..<count {
            particles.append(RabbitHoleParticle(
                id: UUID(),
                position: CGPoint(x: x + CGFloat.random(in: -54...54),
                                  y: groundY + CGFloat.random(in: -3...4)),
                velocity: CGSize(width: CGFloat.random(in: -105...105),
                                 height: CGFloat.random(in: -125...(-35))),
                age: 0,
                life: Double.random(in: 0.28...0.52),
                radius: CGFloat.random(in: 3...7),
                spin: Double.random(in: 0...360),
                kind: .dust
            ))
        }
    }

    private func cubic(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        let x = u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x
        let y = u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y
        return CGPoint(x: x, y: y)
    }

    private func quad(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * a.x + 2 * u * t * b.x + t * t * c.x,
            y: u * u * a.y + 2 * u * t * b.y + t * t * c.y
        )
    }
}
