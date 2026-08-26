//
//  RabbitHolePlayfield.swift
//  Rabbit Hole
//
//  The in-game board: a rabbit in a digger on the grass, a crane claw that
//  aims across the pit and extends to grab, and an underground floor of
//  carrots and dynamite. HUD, pause and result cards stay in GameView; this
//  file only draws the round.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RabbitHolePlayfield: View {
    let round: GameRound?
    var remainingQuestions: [MathQuestion] = []
    var mistakeCount = 0
    var resumeFloorState: RabbitHoleFloorState?
    var missedSum: MissedSum?
    let maximumRounds: Int
    let character: AnimalCharacter
    let isPad: Bool
    let isLive: Bool
    let isRunning: Bool
    let playsKingEntrance: Bool
    var hasBonusPower: Bool = false
    var isLifeCrabAvailable: Bool = false
    let isStreakBoostActive: Bool
    let playsLevelCompletion: Bool
    let reduceMotion: Bool
    var tutorialPlan = RabbitHoleTutorialPlan()
    var reservesTutorialMessage = false
    let topReserve: CGFloat
    let bottomReserve: CGFloat
    let scoreTarget: CGPoint?

    let onCorrect: (UUID) -> Bool
    var onWrong: (String) -> Void = { _ in }
    var onDynamiteMistake: () -> Void = {}
    var onFloorStateChanged: (RabbitHoleFloorState) -> Void = { _ in }
    var onFinalFloorCleared: () -> Void = {}
    var onTimeout: () -> Void = {}
    var onSmash: () -> Void = {}
    let onShellArrived: () -> Void
    var onBonusCrabCaught: () -> Void = {}
    var onLifeCrabArrived: () -> Bool = { false }
    let onKingEntranceComplete: () -> Void
    var onLevelCompletionStarted: () -> Void = {}
    let onLevelCompletionFinished: () -> Void
    var onTutorialEvent: (RabbitHoleTutorialEvent) -> Void = { _ in }
    var onGuardedArrival: ((UUID) -> Bool)? = nil
    var onSmashedGuard: (() -> Bool)? = nil
    var onBreach: (() -> Void)? = nil
    var onSweep: (() -> Void)? = nil

    @StateObject private var arena = RabbitHoleArena()
    @ObservedObject private var language = LanguageManager.shared

    private var palette: ReefPalette { ReefPalette.palette(for: character) }
    private var pickupStyle: FoodPickupStyle {
        FoodCatalog.food(for: character.id).pickupStyle
    }
    private var isRightToLeft: Bool {
        language.layoutDirection == .rightToLeft
    }

    private var surfaceTop: CGFloat {
        topReserve + (isPad ? 8 : 4)
            + (reservesTutorialMessage ? ArenaConfig.tutorialMessageReserve(isPad: isPad) : 0)
    }

    private func grassLine(in size: CGSize) -> CGFloat {
        let share = isPad ? 0.57 : GameConfig.rabbitHoleGrassShare
        let target = size.height * share
        let minGrass = surfaceTop + (isPad ? 220 : 100)
        let maxGrass = size.height - bottomReserve - (isPad ? 300 : 220)
        return min(max(target, minGrass), maxGrass)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let grassY = grassLine(in: size)
            let surface = CGRect(x: 0, y: surfaceTop, width: size.width,
                                 height: max(90, grassY - surfaceTop))
            let field = CGRect(x: 0, y: grassY,
                               width: size.width,
                               height: max(80, size.height - grassY - bottomReserve - 8))
            let floorTravel = max(1, (size.height - surface.maxY) * 2)
            let travelledFloors = min(7, max(0, arena.shaftScroll / floorTravel))
            // The first landing is still directly beneath the opening and
            // therefore retains almost all daylight. The underground palette
            // only begins deepening in earnest on the way to floor two.
            let undergroundDepth = min(1, max(0, (travelledFloors - 0.75) / 6.25))
            let shaftDim = pow(undergroundDepth, 0.82)
            let skyVisibility: CGFloat = arena.finaleSceneActive
                ? 1
                : (arena.floorIndex == 0
                    ? 1
                    : max(arena.finaleSurfaceReveal, 1 - arena.shaftReveal))
            // A clean patch of sky remains visible behind the surviving grass
            // rim on floor one. It contains no sun or clouds and fades away
            // continuously during the descent to floor two.
            let openingVisibility: CGFloat = arena.finaleSceneActive
                ? 0
                : (arena.floorIndex == 0
                    ? 0
                    : max(arena.finaleSurfaceReveal,
                          min(1, max(0, 2 - travelledFloors))))
            // First blast only: fence and sign leave with the shockwave.
            // The finale restores the meadow, so scatter resets there.
            let surfaceDressingScatter: CGFloat = {
                if arena.finaleSceneActive { return 0 }
                if arena.floorIndex != 0 { return 1 }
                switch arena.mode {
                case .exploding:
                    let t = min(1, CGFloat(arena.actionProgress) / 0.28)
                    return t * t * (3 - 2 * t)
                case .falling:
                    return 1
                default:
                    return arena.floorDropped ? 1 : 0
                }
            }()

            ZStack(alignment: .topLeading) {
                // The open centre of the shaft needs its own backing. Without
                // it, the full-screen sky shows through one floor underground.
                LinearGradient(
                    colors: [
                        Color(red: 0.43 - 0.24 * shaftDim,
                              green: 0.34 - 0.21 * shaftDim,
                              blue: 0.23 - 0.10 * shaftDim),
                        Color(red: 0.255 - 0.175 * shaftDim,
                              green: 0.19 - 0.13 * shaftDim,
                              blue: 0.13 - 0.065 * shaftDim)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if openingVisibility > 0.001 {
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.28, green: 0.77, blue: 1.00),
                                  location: 0),
                            .init(color: Color(red: 0.49, green: 0.87, blue: 1.00),
                                  location: 0.24),
                            .init(color: Color(red: 0.72, green: 0.93, blue: 0.98)
                                .opacity(0.92), location: 0.50),
                            .init(color: Color(red: 1.00, green: 0.93, blue: 0.68)
                                .opacity(0.34), location: 0.76),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: size.width,
                           height: max(120, grassY * 0.72),
                           alignment: .top)
                    .opacity(Double(openingVisibility))
                    .allowsHitTesting(false)
                }

                RabbitHoleSky(palette: palette,
                              clock: arena.clock,
                              amount: arena.skyAmount,
                              habitat: HabitatKind(characterID: character.id),
                              hudBottom: surfaceTop,
                              isPad: isPad)
                    .opacity(Double(skyVisibility))

                RabbitHoleSoil(palette: palette,
                               characterID: character.id,
                               isPad: isPad,
                               grassY: grassY,
                               field: field,
                               holeOpen: arena.holeOpen,
                               slabFall: arena.slabFall,
                               floorDropped: arena.floorDropped,
                               fallShift: arena.fallShift,
                               floorIndex: arena.floorIndex,
                               shaftReveal: arena.shaftReveal,
                               shaftScroll: arena.shaftScroll,
                               skyAmount: arena.skyAmount,
                               languageCode: language.effective.code,
                               isRightToLeft: isRightToLeft,
                               carrotPockets: arena.items
                                   .filter { !$0.isDynamite }
                                   .map(\.rest),
                               dynamitePocket: arena.items
                                   .first(where: \.isDynamite)?.rest,
                               finaleLayout: arena.finaleSceneActive,
                               finaleSurfaceProgress: arena.finaleSurfaceReveal,
                               finaleCameraShift: arena.finaleSceneActive
                                   ? min(size.width * 0.48,
                                         max(0, arena.finaleWorldShift))
                                   : 0,
                               dressingScatter: surfaceDressingScatter,
                               pickupStyle: pickupStyle)
                    .equatable()
                    .frame(width: size.width, height: size.height)

                if arena.floorIndex == 0 {
                    HabitatAmbientMotion(
                        kind: HabitatKind(characterID: character.id),
                        grassY: grassY,
                        reduceMotion: reduceMotion
                    )
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                }

                // Keep the seven animated dust glints out of the much larger
                // procedural soil canvas. The old implementation rebuilt all
                // strata, rocks, roots, grass and wall details around 12 times
                // per second solely to change these seven opacities.
                if arena.floorIndex > 0 {
                    RabbitHoleSunbeamSparkles(
                        grassY: grassY,
                        floorDropped: arena.floorDropped,
                        fallShift: arena.fallShift,
                        shaftReveal: arena.shaftReveal,
                        skyAmount: arena.skyAmount,
                        clock: arena.clock,
                        finaleLayout: arena.finaleSceneActive,
                        finaleCameraShift: arena.finaleSceneActive
                            ? min(size.width * 0.48, max(0, arena.finaleWorldShift))
                            : 0
                    )
                    .frame(width: size.width, height: size.height)
                    .allowsHitTesting(false)
                }

                let soilTop = grassY + arena.fallShift
                let leafPoke: CGFloat = isPad ? 34 : 26
                let buryInSoil = arena.fallShift > 4
                ForEach(arena.items) { item in
                    if (item.isPresent || item.flight != .none), item.flight == .blast {
                        floorItem(item)
                            .position(x: item.position.x, y: item.position.y)
                            .transaction { $0.animation = nil }
                    }
                }
                ZStack(alignment: .topLeading) {
                    ForEach(arena.items) { item in
                        if (item.isPresent || item.flight != .none),
                           item.flight != .blast,
                           item.flight != .tossCorrect,
                           item.flight != .tossWrong {
                            floorItem(item)
                                .position(x: item.position.x,
                                          y: item.position.y + arena.fallShift)
                                .transaction { $0.animation = nil }
                        }
                    }
                }
                .id("buried-floor")
                .frame(width: size.width, height: size.height)
                .mask(alignment: .topLeading) {
                    if buryInSoil {
                        Rectangle()
                            .fill(.white)
                            .frame(width: size.width,
                                   height: max(0, size.height - soilTop + leafPoke + 8))
                            .offset(y: soilTop - leafPoke)
                    } else {
                        Rectangle().fill(.white)
                    }
                }

                if arena.blastPulse > 0.01 {
                    RabbitHoleFireball(origin: arena.blastOrigin,
                                       pulse: arena.blastPulse,
                                       size: size)
                }

                RabbitHoleParticles(particles: arena.particles)
                    .allowsHitTesting(false)

                if tutorialPlan.showsAimGuide,
                   let guideEnd = arena.tutorialGuideEndPoint {
                    TutorialHookGuide(start: arena.hookPoint,
                                      end: guideEnd,
                                      isPad: isPad)
                        .allowsHitTesting(false)
                }

                CraneRig(character: character,
                         isPad: isPad,
                         surface: surface,
                         fieldSize: size,
                         floorIndex: arena.floorIndex,
                         groundContact: arena.mode == .exploding
                            ? 1
                            : (arena.floorDropped
                                ? 0
                                : max(0, 1 - arena.fallShift
                                    / (RabbitHoleCraneLayout.mainHeight(isPad: isPad) * 0.72))),
                         boom: arena.boomPoint,
                         hook: arena.hookPoint,
                         entrance: arena.excavatorEntrance,
                         reach: arena.poke,
                         squash: arena.excavatorSquash,
                         hop: arena.celebrateHop,
                         travelX: arena.finaleTravelX,
                         tilt: arena.excavatorTilt,
                         flip: arena.finaleFlip,
                         hookWiggle: arena.hookWiggle)

                ForEach(arena.items) { item in
                    if item.flight == .tossCorrect || item.flight == .tossWrong {
                        floorItem(item)
                            .position(x: item.position.x, y: item.position.y)
                            .transaction { $0.animation = nil }
                            .allowsHitTesting(false)
                    }
                }

                // Tie the ambient shade to the physical shaft distance. This
                // keeps darkening smoothly beyond floor four, where skyAmount
                // intentionally stops decreasing to retain a little visibility.
                let shadeProgress = min(1, max(0,
                    (travelledFloors - 0.90) / 6.10))
                let depthShade = 0.38 * pow(shadeProgress, 0.95)
                if depthShade > 0.001 {
                    Color(red: 0.05, green: 0.07, blue: 0.10)
                        .opacity(Double(depthShade))
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                if arena.flash > 0 {
                    ZStack {
                        Color.orange.opacity(0.42 * arena.flash)
                        Color.yellow.opacity(0.18 * arena.flash)
                        Color.white.opacity(0.28 * arena.flash)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
            .offset(x: arena.shake > 0.4 ? sin(arena.clock * 92) * arena.shake : 0,
                    y: arena.shake > 0.4 ? cos(arena.clock * 74) * arena.shake * 0.55 : 0)
            .frame(width: size.width, height: size.height)
            // Gameplay has its own spatial direction. Mirror the complete
            // world in RTL so every layered excavator part, its hook physics,
            // the entrance, terrain dressing and finale stay in lockstep.
            // Numeric/text layers counter-mirror themselves where they draw.
            .scaleEffect(x: isRightToLeft ? -1 : 1, y: 1)
            .contentShape(Rectangle())
#if canImport(UIKit)
            .overlay(HoleTapView { _ in arena.tap() })
#else
            .gesture(DragGesture(minimumDistance: 0).onChanged { _ in arena.tap() })
#endif
            .allowsHitTesting(!playsLevelCompletion)
            .environment(\.layoutDirection, .leftToRight)
            .onAppear {
                bindArena()
                arena.setCharacterID(character.id)
                arena.setPickupStyle(pickupStyle)
                arena.layout(size: size, field: field, surface: surface, isPad: isPad)
                arena.setRemainingQuestions(remainingQuestions,
                                            maximum: maximumRounds,
                                            mistakes: mistakeCount)
                arena.setResumeFloorState(resumeFloorState)
                arena.setRound(round)
                arena.setLive(isLive)
                arena.setReduceMotion(reduceMotion)
                arena.setSpeedMultiplier(1)
                arena.setScoreTarget(localScoreTarget(scoreTarget, in: proxy))
                arena.applyTutorial(tutorialPlan)
                arena.setRunning(isRunning)
                if playsKingEntrance {
                    arena.beginEntrance(completion: onKingEntranceComplete)
                }
                if playsLevelCompletion {
                    arena.beginCelebration(reduceMotion: reduceMotion,
                                           started: onLevelCompletionStarted,
                                           finished: onLevelCompletionFinished)
                }
            }
            .onChange(of: size) { newSize in
                let grass = grassLine(in: newSize)
                arena.layout(size: newSize,
                             field: CGRect(x: 0, y: grass, width: newSize.width,
                                           height: max(80, newSize.height - grass - bottomReserve - 8)),
                             surface: CGRect(x: 0, y: surfaceTop, width: newSize.width,
                                             height: max(90, grass - surfaceTop)),
                             isPad: isPad)
            }
            .onChange(of: scoreTarget) { target in
                arena.setScoreTarget(localScoreTarget(target, in: proxy))
            }
            .onChange(of: character.id) { _ in
                arena.setCharacterID(character.id)
                arena.setPickupStyle(pickupStyle)
            }
            .onChange(of: isRightToLeft) { _ in
                arena.setScoreTarget(localScoreTarget(scoreTarget, in: proxy))
            }
        }
        .onChange(of: HoleSession(remaining: remainingQuestions,
                                  round: round,
                                  mistakes: mistakeCount)) { session in
            arena.setRemainingQuestions(session.remaining,
                                        maximum: maximumRounds,
                                        mistakes: session.mistakes)
            arena.setRound(session.round)
        }
        .onChange(of: isLive) { live in arena.setLive(live) }
        .onChange(of: isRunning) { running in arena.setRunning(running) }
        .onChange(of: tutorialPlan) { plan in
            arena.applyTutorial(plan)
        }
        .onChange(of: playsKingEntrance) { shouldPlay in
            if shouldPlay { arena.beginEntrance(completion: onKingEntranceComplete) }
        }
        .onChange(of: playsLevelCompletion) { shouldPlay in
            if shouldPlay {
                arena.beginCelebration(reduceMotion: reduceMotion,
                                       started: onLevelCompletionStarted,
                                       finished: onLevelCompletionFinished)
            } else {
                arena.endCelebration()
            }
        }
        .onDisappear { arena.stop() }
        .accessibilityElement(children: .contain)
    }

    private func localScoreTarget(_ global: CGPoint?, in proxy: GeometryProxy) -> CGPoint? {
        guard let global else { return nil }
        let origin = proxy.frame(in: .global).origin
        let localX = global.x - origin.x
        return CGPoint(x: isRightToLeft ? proxy.size.width - localX : localX,
                       y: global.y - origin.y)
    }

    @ViewBuilder
    private func floorItem(_ item: RabbitHoleItem) -> some View {
        if item.isDynamite {
            ZStack {
                DynamiteStickView(item: item,
                                  seconds: item.flight == .blast ? 0 : arena.dynamiteTime,
                                  isPad: isPad,
                                  isRightToLeft: isRightToLeft,
                                  clock: arena.clock)
                if tutorialPlan.shieldsDynamite, item.flight == .none {
                    DynamiteShieldView(isPad: isPad, clock: arena.clock)
                }
            }
                .scaleEffect(item.scale)
                .opacity(item.opacity)
        } else {
            AnswerPickupView(text: item.text,
                             style: pickupStyle,
                             isPad: isPad,
                             isRightToLeft: isRightToLeft,
                             scale: item.scale,
                             spin: item.spin,
                             opacity: item.opacity)
        }
    }

    private func bindArena() {
        arena.onCorrect = { id in
            if let onGuardedArrival { return onGuardedArrival(id) }
            return onCorrect(id)
        }
        arena.onWrong = onWrong
        arena.onDynamiteMistake = onDynamiteMistake
        arena.onFloorStateChanged = onFloorStateChanged
        arena.onFinalFloorCleared = onFinalFloorCleared
        arena.onTimeout = onTimeout
        arena.onShellArrived = onShellArrived
        arena.onDrop = onSmash
        arena.onExplode = { AppAudio.shared.playFlamethrower() }
        arena.onTutorialEvent = onTutorialEvent
    }
}

private struct HoleSession: Equatable {
    var remaining: [MathQuestion]
    var round: GameRound?
    var mistakes: Int
}

// MARK: - Sky

private struct RabbitHoleSky: View {
    let palette: ReefPalette
    let clock: Double
    var amount: CGFloat = 1
    var habitat: HabitatKind = .bunny
    /// Bottom of the question banner. The sun sits just under it so a sliver
    /// can tuck behind the board without vanishing.
    var hudBottom: CGFloat = 110
    var isPad = false

    var body: some View {
        let dusk = min(1, max(0, 1 - amount))
        let sky = HabitatWorld.sky(for: habitat)
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: sky.top.0 - 0.13 * dusk,
                          green: sky.top.1 - 0.24 * dusk,
                          blue: sky.top.2 - 0.16 * dusk),
                    Color(red: sky.mid.0 - 0.16 * dusk,
                          green: sky.mid.1 - 0.28 * dusk,
                          blue: sky.mid.2 - 0.19 * dusk),
                    Color(red: sky.horizon.0 - 0.30 * dusk,
                          green: sky.horizon.1 - 0.34 * dusk,
                          blue: sky.horizon.2 - 0.20 * dusk)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            GeometryReader { proxy in
                let sunSide = max(sky.sunSize, min(proxy.size.width, proxy.size.height) * 0.078)
                ZStack {
                    Circle()
                        .fill(Color(red: sky.sun.0, green: sky.sun.1, blue: sky.sun.2)
                            .opacity(0.28 - 0.10 * dusk))
                        .frame(width: sunSide * 1.85, height: sunSide * 1.85)
                        .blur(radius: sunSide * 0.22)
                    Circle()
                        .fill(Color(red: sky.sun.0, green: sky.sun.1, blue: sky.sun.2)
                            .opacity(0.95 - 0.35 * dusk))
                        .frame(width: sunSide, height: sunSide)
                        .blur(radius: 0.4)
                }
                .frame(width: sunSide * 1.9, height: sunSide * 1.9)
                // surfaceTop sits a few points under the banner. Offset the
                // disc so most of it hangs in the sky, with a small bite
                // tucked behind the board.
                .position(x: proxy.size.width * sky.sunUnitX,
                          y: hudBottom + sunSide * 0.20)
            }
            .allowsHitTesting(false)
            // Equal spacing and speed keep exactly three distinct clouds in
            // one loop: none can catch up with or overlap another.
            cloud(phase: 0.12, y: 0.16, scale: 1.22, speed: 0.018, dusk: dusk)
            cloud(phase: 0.72, y: 0.245, scale: 0.96, speed: 0.018, dusk: dusk)
            cloud(phase: 1.32, y: 0.18, scale: 1.05, speed: 0.018, dusk: dusk)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func cloud(phase: Double, y: Double, scale: CGFloat,
                       speed: Double, dusk: CGFloat) -> some View {
        GeometryReader { proxy in
            let travel = 1.80
            let progress = (phase + clock * speed)
                .truncatingRemainder(dividingBy: travel) - 0.40
            let cloudScale = scale * (isPad ? 2 : 1)
            let cloudY = y + (isPad ? 0 : 0.05)
            // One creamy fill only. A cyan underside plus a white stroke read
            // as a second cloud sitting underneath the first.
            let cloudFill = LinearGradient(
                colors: [.white,
                         Color(red: 0.97, green: 0.97, blue: 0.96),
                         Color(red: 0.93, green: 0.93, blue: 0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            ZStack {
                RabbitPuffyCloudShape()
                    .fill(cloudFill)
                    .frame(width: 112 * cloudScale, height: 52 * cloudScale)
                Capsule()
                    .fill(.white.opacity(0.55))
                    .frame(width: 28 * cloudScale, height: 5 * cloudScale)
                    .offset(x: -12 * cloudScale, y: -11 * cloudScale)
                    .blur(radius: 0.8 * cloudScale)
            }
            .frame(width: 118 * cloudScale, height: 58 * cloudScale)
            .opacity(0.96 - 0.24 * dusk)
            .position(x: proxy.size.width * progress, y: proxy.size.height * cloudY)
        }
    }
}

/// One continuous outline avoids the accidental "two clouds stacked"
/// appearance caused by building every cloud from several loose circles.
private struct RabbitPuffyCloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.075, y: h * 0.76))
        path.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.48),
                      control1: CGPoint(x: w * 0.035, y: h * 0.66),
                      control2: CGPoint(x: w * 0.09, y: h * 0.46))
        path.addCurve(to: CGPoint(x: w * 0.40, y: h * 0.34),
                      control1: CGPoint(x: w * 0.24, y: h * 0.28),
                      control2: CGPoint(x: w * 0.34, y: h * 0.25))
        path.addCurve(to: CGPoint(x: w * 0.58, y: h * 0.18),
                      control1: CGPoint(x: w * 0.44, y: h * 0.08),
                      control2: CGPoint(x: w * 0.56, y: h * 0.05))
        path.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.41),
                      control1: CGPoint(x: w * 0.67, y: h * 0.12),
                      control2: CGPoint(x: w * 0.72, y: h * 0.25))
        // Keep the right-hand tangent going down and slightly left so the
        // lobe does not reverse and leave a V-shaped notch in the outline.
        path.addCurve(to: CGPoint(x: w * 0.90, y: h * 0.78),
                      control1: CGPoint(x: w * 0.78, y: h * 0.30),
                      control2: CGPoint(x: w * 0.99, y: h * 0.52))
        path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.86),
                      control1: CGPoint(x: w * 0.86, y: h * 0.86),
                      control2: CGPoint(x: w * 0.82, y: h * 0.86))
        path.addCurve(to: CGPoint(x: w * 0.20, y: h * 0.86),
                      control1: CGPoint(x: w * 0.64, y: h * 0.90),
                      control2: CGPoint(x: w * 0.34, y: h * 0.90))
        path.addCurve(to: CGPoint(x: w * 0.075, y: h * 0.76),
                      control1: CGPoint(x: w * 0.13, y: h * 0.86),
                      control2: CGPoint(x: w * 0.08, y: h * 0.82))
        path.closeSubpath()
        return path
    }
}

// MARK: - Soil

private struct RabbitHoleSoil: View, Equatable {
    let palette: ReefPalette
    var characterID: String = "bunny"
    let isPad: Bool
    let grassY: CGFloat
    let field: CGRect
    let holeOpen: CGFloat
    let slabFall: CGFloat
    let floorDropped: Bool
    let fallShift: CGFloat
    let floorIndex: Int
    let shaftReveal: CGFloat
    let shaftScroll: CGFloat
    let skyAmount: CGFloat
    let languageCode: String
    let isRightToLeft: Bool
    var carrotPockets: [CGPoint] = []
    var dynamitePocket: CGPoint?
    var finaleLayout = false
    var finaleSurfaceProgress: CGFloat = 0
    var finaleCameraShift: CGFloat = 0
    /// 0 = fence and sign still planted. 1 = blown fully off-screen.
    var dressingScatter: CGFloat = 0
    var pickupStyle: FoodPickupStyle = .carrot

    private var habitatKind: HabitatKind { HabitatKind(characterID: characterID) }
    private var habitatGround: HabitatGroundPalette { HabitatWorld.ground(for: habitatKind) }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.palette == rhs.palette
            && lhs.characterID == rhs.characterID
            && lhs.isPad == rhs.isPad
            && lhs.grassY == rhs.grassY
            && lhs.field == rhs.field
            && abs(lhs.holeOpen - rhs.holeOpen) < 0.01
            && abs(lhs.slabFall - rhs.slabFall) < 0.02
            && lhs.floorDropped == rhs.floorDropped
            && abs(lhs.fallShift - rhs.fallShift) < 0.2
            && lhs.floorIndex == rhs.floorIndex
            && abs(lhs.shaftReveal - rhs.shaftReveal) < 0.008
            && abs(lhs.shaftScroll - rhs.shaftScroll) < 0.4
            && abs(lhs.skyAmount - rhs.skyAmount) < 0.02
            && lhs.languageCode == rhs.languageCode
            && lhs.isRightToLeft == rhs.isRightToLeft
            && lhs.carrotPockets == rhs.carrotPockets
            && lhs.dynamitePocket == rhs.dynamitePocket
            && lhs.finaleLayout == rhs.finaleLayout
            && abs(lhs.finaleSurfaceProgress - rhs.finaleSurfaceProgress) < 0.008
            && abs(lhs.finaleCameraShift - rhs.finaleCameraShift) < 0.4
            && abs(lhs.dressingScatter - rhs.dressingScatter) < 0.012
            && lhs.pickupStyle == rhs.pickupStyle
    }

    var body: some View {
        Canvas { context, size in
            let inShaft = floorIndex > 0
            let collapsing = floorDropped
            let soilPalette = soilPalette(for: floorIndex)
            let depth = soilPalette.depth
            let top = soilPalette.top
            let mid = soilPalette.mid
            let bottom = soilPalette.bottom
            let edges = pitEdges(in: size)
            let colors = [top, mid, bottom]
            let reveal = min(1, max(0, shaftReveal))
            let wallTop = grassY * (1 - reveal)

            let wellEnd = floorDropped ? size.height + 4 : grassY + fallShift
            let soilY = grassY + fallShift

            // After the blast the middle is an OPEN HOLE. Never fill it with a
            // sand rectangle at grassY — that is the horizontal stripe.
            if inShaft {
                drawPitWalls(context: context, size: size, edges: edges,
                             top: top, mid: mid, bottom: bottom,
                             wallTop: wallTop, floorY: wellEnd)
                if collapsing {
                    drawCollapsingEarth(context: context, size: size, edges: edges,
                                        colors: colors)
                } else {
                    // One floor only, at the landing height (off-screen at first).
                    let soil = Path(CGRect(x: 0, y: soilY, width: size.width,
                                           height: max(0, size.height - soilY + 4)))
                    context.fill(soil, with: .linearGradient(
                        Gradient(colors: colors),
                        startPoint: CGPoint(x: 0, y: soilY),
                        endPoint: CGPoint(x: 0, y: size.height)
                    ))
                    drawRightWallDebris(context: context, size: size,
                                        edges: edges, wallTop: wallTop,
                                        floorY: soilY, mid: mid,
                                        bottom: bottom)
                }
            } else if collapsing {
                drawCollapsingEarth(context: context, size: size, edges: edges,
                                    colors: colors)
            } else {
                let soil = surfaceSoilPath(size: size)
                context.fill(soil, with: .linearGradient(
                    Gradient(colors: [habitatGround.sodSoil, top, mid, bottom]),
                    startPoint: CGPoint(x: 0, y: grassY - 10),
                    endPoint: CGPoint(x: 0, y: size.height)
                ))
            }

            let contentDrop = collapsing ? slabFall * (size.height - grassY + 90) : fallShift
            var layers = context
            layers.translateBy(x: 0, y: contentDrop)
            if collapsing {
                // The floor is shattered into particles, not retained as a
                // transparent collection of strata and pocket marks.
                layers.opacity = 0
            } else if inShaft {
                // Only decorate the landing floor, not the open shaft above it.
                layers.clip(to: Path(CGRect(x: 0, y: soilY,
                                            width: size.width,
                                            height: size.height - soilY + 8)))
            }

            drawBrokenStrata(context: layers, size: size, depth: depth,
                             bottom: bottom)
            drawFloorRocks(context: layers, size: size, depth: depth,
                           mid: mid, bottom: bottom)

            for (index, centre) in carrotPockets.enumerated() {
                let artScale = pocketArtScale
                drawCarrotCrater(context: layers, at: centre,
                                 scale: artScale, depth: depth)
                drawSoilCracks(context: layers, at: centre,
                               innerRadius: 31 * artScale,
                               outerRadius: 52 * artScale,
                               count: 6, seed: index + 3, depth: depth)
            }

            if let dynamitePocket {
                // Dynamite disturbs the soil but does not leave a carrot-shaped
                // cavity. Empty layout slots receive no mark at all.
                drawSoilCracks(context: layers, at: dynamitePocket,
                               innerRadius: 30 * pocketArtScale,
                               outerRadius: 62 * pocketArtScale,
                               count: 8, seed: floorIndex + 17, depth: depth)
            }

            if inShaft {
                drawSunbeam(context: context, size: size, edges: edges,
                            wallTop: wallTop, floorY: wellEnd)
                if finaleLayout, finaleSurfaceProgress > 0.001 {
                    // These are the actual tops of the moving shaft walls.
                    // No meadow, fence or second soil layer is introduced.
                    drawFinaleRims(context: context, size: size, edges: edges,
                                   rimY: wallTop,
                                   progress: finaleSurfaceProgress)
                }
                // The original surface rim is visible from the first basement
                // only. The second blast takes that last green silhouette out
                // of frame; deeper floors are dirt walls all the way up.
                if !finaleLayout, floorIndex == 1, !collapsing {
                    drawPitRims(context: context, size: size, edges: edges,
                                rimY: wallTop)
                }
                drawWallRoots(context: context, size: size, edges: edges,
                              wallTop: wallTop, floorY: wellEnd)
            } else if collapsing {
                drawCollapsingGrass(context: context, size: size, edges: edges)
                // Fence and sign keep drawing through the collapse so the
                // shockwave can throw them off-screen instead of popping them.
                if dressingScatter < 0.98 {
                    drawLeftSurfaceProp(context: context, size: size)
                    if !finaleLayout {
                        drawAnswerSign(context: context, size: size)
                    }
                }
            } else {
                // The finale returns to the exact same meadow/fence dressing
                // as the opening scene; only the surviving crater is shifted
                // left to leave a right-hand landing bank.
                drawSurfaceBackdrop(context: context, size: size)
                drawSurface(context: context, size: size, opacity: 1)
                if holeOpen > 0.01 {
                    drawCrater(context: context, size: size)
                }
                    if !finaleLayout {
                    // The instruction board belongs to the untouched opening
                    // scene. It was destroyed during the descent and must not
                    // reappear on the new right-hand landing extension.
                    drawAnswerSign(context: context, size: size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// Eight supported floors form one continuous descent: warm loose topsoil
    /// becomes cooler, denser umber below. The absolute floor number drives the
    /// colour, so a seven/eight-floor campaign really ends darker than a short
    /// four-floor campaign instead of every mode sharing the same final shade.
    private func soilPalette(for floor: Int) -> (depth: CGFloat,
                                                  top: Color,
                                                  mid: Color,
                                                  bottom: Color) {
        let step = min(7, max(0, floor))
        // Floor one is loose topsoil immediately beneath the opening. Give it
        // only a small colour shift; the stronger mineral darkening starts
        // after that first daylight landing.
        let depth = min(1, max(0, (CGFloat(step) - 0.65) / 6.35))
        let deepening = pow(depth, 0.88)
        let mineralCool = max(0, (depth - 0.42) / 0.58)

        return (
            depth: depth,
            top: Color(red: 0.58 - 0.30 * deepening,
                       green: 0.36 - 0.20 * deepening,
                       blue: 0.20 - 0.055 * deepening + 0.012 * mineralCool),
            mid: Color(red: 0.40 - 0.245 * deepening,
                       green: 0.22 - 0.125 * deepening,
                       blue: 0.13 - 0.035 * deepening + 0.010 * mineralCool),
            bottom: Color(red: 0.16 - 0.092 * deepening,
                          green: 0.08 - 0.041 * deepening,
                          blue: 0.10 - 0.032 * deepening + 0.008 * mineralCool)
        )
    }

    /// Stable per-floor noise keeps geological details still during play, but
    /// prevents a dark stone or soil break returning at the same screen spot
    /// after every descent.
    private func soilNoise(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed + floorIndex * 101) * 12.9898 + 4.1414) * 43_758.5453
        return CGFloat(value - value.rounded(.down))
    }

    private func drawBrokenStrata(context: GraphicsContext, size: CGSize,
                                  depth: CGFloat, bottom: Color) {
        let rowCount = max(9, Int(ceil((size.height - grassY) / 34)) + 2)
        for row in 0..<rowCount {
            let y = grassY + 14 + CGFloat(row) * 34
                + (soilNoise(40 + row * 17) - 0.5) * 11
            let segmentCount = 2 + Int(soilNoise(90 + row * 13) * 3)
            let zoneWidth = size.width / CGFloat(segmentCount)

            for segment in 0..<segmentCount {
                let seed = 180 + row * 31 + segment * 11
                let startX = CGFloat(segment) * zoneWidth
                    + zoneWidth * (0.06 + soilNoise(seed) * 0.20)
                let length = zoneWidth * (0.34 + soilNoise(seed + 1) * 0.42)
                let endX = min(size.width - 3, startX + length)
                guard endX - startX > 12 else { continue }

                let endY = y + (soilNoise(seed + 2) - 0.5) * 8
                var stratum = Path()
                stratum.move(to: CGPoint(x: startX, y: y))
                stratum.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(x: (startX + endX) / 2,
                                     y: min(y, endY) - 2 - soilNoise(seed + 3) * 5)
                )
                context.stroke(
                    stratum,
                    with: .color(bottom.opacity(0.15 + 0.12 * depth
                                                + 0.06 * soilNoise(seed + 4))),
                    style: StrokeStyle(lineWidth: 1.2 + soilNoise(seed + 5) * 3.1,
                                       lineCap: .round,
                                       lineJoin: .round)
                )
            }

            var grit = Path()
            let gritCount = 4 + Int(soilNoise(400 + row) * 5)
            for index in 0..<gritCount {
                let seed = 460 + row * 29 + index * 7
                let x = 5 + soilNoise(seed) * max(10, size.width - 10)
                let gy = y + (soilNoise(seed + 1) - 0.5) * 23
                let width = 1.8 + soilNoise(seed + 2) * 4.2
                grit.addEllipse(in: CGRect(x: x, y: gy,
                                           width: width,
                                           height: 1.4 + soilNoise(seed + 3) * 2.1))
            }
            context.fill(grit, with: .color(bottom.opacity(0.28 + 0.13 * depth)))
        }
    }

    private func drawFloorRocks(context: GraphicsContext, size: CGSize,
                                depth: CGFloat, mid: Color, bottom: Color) {
        // Scattered mid-tone stones replace the old fixed coordinate list.
        for index in 0..<7 {
            let seed = 700 + index * 23
            let centre = CGPoint(
                x: size.width * (0.06 + soilNoise(seed) * 0.88),
                y: field.minY + field.height * (0.10 + soilNoise(seed + 1) * 0.76)
            )
            let radius = 6 + soilNoise(seed + 2) * 9
            let rock = soilRockPath(centre: centre, radius: radius, seed: seed + 3)
            context.fill(rock, with: .color(Color(
                red: 0.27 - 0.11 * depth,
                green: 0.20 - 0.09 * depth,
                blue: 0.16 - 0.045 * depth
            ).opacity(0.68)))
            context.stroke(rock, with: .color(mid.opacity(0.20)),
                           style: StrokeStyle(lineWidth: 0.8, lineJoin: .round))
        }

        // Darker clustered rock becomes more common toward the lower half of
        // the floor. Each floor receives a different deterministic layout.
        let clusterCount = 4 + min(3, floorIndex / 2)
        for cluster in 0..<clusterCount {
            let seed = 1_000 + cluster * 41
            let centre = CGPoint(
                x: size.width * (0.07 + soilNoise(seed) * 0.86),
                y: field.minY + field.height * (0.58 + soilNoise(seed + 1) * 0.35)
            )
            let baseRadius = 7 + soilNoise(seed + 2) * 8
            for piece in 0..<3 {
                let pieceSeed = seed + 7 + piece * 9
                let direction: CGFloat = piece.isMultiple(of: 2) ? -1 : 1
                let pieceCentre = CGPoint(
                    x: centre.x + direction * CGFloat(piece) * baseRadius * 0.55,
                    y: centre.y + (soilNoise(pieceSeed) - 0.5) * baseRadius * 0.8
                )
                let radius = baseRadius * (piece == 0 ? 1 : 0.48 + soilNoise(pieceSeed + 1) * 0.22)
                let rock = soilRockPath(centre: pieceCentre, radius: radius,
                                        seed: pieceSeed + 2)
                let darkRock = Color(red: 0.09 - 0.025 * depth,
                                     green: 0.055 - 0.020 * depth,
                                     blue: 0.065 - 0.010 * depth)
                context.fill(rock, with: .color(darkRock.opacity(0.72 + 0.10 * depth)))
                context.stroke(rock, with: .color(bottom.opacity(0.56)),
                               style: StrokeStyle(lineWidth: 1.0,
                                                  lineJoin: .round))
            }
        }
    }

    private func soilRockPath(centre: CGPoint, radius: CGFloat, seed: Int) -> Path {
        let pointCount = 7
        var path = Path()
        for index in 0..<pointCount {
            let angle = Double(index) / Double(pointCount) * .pi * 2
                + Double(soilNoise(seed + index)) * 0.16
            let reach = radius * (0.72 + soilNoise(seed + 20 + index) * 0.36)
            let verticalReach = reach * (0.62 + soilNoise(seed + 40 + index) * 0.18)
            let point = CGPoint(x: centre.x + CGFloat(cos(angle)) * reach,
                                y: centre.y + CGFloat(sin(angle)) * verticalReach)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    /// A few loose pieces sit just beyond the broader right-hand wall foot.
    /// Their count, spacing and silhouettes are tied to the floor seed, so the
    /// dynamite never appears to break the exact same pieces loose twice.
    private func drawRightWallDebris(context: GraphicsContext, size: CGSize,
                                     edges: (left: CGFloat, right: CGFloat),
                                     wallTop: CGFloat, floorY: CGFloat,
                                     mid: Color, bottom: Color) {
        let origin = max(0, wallTop)
        guard floorY > origin + 8, floorY < size.height + 30 else { return }
        let anchor = wallInnerX(size: size, edges: edges,
                                y: floorY - 1, origin: origin,
                                lip: floorY, isLeft: false)
        let count = 2 + Int(soilNoise(1_610) * 3)

        for index in 0..<count {
            let seed = 1_630 + index * 17
            let distance = 6 + CGFloat(index) * 8 + soilNoise(seed) * 7
            let centre = CGPoint(x: anchor - distance,
                                 y: floorY + 2 + soilNoise(seed + 1) * 7)
            let radius = 2.8 + soilNoise(seed + 2) * 3.8
            let clod = soilRockPath(centre: centre, radius: radius,
                                    seed: seed + 3)
            context.fill(clod,
                         with: .color((index.isMultiple(of: 3) ? bottom : mid)
                            .opacity(0.58 + 0.12 * soilNoise(seed + 4))))
        }
    }

    /// The original soft pocket: deliberately flatter than a circle and made
    /// from the same dark soil tones as the floor, without a bright hard rim.
    private func drawCarrotCrater(context: GraphicsContext,
                                  at centre: CGPoint,
                                  scale: CGFloat,
                                  depth: CGFloat) {
        let width: CGFloat = 66 * scale
        let height: CGFloat = 44 * scale
        let rim = CGRect(x: centre.x - width / 2,
                         y: centre.y - height / 2,
                         width: width, height: height)
        let well = CGRect(x: centre.x - width * 0.38,
                          y: centre.y - height * 0.28,
                          width: width * 0.76,
                          height: height * 0.72)
        context.fill(Path(ellipseIn: rim),
                     with: .color(Color(red: 0.18, green: 0.10, blue: 0.06)
                         .opacity(0.22 + 0.10 * depth)))
        context.fill(Path(ellipseIn: well),
                     with: .color(Color.black.opacity(0.34 + 0.16 * depth)))
    }

    /// Match the authored phone/iPad item size without threading another layout
    /// flag through the Canvas. Capped so split-screen layouts stay restrained.
    private var pocketArtScale: CGFloat {
        max(0.94, min(1.28, field.width / 390))
    }

    /// Deterministic branched cracks: stable between Canvas frames, but uneven
    /// enough not to read as a decorative starburst.
    private func drawSoilCracks(context: GraphicsContext,
                                at centre: CGPoint,
                                innerRadius: CGFloat,
                                outerRadius: CGFloat,
                                count: Int,
                                seed: Int,
                                depth: CGFloat) {
        var cracks = Path()
        for index in 0..<count {
            let base = Double(index) / Double(max(1, count)) * .pi * 2
            let jitter = sin(Double((seed + 1) * (index + 3)) * 1.73) * 0.22
            let angle = base + jitter
            let middleAngle = angle + sin(Double(seed + index * 5)) * 0.10
            let start = crackPoint(centre: centre, radius: innerRadius, angle: angle)
            let middleRadius = innerRadius + (outerRadius - innerRadius) * 0.55
            let middle = crackPoint(centre: centre, radius: middleRadius, angle: middleAngle)
            let lengthMix = 0.78 + 0.22 * CGFloat(abs(sin(Double(seed * 7 + index * 11))))
            let end = crackPoint(centre: centre, radius: outerRadius * lengthMix,
                                 angle: angle + jitter * 0.35)
            cracks.move(to: start)
            cracks.addLine(to: middle)
            cracks.addLine(to: end)

            if index.isMultiple(of: 2) {
                let branch = crackPoint(centre: middle,
                                        radius: 7 + CGFloat((seed + index) % 4),
                                        angle: angle + (index.isMultiple(of: 4) ? 0.72 : -0.68))
                cracks.move(to: middle)
                cracks.addLine(to: branch)
            }
        }
        context.stroke(cracks,
                       with: .color(Color(red: 0.19, green: 0.105, blue: 0.055)
                           .opacity(0.48 + 0.14 * depth)),
                       style: StrokeStyle(lineWidth: 1.7,
                                          lineCap: .round,
                                          lineJoin: .round))
    }

    private func crackPoint(centre: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(x: centre.x + CGFloat(cos(angle)) * radius,
                y: centre.y + CGFloat(sin(angle)) * radius)
    }

    /// Always the leftover side walls. Width never animates; the middle is
    /// destroyed while these narrow wall sections remain fixed.
    private func sideInset(in size: CGSize) -> CGFloat {
        max(18, size.width * 0.06)
    }

    private func pitEdges(in size: CGSize, open: CGFloat? = nil) -> (left: CGFloat, right: CGFloat) {
        _ = open
        if finaleLayout {
            // Treat the finale as a camera pan across one wide world. Both
            // opening edges keep their distance and move left together; the
            // right bank therefore enters continuously instead of appearing
            // as a new rectangular scene.
            let inset = sideInset(in: size)
            let shift = min(size.width * 0.48, max(0, finaleCameraShift))
            return (inset - shift, size.width - inset - shift)
        }
        let inset = sideInset(in: size)
        return (inset, size.width - inset)
    }

    /// Leftover walls only. The blast pulverises the complete visible floor;
    /// it must never survive as one solid slab beneath the rabbit.
    private func drawCollapsingEarth(context: GraphicsContext, size: CGSize,
                                     edges: (left: CGFloat, right: CGFloat),
                                     colors: [Color]) {
        let floorH = size.height - grassY + 4
        let shade = GraphicsContext.Shading.linearGradient(
            Gradient(colors: colors),
            startPoint: CGPoint(x: 0, y: grassY),
            endPoint: CGPoint(x: 0, y: size.height)
        )
        let lip = grassY + floorH
        context.fill(pitWallPath(size: size, edges: edges, origin: grassY,
                                 lip: lip, isLeft: true), with: shade)
        context.fill(pitWallPath(size: size, edges: edges, origin: grassY,
                                 lip: lip, isLeft: false), with: shade)
    }

    private func drawCollapsingGrass(context: GraphicsContext, size: CGSize,
                                     edges: (left: CGFloat, right: CGFloat)) {
        drawGrassCap(context: context, size: size, x: 0, width: edges.left, y: grassY)
        drawGrassCap(context: context, size: size, x: edges.right, width: size.width - edges.right, y: grassY)
    }

    private func surfaceScale(in size: CGSize) -> CGFloat {
        HabitatDraw.scale(for: size, grassY: grassY)
    }

    /// Wavy top so the dirt rises into the turf instead of meeting it on a
    /// hard horizontal cut.
    private func surfaceSoilPath(size: CGSize) -> Path {
        let scale = surfaceScale(in: size)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height + 4))
        path.addLine(to: CGPoint(x: 0, y: grassY - 4 * scale))
        var x: CGFloat = 0
        while x < size.width - 0.5 {
            let next = min(size.width, x + 36 * scale)
            let mid = (x + next) / 2
            let dip = (5.5 + 3.2 * sin(Double(mid) * 0.11)
                       + 2.0 * sin(Double(mid) * 0.29 + 0.7)) * scale
            path.addQuadCurve(to: CGPoint(x: next, y: grassY - 3 * scale),
                              control: CGPoint(x: mid, y: grassY - 8 * scale - dip * 0.15))
            x = next
        }
        path.addLine(to: CGPoint(x: size.width, y: size.height + 4))
        path.closeSubpath()
        return path
    }

    /// Stable 0...1 hash for turf details. Independent of the floor seed so
    /// the opening meadow never shimmers while the shaft clock ticks.
    private func turfUnit(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + 78.233) * 43_758.5453
        return CGFloat(value - value.rounded(.down))
    }

    private func hidesInHole(_ x: CGFloat, edges: (left: CGFloat, right: CGFloat),
                             inset: CGFloat = 2) -> Bool {
        holeOpen > 0.18 && x > edges.left + inset && x < edges.right - inset
    }

    private func drawFilledGrassBlade(context: GraphicsContext, root: CGPoint,
                                      height: CGFloat, lean: CGFloat,
                                      halfWidth: CGFloat, color: Color) {
        var blade = Path()
        let tip = CGPoint(x: root.x + lean, y: root.y - height)
        blade.move(to: CGPoint(x: root.x - halfWidth, y: root.y + 0.8))
        blade.addQuadCurve(
            to: tip,
            control: CGPoint(x: root.x - halfWidth * 0.2 + lean * 0.28,
                             y: root.y - height * 0.46)
        )
        blade.addQuadCurve(
            to: CGPoint(x: root.x + halfWidth, y: root.y + 0.8),
            control: CGPoint(x: root.x + halfWidth * 0.38 + lean * 0.72,
                             y: root.y - height * 0.36)
        )
        blade.closeSubpath()
        context.fill(blade, with: .color(color))
        if height > 11 {
            var glint = Path()
            glint.move(to: CGPoint(x: root.x - halfWidth * 0.18, y: root.y - 1.2))
            glint.addQuadCurve(to: CGPoint(x: tip.x - lean * 0.12, y: tip.y + 2.4),
                               control: CGPoint(x: root.x + lean * 0.2,
                                                y: root.y - height * 0.55))
            context.stroke(glint,
                           with: .color(Color.white.opacity(0.16)),
                           style: StrokeStyle(lineWidth: max(0.45, halfWidth * 0.28),
                                              lineCap: .round))
        }
    }

    /// One lush turf strip: a soil-cut sod lip, overlapping zoden, and dense
    /// filled blades. Caps after the blast reuse this so leftover grass keeps
    /// the same drawing style as the opening plateau.
    private func drawTurfStrip(context: GraphicsContext, size: CGSize,
                               x startX: CGFloat, width: CGFloat, lipY: CGFloat,
                               opacity: CGFloat, cutHole: Bool) {
        guard width > 4 else { return }
        let scale = surfaceScale(in: size)
        let edges = pitEdges(in: size)
        let endX = startX + width
        let lushLight = habitatGround.lushLight
        let lushMid = habitatGround.lushMid
        let lushDeep = habitatGround.lushDeep
        let lushGlow = habitatGround.lushGlow
        let sodSoil = habitatGround.sodSoil
        let sodSoilDark = habitatGround.sodSoilDark
        let sodSoilLight = habitatGround.sodSoilLight
        let bladeStep: CGFloat = habitatGround.sparseBlades ? 1.55 : 1

        func hidden(_ x: CGFloat, inset: CGFloat = 2) -> Bool {
            cutHole && hidesInHole(x, edges: edges, inset: inset)
        }

        context.drawLayer { layer in
            layer.clip(to: Path(CGRect(x: startX - 2, y: lipY - 52 * scale,
                                       width: width + 4, height: 108 * scale)))
            layer.opacity = Double(opacity)

            func fillBand(_ path: Path, shading: GraphicsContext.Shading) {
                if cutHole, holeOpen > 0.01 {
                    var punched = path
                    punched.addPath(craterPath(size: size))
                    layer.fill(punched, with: shading, style: FillStyle(eoFill: true))
                } else {
                    layer.fill(path, with: shading)
                }
            }

            var soilLip = Path()
            soilLip.move(to: CGPoint(x: startX, y: lipY - 4 * scale))
            soilLip.addLine(to: CGPoint(x: endX, y: lipY - 4 * scale))
            let soilSteps = max(6, Int(width / (13 * scale)))
            for step in 0...soilSteps {
                let t = CGFloat(step) / CGFloat(soilSteps)
                let x = endX - t * width
                let drop = (20 + 6.5 * sin(Double(x) * 0.17)
                            + 3.4 * sin(Double(x) * 0.41 + 1.1)) * scale
                soilLip.addLine(to: CGPoint(x: x, y: lipY + drop))
            }
            soilLip.closeSubpath()
            fillBand(soilLip, shading: .linearGradient(
                Gradient(colors: [sodSoil, sodSoilDark, sodSoilDark.opacity(0.92)]),
                startPoint: CGPoint(x: 0, y: lipY - 4 * scale),
                endPoint: CGPoint(x: 0, y: lipY + 26 * scale)))

            var cutFace = Path()
            cutFace.move(to: CGPoint(x: startX, y: lipY - 1.2 * scale))
            cutFace.addLine(to: CGPoint(x: endX, y: lipY - 1.2 * scale))
            cutFace.addLine(to: CGPoint(x: endX, y: lipY + 5.5 * scale))
            cutFace.addLine(to: CGPoint(x: startX, y: lipY + 5.5 * scale))
            cutFace.closeSubpath()
            fillBand(cutFace, shading: .color(sodSoilLight.opacity(0.62)))

            var turf = Path()
            turf.move(to: CGPoint(x: startX, y: lipY + 9 * scale))
            turf.addLine(to: CGPoint(x: startX, y: lipY - 16 * scale))
            var waveX = startX
            while waveX < endX - 0.5 {
                let next = min(endX, waveX + 34 * scale)
                let mid = (waveX + next) / 2
                let rise = (19 + 4.5 * sin(Double(mid) * 0.11)
                            + 2.2 * sin(Double(mid) * 0.27)) * scale
                turf.addQuadCurve(to: CGPoint(x: next,
                                              y: lipY - (16 + 2.4 * sin(Double(next) * 0.08)) * scale),
                                  control: CGPoint(x: mid, y: lipY - rise))
                waveX = next
            }
            turf.addLine(to: CGPoint(x: endX, y: lipY + 9 * scale))
            turf.closeSubpath()
            fillBand(turf, shading: .linearGradient(
                Gradient(colors: [lushLight, lushMid, lushDeep]),
                startPoint: CGPoint(x: 0, y: lipY - 24 * scale),
                endPoint: CGPoint(x: 0, y: lipY + 6 * scale)))

            var ridge = Path()
            ridge.move(to: CGPoint(x: startX + 4 * scale, y: lipY - 17 * scale))
            waveX = startX + 4 * scale
            while waveX < endX - 4 * scale {
                let next = min(endX - 4 * scale, waveX + 40 * scale)
                let mid = (waveX + next) / 2
                ridge.addQuadCurve(to: CGPoint(x: next, y: lipY - 16.5 * scale),
                                   control: CGPoint(x: mid, y: lipY - 21 * scale))
                waveX = next
            }
            layer.stroke(ridge, with: .color(lushGlow.opacity(0.42)),
                         style: StrokeStyle(lineWidth: 1.6 * scale, lineCap: .round))

            let sodSpacing = 24 * scale
            var sodIndex = 0
            var sodX = startX + 6 * scale
            while sodX < endX + 8 * scale {
                if !hidden(sodX, inset: 7 * scale) {
                    let n = turfUnit(sodIndex * 17 + 4)
                    let m = turfUnit(sodIndex * 11 + 8)
                    let sodW = (31 + n * 11) * scale
                    let sodH = (14 + m * 5) * scale
                    let yJitter = (m - 0.5) * 2.4 * scale

                    let soil = CGRect(x: sodX - sodW * 0.5,
                                      y: lipY + 3.2 * scale + yJitter * 0.4,
                                      width: sodW,
                                      height: sodH * 0.78)
                    layer.fill(Path(ellipseIn: soil),
                               with: .color(sodSoilDark.opacity(0.94)))

                    let sod = CGRect(x: sodX - sodW * 0.5,
                                     y: lipY - sodH * 0.68 + yJitter * 0.2,
                                     width: sodW, height: sodH)
                    layer.fill(Path(ellipseIn: sod), with: .linearGradient(
                        Gradient(colors: [lushLight, lushMid]),
                        startPoint: CGPoint(x: sod.midX, y: sod.minY),
                        endPoint: CGPoint(x: sod.midX, y: sod.maxY)))

                    let shine = CGRect(x: sod.minX + sod.width * 0.16,
                                       y: sod.minY + sod.height * 0.14,
                                       width: sod.width * 0.44,
                                       height: sod.height * 0.22)
                    layer.fill(Path(ellipseIn: shine),
                               with: .color(lushGlow.opacity(0.38)))
                }
                sodX += sodSpacing
                sodIndex += 1
            }

            sodIndex = 0
            sodX = startX + 18 * scale
            while sodX < endX + 4 * scale {
                if !hidden(sodX, inset: 7 * scale) {
                    let n = turfUnit(sodIndex * 19 + 21)
                    let sodW = (24 + n * 8) * scale
                    let sodH = (10 + turfUnit(sodIndex * 7) * 4) * scale
                    let sod = CGRect(x: sodX - sodW * 0.5,
                                     y: lipY - 3 * scale,
                                     width: sodW, height: sodH)
                    layer.fill(Path(ellipseIn: sod),
                               with: .color(lushDeep.opacity(0.78)))
                }
                sodX += 27 * scale
                sodIndex += 1
            }

            for crumb in 0..<max(4, Int(width / 18)) {
                let x = startX + turfUnit(crumb * 13 + 5) * width
                if hidden(x, inset: 6) { continue }
                let y = lipY + (10 + turfUnit(crumb * 9) * 10) * scale
                layer.fill(Path(ellipseIn: CGRect(x: x - 1.6 * scale,
                                                  y: y - 1.1 * scale,
                                                  width: (2.4 + turfUnit(crumb) * 2.2) * scale,
                                                  height: (1.6 + turfUnit(crumb + 3) * 1.4) * scale)),
                           with: .color(sodSoilLight.opacity(0.7)))
            }

            func drawBladeRow(step: CGFloat, offset: CGFloat, minH: CGFloat,
                              span: CGFloat, halfWidth: CGFloat,
                              leanScale: CGFloat, colorPick: (Int) -> Color) {
                var bladeX = startX + offset
                var index = 0
                while bladeX < endX {
                    if !hidden(bladeX, inset: 3 * scale) {
                        let n = turfUnit(index * 23 + Int(offset * 10))
                        let height = (minH + n * span) * scale
                        let lean = ((n - 0.5) * leanScale
                                    + 0.8 * sin(Double(bladeX) * 0.13)) * scale
                        let rootY = lipY - (2.5 + n * 2.2) * scale
                        drawFilledGrassBlade(
                            context: layer,
                            root: CGPoint(x: bladeX, y: rootY),
                            height: height,
                            lean: lean,
                            halfWidth: halfWidth * scale,
                            color: colorPick(index).opacity(0.97)
                        )
                    }
                    bladeX += step * scale
                    index += 1
                }
            }

            drawBladeRow(step: 6.4 * bladeStep, offset: 2.0, minH: 13, span: 10,
                         halfWidth: 1.35, leanScale: 5.5) { index in
                index.isMultiple(of: 3) ? lushDeep : lushMid
            }
            drawBladeRow(step: 5.1 * bladeStep, offset: 4.4, minH: 10, span: 8,
                         halfWidth: 1.2, leanScale: 4.8) { index in
                switch index % 3 {
                case 0: return lushLight
                case 1: return lushDeep
                default: return lushMid
                }
            }
            drawBladeRow(step: 4.6 * bladeStep, offset: 1.2, minH: 6.5, span: 6,
                         halfWidth: 1.05, leanScale: 3.4) { index in
                index.isMultiple(of: 2) ? lushGlow : lushLight
            }

            var tuftX = startX + 11 * scale
            var tuftIndex = 0
            while tuftX < endX {
                if !hidden(tuftX, inset: 5 * scale) {
                    let fan = turfUnit(tuftIndex * 29 + 6)
                    for tooth in -2...2 {
                        let lean = CGFloat(tooth) * 3.4 * scale
                            + (fan - 0.5) * 2.2 * scale
                        let extra = CGFloat(abs(tooth)) * 2.5
                        let height = (9 + extra + fan * 6) * scale
                        drawFilledGrassBlade(
                            context: layer,
                            root: CGPoint(x: tuftX, y: lipY - 1.5 * scale),
                            height: height,
                            lean: lean,
                            halfWidth: 1.15 * scale,
                            color: (tooth == 0 ? lushLight : lushMid).opacity(0.98)
                        )
                    }
                }
                tuftX += 21 * scale
                tuftIndex += 1
            }

            var hangX = startX + 5 * scale
            var hangIndex = 0
            while hangX < endX {
                if !hidden(hangX, inset: 4 * scale) {
                    let n = turfUnit(hangIndex * 17 + 9)
                    let length = (7 + n * 9) * scale
                    let lean = ((n - 0.5) * 5.5 + 0.6 * sin(Double(hangX) * 0.19)) * scale
                    var hang = Path()
                    let root = CGPoint(x: hangX, y: lipY + 1.2 * scale)
                    let tip = CGPoint(x: hangX + lean, y: lipY + length)
                    hang.move(to: CGPoint(x: root.x - 1.05 * scale, y: root.y))
                    hang.addQuadCurve(to: tip,
                                      control: CGPoint(x: root.x - 0.3 * scale + lean * 0.35,
                                                       y: root.y + length * 0.45))
                    hang.addQuadCurve(to: CGPoint(x: root.x + 1.05 * scale, y: root.y),
                                      control: CGPoint(x: root.x + 0.4 * scale + lean * 0.55,
                                                       y: root.y + length * 0.38))
                    hang.closeSubpath()
                    layer.fill(hang, with: .color(
                        (hangIndex.isMultiple(of: 3) ? lushDeep : lushMid).opacity(0.90)))
                }
                hangX += 6.8 * scale * bladeStep
                hangIndex += 1
            }
        }
    }

    private func drawGrassCap(context: GraphicsContext, size: CGSize,
                              x: CGFloat, width: CGFloat, y: CGFloat) {
        drawTurfStrip(context: context, size: size, x: x, width: width,
                      lipY: y, opacity: 1, cutHole: false)
    }

    /// Side walls. Their inner profiles are built from several incommensurate
    /// curves, so ledges and chips do not repeat like a stamped pattern.
    /// `wallTop` is the grass lip: grassY on the first drop, 0 once the shaft is established.
    private func drawPitWalls(context: GraphicsContext, size: CGSize,
                              edges: (left: CGFloat, right: CGFloat),
                              top: Color, mid: Color, bottom: Color,
                              wallTop: CGFloat, floorY: CGFloat) {
        let origin = max(0, wallTop)
        let lip = max(origin + 8, floorY)
        let leftWall = pitWallPath(size: size, edges: edges, origin: origin,
                                   lip: lip, isLeft: true)
        let rightWall = pitWallPath(size: size, edges: edges, origin: origin,
                                    lip: lip, isLeft: false)
        let shade = GraphicsContext.Shading.linearGradient(
            // The last warm turn meets the new floor in its own top colour,
            // rather than ending in a dark strip beside lighter soil.
            Gradient(stops: [
                .init(color: top, location: 0),
                .init(color: mid, location: 0.48),
                .init(color: bottom, location: 0.82),
                .init(color: top, location: 1)
            ]),
            startPoint: CGPoint(x: 0, y: origin),
            endPoint: CGPoint(x: 0, y: lip)
        )
        context.fill(leftWall, with: shade)
        context.fill(rightWall, with: shade)

        drawWallSoilDetails(context: context, size: size, edges: edges,
                            origin: origin, lip: lip, top: top, bottom: bottom,
                            leftWall: leftWall, rightWall: rightWall)

        // A narrow, broken shadow gives the freshly cut face depth while the
        // fill itself keeps the exact same palette as the floor below.
        for isLeft in [true, false] {
            let edge = pitWallInnerEdge(size: size, edges: edges,
                                        origin: origin, lip: lip,
                                        isLeft: isLeft)
            context.stroke(edge, with: .color(bottom.opacity(0.34)),
                           style: StrokeStyle(lineWidth: 2.4,
                                              lineCap: .round,
                                              lineJoin: .round))
            context.stroke(edge, with: .color(top.opacity(0.20)),
                           style: StrokeStyle(lineWidth: 0.8,
                                              lineCap: .round,
                                              lineJoin: .round))
        }
    }

    private func pitWallPath(size: CGSize,
                             edges: (left: CGFloat, right: CGFloat),
                             origin: CGFloat, lip: CGFloat,
                             isLeft: Bool) -> Path {
        let bottomY = max(origin + 1, lip)
        let steps = max(4, Int(ceil((bottomY - origin) / 14)))
        var path = Path()
        let outsideX: CGFloat = isLeft ? 0 : size.width
        path.move(to: CGPoint(x: outsideX, y: origin))
        path.addLine(to: CGPoint(x: wallInnerX(size: size, edges: edges,
                                               y: origin, origin: origin,
                                               lip: bottomY, isLeft: isLeft),
                                  y: origin))
        for index in 1...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let y = origin + (bottomY - origin) * t
            path.addLine(to: CGPoint(x: wallInnerX(size: size, edges: edges,
                                                   y: y, origin: origin,
                                                   lip: bottomY, isLeft: isLeft),
                                      y: y))
        }
        path.addLine(to: CGPoint(x: outsideX, y: bottomY))
        path.closeSubpath()
        return path
    }

    private func pitWallInnerEdge(size: CGSize,
                                  edges: (left: CGFloat, right: CGFloat),
                                  origin: CGFloat, lip: CGFloat,
                                  isLeft: Bool) -> Path {
        let bottomY = max(origin + 1, lip)
        let steps = max(4, Int(ceil((bottomY - origin) / 14)))
        var path = Path()
        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let y = origin + (bottomY - origin) * t
            let point = CGPoint(x: wallInnerX(size: size, edges: edges,
                                              y: y, origin: origin,
                                              lip: bottomY, isLeft: isLeft),
                                y: y)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    private func wallInnerX(size: CGSize,
                            edges: (left: CGFloat, right: CGFloat),
                            y: CGFloat, origin: CGFloat, lip: CGFloat,
                            isLeft: Bool) -> CGFloat {
        let worldY = Double(y + shaftScroll + CGFloat(floorIndex) * 43)
        let phase = isLeft ? 0.72 : 2.18
        let broad = sin(worldY * 0.047 + phase) * 0.50
        let ledges = sin(worldY * 0.113 + phase * 1.7) * 0.31
        let chips = sin(worldY * 0.251 + phase * 0.6) * 0.19
        let height = max(1, lip - origin)
        let t = min(1, max(0, (y - origin) / height))
        let endRestraint = 0.42 + 0.58 * sin(Double(t) * .pi)
        let amplitude = min(6.5, max(3.2, size.width * 0.013))
        let offset = CGFloat((broad + ledges + chips) * endRestraint) * amplitude
        // The cut wall thickens into a quiet natural toe near the floor. A
        // smoothstep curve changes the last section from vertical to sloped,
        // so it meets the horizontal soil without a separate pasted-on mound.
        let toeStart = (isLeft ? 0.80 : 0.76)
            + (soilNoise(isLeft ? 1_425 : 1_485) - 0.5) * 0.035
        let toeProgress = min(1, max(0, (t - toeStart) / (1 - toeStart)))
        let smoothToe = toeProgress * toeProgress * (3 - 2 * toeProgress)
        let baseToeDepth = min(24, max(14, size.width * 0.045))
        let rightReach: CGFloat = isLeft
            ? 0
            : 8 + soilNoise(1_495) * 8
        let toeDepth = baseToeDepth + rightReach
            + (soilNoise(isLeft ? 1_430 : 1_490) - 0.5) * 5
        let toe = smoothToe * toeDepth
        let base = isLeft ? edges.left : edges.right
        return isLeft ? base + offset + toe : base - offset - toe
    }

    private func drawWallSoilDetails(context: GraphicsContext, size: CGSize,
                                     edges: (left: CGFloat, right: CGFloat),
                                     origin: CGFloat, lip: CGFloat,
                                     top: Color, bottom: Color,
                                     leftWall: Path, rightWall: Path) {
        guard lip - origin > 24 else { return }

        for isLeft in [true, false] {
            var details = context
            details.clip(to: isLeft ? leftWall : rightWall)

            // Short broken strata and denser crumbs toward the bottom make the
            // root zone feel packed rather than like a flat colour strip.
            for index in 0..<15 {
                let baseT = (CGFloat(index) + 0.55) / 15
                let t = pow(baseT, 0.82)
                let yJitter = CGFloat(sin(Double(index * 17 + (isLeft ? 3 : 11)))) * 5
                let y = origin + (lip - origin) * t + yJitter
                guard y > origin + 5, y < lip - 3 else { continue }
                let inner = wallInnerX(size: size, edges: edges, y: y,
                                       origin: origin, lip: lip,
                                       isLeft: isLeft)
                let wallWidth = isLeft ? max(8, inner) : max(8, size.width - inner)
                let length = wallWidth * (0.34 + CGFloat((index * 7) % 5) * 0.08)
                let inset = 3 + CGFloat((index * 5) % 4)
                let startX = isLeft ? max(2, inner - length) : inner + inset
                let endX = isLeft ? inner - inset : min(size.width - 2, inner + length)
                var layer = Path()
                layer.move(to: CGPoint(x: startX, y: y))
                layer.addQuadCurve(to: CGPoint(x: endX, y: y + CGFloat((index % 3) - 1) * 2),
                                   control: CGPoint(x: (startX + endX) / 2,
                                                    y: y - 2 - CGFloat(index % 2)))
                details.stroke(layer, with: .color(bottom.opacity(0.23)),
                               style: StrokeStyle(lineWidth: index.isMultiple(of: 4) ? 2.2 : 1.15,
                                                  lineCap: .round))

                let fleckX = isLeft
                    ? max(3, inner - wallWidth * (0.22 + CGFloat((index * 3) % 5) * 0.11))
                    : min(size.width - 3,
                          inner + wallWidth * (0.22 + CGFloat((index * 3) % 5) * 0.11))
                let radius = 1.1 + CGFloat(index % 4) * 0.55
                let fleck = CGRect(x: fleckX - radius, y: y + 5 - radius * 0.5,
                                   width: radius * 2, height: radius * 1.25)
                details.fill(Path(ellipseIn: fleck),
                             with: .color((index.isMultiple(of: 3) ? top : bottom)
                                .opacity(0.34)))
            }
        }
    }

    private func drawSunbeam(context: GraphicsContext, size: CGSize,
                             edges: (left: CGFloat, right: CGFloat),
                             wallTop: CGFloat, floorY: CGFloat) {
        let origin = max(0, wallTop)
        let shaftH = max(8, min(floorY, grassY + 8) - origin)
        // Floor one keeps the established beam. Deeper down its reach fades,
        // but never to zero because the shaft is still open to daylight.
        let strength = max(0.38, min(1, skyAmount / 0.84))
        let shaft = Path(CGRect(x: edges.left, y: origin,
                                width: edges.right - edges.left,
                                height: shaftH))
        context.fill(shaft, with: .linearGradient(
            Gradient(stops: [
                .init(color: Color(red: 1.0, green: 0.97, blue: 0.76).opacity(0.28 * Double(strength)), location: 0),
                .init(color: Color(red: 1.0, green: 0.93, blue: 0.60).opacity(0.11 * Double(strength)), location: 0.42),
                .init(color: Color.clear, location: 1)
            ]),
            startPoint: CGPoint(x: size.width / 2, y: origin),
            endPoint: CGPoint(x: size.width / 2, y: origin + shaftH)
        ))

    }

    private func drawWallRoots(context: GraphicsContext, size: CGSize,
                               edges: (left: CGFloat, right: CGFloat),
                               wallTop: CGFloat, floorY: CGFloat) {
        let origin = max(0, wallTop)
        let lip = max(origin + 8, min(floorY, size.height))
        let span = max(40, lip - origin - 16)
        let spacing = max(58, span / 6)
        // During the first descent `wallTop` already carries the roots upward
        // with the surviving surface rim. Applying the complete shaft scroll
        // here as well made them overtake that rim and disappear into its sod.
        // Start cycling the procedural wall details only after the first
        // landing; subsequent descents have a fixed wall top and therefore do
        // need the normal camera scroll.
        let firstLandingTravel = max(1, (size.height - grassY) * 2)
        let wallDetailScroll = max(0, shaftScroll - firstLandingTravel)
        let phase = wallDetailScroll.truncatingRemainder(dividingBy: spacing)
        let count = max(3, Int(ceil((lip - origin + phase) / spacing)) + 2)
        var roots = context
        roots.clip(to: Path(CGRect(x: 0, y: origin,
                                   width: size.width, height: max(0, lip - origin))))
        for i in 0..<count {
            let jitter = CGFloat(sin(Double(i * 19 + floorIndex * 7))) * spacing * 0.19
            let y = origin + 10 - phase + CGFloat(i) * spacing + jitter
            guard y > origin - 28, y < lip + 12 else { continue }

            let leftLength = 17 + CGFloat((i * 13 + floorIndex * 5) % 27)
            let leftDrop = 18 + CGFloat((i * 17 + floorIndex * 3) % 24)
            let leftStartX = wallInnerX(size: size, edges: edges, y: y,
                                        origin: origin, lip: lip, isLeft: true)
            let leftEnd = CGPoint(x: leftStartX + leftLength, y: y + leftDrop)
            let leftControl = CGPoint(x: leftStartX + leftLength * 0.48,
                                      y: y + leftDrop * 0.18)
            var leftRoot = Path()
            leftRoot.move(to: CGPoint(x: leftStartX, y: y))
            leftRoot.addQuadCurve(to: leftEnd, control: leftControl)
            roots.stroke(leftRoot,
                         with: .color(Color(red: 0.34, green: 0.21, blue: 0.09)
                            .opacity(0.48)),
                         style: StrokeStyle(lineWidth: 1.5 + CGFloat(i % 3) * 0.42,
                                            lineCap: .round))
            drawRootBranch(context: roots,
                           start: quadraticPoint(from: CGPoint(x: leftStartX, y: y),
                                                 control: leftControl,
                                                 to: leftEnd, t: 0.58),
                           direction: i.isMultiple(of: 2) ? -1 : 1,
                           seed: i + floorIndex * 5,
                           color: Color(red: 0.34, green: 0.21, blue: 0.09))

            let rightY = y + 9 + CGFloat(sin(Double(i * 11 + 5))) * 11
            let rightLength = 15 + CGFloat((i * 17 + floorIndex * 11) % 25)
            let rightDrop = 20 + CGFloat((i * 11 + floorIndex * 7) % 28)
            let rightStartX = wallInnerX(size: size, edges: edges, y: rightY,
                                         origin: origin, lip: lip, isLeft: false)
            let rightEnd = CGPoint(x: rightStartX - rightLength, y: rightY + rightDrop)
            let rightControl = CGPoint(x: rightStartX - rightLength * 0.44,
                                       y: rightY + rightDrop * 0.24)
            var rightRoot = Path()
            rightRoot.move(to: CGPoint(x: rightStartX, y: rightY))
            rightRoot.addQuadCurve(to: rightEnd, control: rightControl)
            roots.stroke(rightRoot,
                         with: .color(Color(red: 0.34, green: 0.21, blue: 0.09)
                            .opacity(0.48)),
                         style: StrokeStyle(lineWidth: 1.35 + CGFloat((i + 1) % 3) * 0.46,
                                            lineCap: .round))
            drawRootBranch(context: roots,
                           start: quadraticPoint(from: CGPoint(x: rightStartX, y: rightY),
                                                 control: rightControl,
                                                 to: rightEnd, t: 0.62),
                           direction: i.isMultiple(of: 3) ? 1 : -1,
                           seed: i + floorIndex * 7 + 3,
                           color: Color(red: 0.34, green: 0.21, blue: 0.09))
        }
    }

    private func quadraticPoint(from start: CGPoint, control: CGPoint,
                                to end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        return CGPoint(
            x: oneMinusT * oneMinusT * start.x
                + 2 * oneMinusT * t * control.x + t * t * end.x,
            y: oneMinusT * oneMinusT * start.y
                + 2 * oneMinusT * t * control.y + t * t * end.y
        )
    }

    private func drawRootBranch(context: GraphicsContext, start: CGPoint,
                                direction: CGFloat, seed: Int, color: Color) {
        let reach = 7 + CGFloat((seed * 7) % 8)
        let drop = 5 + CGFloat((seed * 11) % 9)
        var branch = Path()
        branch.move(to: start)
        branch.addQuadCurve(to: CGPoint(x: start.x + direction * reach,
                                        y: start.y + drop),
                            control: CGPoint(x: start.x + direction * reach * 0.65,
                                             y: start.y + 1))
        context.stroke(branch, with: .color(color.opacity(0.36)),
                       style: StrokeStyle(lineWidth: 0.85,
                                          lineCap: .round))
    }

    /// Original grass, only on the wall tops — the surface the blast left behind.
    /// `rimY` is the dirt lip, matching `drawGrassCap`, so leftover turf keeps
    /// the same sods and blades as the opening plateau.
    private func drawPitRims(context: GraphicsContext, size: CGSize,
                             edges: (left: CGFloat, right: CGFloat),
                             rimY: CGFloat) {
        drawGrassCap(context: context, size: size, x: 0, width: edges.left, y: rimY)
        drawGrassCap(context: context, size: size, x: edges.right,
                     width: size.width - edges.right, y: rimY)
    }

    /// Grass is already attached to the two existing wall tops. It moves with
    /// those tops and never grows upward from the middle of either wall.
    private func drawFinaleRims(context: GraphicsContext, size: CGSize,
                                edges: (left: CGFloat, right: CGFloat),
                                rimY: CGFloat,
                                progress: CGFloat) {
        let p = min(1, max(0, progress))
        guard p > 0.001 else { return }
        drawGrassCap(context: context, size: size, x: 0,
                     width: max(0, edges.left), y: rimY)
        drawGrassCap(context: context, size: size, x: max(0, edges.right),
                     width: max(0, size.width - max(0, edges.right)),
                     y: rimY)
    }

    private func craterPath(size: CGSize) -> Path {
        let edges = pitEdges(in: size)
        let left = edges.left
        let right = edges.right
        let top = grassY - 20
        let bottom = grassY + 36 + (size.height - grassY) * 0.18 * holeOpen
        var path = Path()
        let steps = 12
        path.move(to: CGPoint(x: left, y: top + 8))
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let jag = CGFloat(sin(Double(t) * 9 + Double(holeOpen) * 3)) * 5
            path.addLine(to: CGPoint(x: left + (right - left) * t, y: top + jag))
        }
        path.addLine(to: CGPoint(x: right, y: bottom))
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let jag = CGFloat(sin(Double(t) * 7 + 1.4)) * 4
            path.addLine(to: CGPoint(x: right - (right - left) * t, y: bottom + jag))
        }
        path.closeSubpath()
        return path
    }

    private func drawCrater(context: GraphicsContext, size: CGSize) {
        let edges = pitEdges(in: size)
        let lip = grassY - 4

        let wall = Color(red: 0.36, green: 0.22, blue: 0.12)
        let dark = Color(red: 0.16, green: 0.08, blue: 0.05)
        context.fill(Path(CGRect(x: edges.left - 10, y: lip - 16, width: 14, height: 52)),
                     with: .color(wall.opacity(0.95)))
        context.fill(Path(CGRect(x: edges.right - 4, y: lip - 16, width: 14, height: 52)),
                     with: .color(wall.opacity(0.95)))
        context.fill(Path(CGRect(x: edges.left, y: lip - 6, width: 8, height: 40)),
                     with: .color(dark.opacity(0.7)))
        context.fill(Path(CGRect(x: edges.right - 8, y: lip - 6, width: 8, height: 40)),
                     with: .color(dark.opacity(0.7)))

        let shadow = Path(CGRect(x: edges.left, y: lip,
                                 width: edges.right - edges.left,
                                 height: 22 + 10 * holeOpen))
        context.fill(shadow, with: .linearGradient(
            Gradient(colors: [
                Color.black.opacity(0.42 * holeOpen),
                Color.black.opacity(0)
            ]),
            startPoint: CGPoint(x: size.width / 2, y: lip),
            endPoint: CGPoint(x: size.width / 2, y: lip + 32)
        ))

        let span = edges.right - edges.left
        let count = 10
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let x = edges.left + 12 + t * (span - 24)
            let clod = Path(ellipseIn: CGRect(x: x - 7, y: lip - 6 + CGFloat(i % 3) * 3,
                                              width: 13, height: 8))
            context.fill(clod, with: .color(Color(red: 0.40, green: 0.24, blue: 0.12).opacity(0.9)))
        }
    }

    private func drawSurface(context: GraphicsContext, size: CGSize, opacity: CGFloat) {
        // Grass sits on the dirt lip (grassY). Sods, blades and flowers stand
        // above it so the rabbit parks on a real turf patch rather than a stripe.
        drawTurfStrip(context: context, size: size, x: 0, width: size.width,
                      lipY: grassY, opacity: opacity, cutHole: true)

        let scale = surfaceScale(in: size)
        let edges = pitEdges(in: size)
        if habitatKind != .bunny {
            HabitatWorld.drawLipDetails(kind: habitatKind, context: context,
                                        size: size, grassY: grassY,
                                        holeLeft: edges.left, holeRight: edges.right,
                                        holeOpen: holeOpen)
            return
        }
        // stemHeight is how far the head sits above the turf.
        let daisies: [(CGFloat, CGFloat, Color, CGFloat, Double)] = [
            (0.05, 14, Color.white, 0.82, -8),
            (0.12, 22, Color(red: 1.00, green: 0.86, blue: 0.28), 0.90, 6),
            (0.19, 12, Color.white, 0.74, -5),
            (0.28, 18, Color.white, 0.88, 7),
            (0.48, 15, Color(red: 1.00, green: 0.82, blue: 0.22), 0.80, -6),
            (0.57, 20, Color.white, 0.92, 5),
            // Keep the board face clear: only short blooms at the posts.
            (0.62, 11, Color(red: 1.00, green: 0.55, blue: 0.68), 0.72, -9),
            (0.97, 13, Color.white, 0.78, 8)
        ]
        for daisy in daisies {
            let x = size.width * daisy.0
            if hidesInHole(x, edges: edges, inset: 8) { continue }
            let stem = daisy.1 * scale
            drawDaisy(context: context,
                      at: CGPoint(x: x, y: grassY - stem),
                      petal: daisy.2,
                      scale: daisy.3 * scale,
                      opacity: opacity,
                      tilt: daisy.4,
                      stemHeight: stem,
                      stemLean: daisy.4 * 0.18 * scale)
        }
    }

    /// Surface set dressing lives behind the excavator and is made entirely
    /// from Canvas paths. That keeps it crisp without adding image assets.
    private func drawSurfaceBackdrop(context: GraphicsContext, size: CGSize) {
        let scale = surfaceScale(in: size)
        if habitatKind != .bunny {
            HabitatWorld.drawBackdrop(kind: habitatKind, context: context,
                                      size: size, grassY: grassY)
            drawLeftSurfaceProp(context: context, size: size)
            return
        }
        drawMeadow(context: context, size: size, scale: scale)
        drawFence(context: context, size: size)

        // Hill flowers sit on the meadow bands, not the turf lip, so their
        // stems are short and plant into the slope beneath each head.
        let backgroundFlowers: [(CGFloat, CGFloat, CGFloat, Color, CGFloat, Double)] = [
            (0.08, 48, 14, Color.white, 0.92, -6),
            (0.18, 32, 11, Color(red: 1.0, green: 0.49, blue: 0.66), 0.82, 7),
            (0.59, 28, 12, Color.white, 0.84, 5),
            // Behind the board: the plank covers the heads, so only the
            // sides of the posts read as a small planted cluster.
            (0.66, 22, 11, Color(red: 1.0, green: 0.45, blue: 0.60), 0.78, -6),
            (0.76, 18, 10, Color.white, 0.72, 4),
            (0.98, 24, 13, Color(red: 0.98, green: 0.78, blue: 0.20), 0.88, -5)
        ]
        for flower in backgroundFlowers {
            let stem = flower.2 * scale
            let point = CGPoint(x: size.width * flower.0,
                                y: grassY - flower.1 * scale)
            drawDaisy(context: context, at: point, petal: flower.3,
                      scale: flower.4 * scale, opacity: 1, tilt: flower.5,
                      stemHeight: stem, stemLean: flower.5 * 0.16 * scale)
        }
    }

    private func drawLeftSurfaceProp(context: GraphicsContext, size: CGSize) {
        if habitatKind == .bunny {
            drawFence(context: context, size: size)
        } else {
            HabitatWorld.drawLeftProp(kind: habitatKind, context: context,
                                      size: size, grassY: grassY,
                                      scatter: dressingScatter)
        }
    }

    private func drawFence(context: GraphicsContext, size: CGSize) {
        let scale = surfaceScale(in: size)
        let fenceTop = grassY - 78 * scale
        let fenceBottom = grassY - 9
        let wood = Color(red: 0.67, green: 0.39, blue: 0.17)
        let woodLight = Color(red: 0.83, green: 0.57, blue: 0.28)
        let woodDark = Color(red: 0.42, green: 0.23, blue: 0.10)
        let fenceStart = -16 * scale
        let fenceWidth = min(size.width * 0.43, 158 * scale)
        let fencePivot = CGPoint(x: fenceStart + fenceWidth / 2,
                                 y: fenceTop + 39 * scale)
        guard let blownFence = blownDressing(context, pivot: fencePivot,
                                             direction: -1, size: size) else { return }
        var fence = blownFence
        fence.translateBy(x: fencePivot.x, y: fencePivot.y)
        fence.rotate(by: .degrees(2.2))
        fence.translateBy(x: -fencePivot.x, y: -fencePivot.y)
        for railY in [fenceTop + 22 * scale, fenceTop + 47 * scale] {
            let rail = CGRect(x: fenceStart, y: railY,
                              width: fenceWidth, height: 9 * scale)
            fence.fill(Path(roundedRect: rail, cornerRadius: 3 * scale),
                       with: .color(wood))
            fence.stroke(Path(roundedRect: rail, cornerRadius: 3 * scale),
                         with: .color(woodDark.opacity(0.55)), lineWidth: 1.2 * scale)
            fence.fill(Path(CGRect(x: rail.minX + 4, y: rail.minY + 1.5 * scale,
                                   width: rail.width - 8, height: 2 * scale)),
                       with: .color(woodLight.opacity(0.55)))
        }

        // Four close-set posts make the short fence read as a real section;
        // the first one is partly cropped by the left edge on purpose.
        for fraction in [0.12, 0.42, 0.72, 1.0] as [CGFloat] {
            let x = fenceStart + fenceWidth * fraction
            let postWidth = 13 * scale
            var post = Path()
            post.move(to: CGPoint(x: x - postWidth / 2, y: fenceBottom))
            post.addLine(to: CGPoint(x: x - postWidth / 2, y: fenceTop + 8 * scale))
            post.addLine(to: CGPoint(x: x, y: fenceTop))
            post.addLine(to: CGPoint(x: x + postWidth / 2, y: fenceTop + 8 * scale))
            post.addLine(to: CGPoint(x: x + postWidth / 2, y: fenceBottom))
            post.closeSubpath()
            fence.fill(post, with: .color(woodLight))
            fence.stroke(post, with: .color(woodDark.opacity(0.58)), lineWidth: 1.3 * scale)

            var grain = Path()
            grain.move(to: CGPoint(x: x - 2 * scale, y: fenceTop + 15 * scale))
            grain.addQuadCurve(to: CGPoint(x: x + 2 * scale, y: fenceTop + 31 * scale),
                               control: CGPoint(x: x + 4 * scale, y: fenceTop + 22 * scale))
            fence.stroke(grain, with: .color(woodDark.opacity(0.28)), lineWidth: scale)
        }
    }

    /// First dynamite blast throws the left fence off the left edge and the
    /// answer board off the right. `direction` is −1 (left) or +1 (right).
    private func blownDressing(_ context: GraphicsContext, pivot: CGPoint,
                               direction: CGFloat, size: CGSize) -> GraphicsContext? {
        if dressingScatter >= 0.98 { return nil }
        guard dressingScatter > 0.001 else { return context }
        let t = dressingScatter
        var blown = context
        let dx = direction * t * (size.width * 0.64 + 40)
        let lift = CGFloat(sin(Double(t) * .pi * 0.78)) * 86 + t * 26
        blown.translateBy(x: pivot.x + dx, y: pivot.y - lift)
        blown.rotate(by: .degrees(Double(direction) * t * (34 + t * 28)))
        blown.translateBy(x: -pivot.x, y: -pivot.y)
        blown.opacity = Double(max(0, 1 - t * 0.7))
        return blown
    }

    private func drawMeadow(context: GraphicsContext, size: CGSize, scale: CGFloat) {
        let meadowBottom = grassY + 10

        var farHill = Path()
        farHill.move(to: CGPoint(x: 0, y: grassY - 52 * scale))
        farHill.addQuadCurve(to: CGPoint(x: size.width * 0.53,
                                         y: grassY - 46 * scale),
                             control: CGPoint(x: size.width * 0.25,
                                              y: grassY - 75 * scale))
        farHill.addQuadCurve(to: CGPoint(x: size.width,
                                         y: grassY - 54 * scale),
                             control: CGPoint(x: size.width * 0.78,
                                              y: grassY - 73 * scale))
        farHill.addLine(to: CGPoint(x: size.width, y: meadowBottom))
        farHill.addLine(to: CGPoint(x: 0, y: meadowBottom))
        farHill.closeSubpath()
        context.fill(farHill, with: .linearGradient(
            Gradient(colors: [Color(red: 0.60, green: 0.82, blue: 0.35),
                              Color(red: 0.46, green: 0.72, blue: 0.25)]),
            startPoint: CGPoint(x: 0, y: grassY - 75 * scale),
            endPoint: CGPoint(x: 0, y: meadowBottom)))

        drawMeadowTree(context: context,
                       base: CGPoint(x: size.width * 0.045, y: grassY - 17 * scale),
                       height: 55 * scale, tint: 0.08)
        drawMeadowTree(context: context,
                       base: CGPoint(x: size.width * 0.125, y: grassY - 16 * scale),
                       height: 42 * scale, tint: 0.18)
        drawMeadowTree(context: context,
                       base: CGPoint(x: size.width * 0.885, y: grassY - 16 * scale),
                       height: 45 * scale, tint: 0.15)
        drawMeadowTree(context: context,
                       base: CGPoint(x: size.width * 0.965, y: grassY - 17 * scale),
                       height: 58 * scale, tint: 0.04)

        var middleHill = Path()
        middleHill.move(to: CGPoint(x: 0, y: grassY - 35 * scale))
        middleHill.addQuadCurve(to: CGPoint(x: size.width * 0.44,
                                            y: grassY - 42 * scale),
                                control: CGPoint(x: size.width * 0.20,
                                                 y: grassY - 56 * scale))
        middleHill.addQuadCurve(to: CGPoint(x: size.width,
                                            y: grassY - 29 * scale),
                                control: CGPoint(x: size.width * 0.74,
                                                 y: grassY - 56 * scale))
        middleHill.addLine(to: CGPoint(x: size.width, y: meadowBottom))
        middleHill.addLine(to: CGPoint(x: 0, y: meadowBottom))
        middleHill.closeSubpath()
        context.fill(middleHill, with: .linearGradient(
            Gradient(colors: [Color(red: 0.43, green: 0.75, blue: 0.22),
                              Color(red: 0.29, green: 0.63, blue: 0.17)]),
            startPoint: CGPoint(x: 0, y: grassY - 57 * scale),
            endPoint: CGPoint(x: 0, y: meadowBottom)))

        var nearHill = Path()
        nearHill.move(to: CGPoint(x: 0, y: grassY - 18 * scale))
        nearHill.addQuadCurve(to: CGPoint(x: size.width * 0.58,
                                          y: grassY - 23 * scale),
                              control: CGPoint(x: size.width * 0.28,
                                               y: grassY - 39 * scale))
        nearHill.addQuadCurve(to: CGPoint(x: size.width,
                                          y: grassY - 15 * scale),
                              control: CGPoint(x: size.width * 0.82,
                                               y: grassY - 33 * scale))
        nearHill.addLine(to: CGPoint(x: size.width, y: meadowBottom))
        nearHill.addLine(to: CGPoint(x: 0, y: meadowBottom))
        nearHill.closeSubpath()
        context.fill(nearHill, with: .linearGradient(
            Gradient(colors: [Color(red: 0.31, green: 0.68, blue: 0.16),
                              Color(red: 0.21, green: 0.54, blue: 0.12)]),
            startPoint: CGPoint(x: 0, y: grassY - 39 * scale),
            endPoint: CGPoint(x: 0, y: meadowBottom)))

        // Tiny stemmed blooms on the hill bands. Bare ellipses read as
        // floating heads; a short stem plants each one in the slope.
        let meadowPetals = [
            Color.white.opacity(0.92),
            Color(red: 0.98, green: 0.86, blue: 0.32).opacity(0.90),
            Color(red: 1.00, green: 0.62, blue: 0.72).opacity(0.88)
        ]
        for index in 0..<10 {
            let x = size.width * (CGFloat(index) + 0.32) / 10
            let stem = (7 + CGFloat((index * 11) % 10)) * scale
            let headY = grassY - (16 + CGFloat((index * 17) % 18)) * scale
            drawDaisy(context: context,
                      at: CGPoint(x: x, y: headY),
                      petal: meadowPetals[index % meadowPetals.count],
                      scale: (0.40 + CGFloat(index % 3) * 0.07) * scale,
                      opacity: 0.86,
                      tilt: index.isMultiple(of: 2) ? -7 : 8,
                      stemHeight: stem,
                      stemLean: (index.isMultiple(of: 2) ? -1.4 : 1.6) * scale)
        }
    }

    private func drawMeadowTree(context: GraphicsContext, base: CGPoint,
                                height: CGFloat, tint: Double) {
        let trunkWidth = max(2.5, height * 0.075)
        let trunk = CGRect(x: base.x - trunkWidth / 2,
                           y: base.y - height * 0.56,
                           width: trunkWidth,
                           height: height * 0.58)
        context.fill(Path(roundedRect: trunk, cornerRadius: trunkWidth / 2),
                     with: .linearGradient(
                        Gradient(colors: [Color(red: 0.76, green: 0.62, blue: 0.39)
                            .opacity(0.70),
                                          Color(red: 0.49, green: 0.39, blue: 0.24)
                            .opacity(0.58)]),
                        startPoint: CGPoint(x: trunk.minX, y: 0),
                        endPoint: CGPoint(x: trunk.maxX, y: 0)))

        var branches = Path()
        branches.move(to: CGPoint(x: base.x, y: base.y - height * 0.38))
        branches.addLine(to: CGPoint(x: base.x - height * 0.18,
                                     y: base.y - height * 0.57))
        branches.move(to: CGPoint(x: base.x, y: base.y - height * 0.45))
        branches.addLine(to: CGPoint(x: base.x + height * 0.20,
                                     y: base.y - height * 0.64))
        context.stroke(branches,
                       with: .color(Color(red: 0.51, green: 0.42, blue: 0.25)
                          .opacity(0.46)),
                       style: StrokeStyle(lineWidth: max(1.2, trunkWidth * 0.45),
                                          lineCap: .round))

        let leaf = Color(red: 0.55 + tint,
                         green: 0.79 + tint * 0.35,
                         blue: 0.38 + tint * 0.25)
        let leafShadow = Color(red: 0.38 + tint,
                               green: 0.68 + tint * 0.25,
                               blue: 0.29 + tint * 0.20)
        let crowns: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.22, -0.67, 0.42),
            (0.18, -0.70, 0.48),
            (0.00, -0.86, 0.54),
            (-0.30, -0.88, 0.34),
            (0.30, -0.91, 0.36)
        ]
        for (index, crown) in crowns.enumerated() {
            let diameter = height * crown.2
            let rect = CGRect(x: base.x + height * crown.0 - diameter / 2,
                              y: base.y + height * crown.1 - diameter / 2,
                              width: diameter, height: diameter * 0.92)
            context.fill(Path(ellipseIn: rect),
                         with: .linearGradient(
                            Gradient(colors: [leaf.opacity(0.88),
                                              leafShadow.opacity(0.82)]),
                            startPoint: CGPoint(x: rect.midX, y: rect.minY),
                            endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
            if index.isMultiple(of: 2) {
                context.fill(Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.20,
                                                    y: rect.minY + rect.height * 0.16,
                                                    width: rect.width * 0.34,
                                                    height: rect.height * 0.20)),
                             with: .color(Color.white.opacity(0.17)))
            }
        }
    }

    /// Meadow daisy: oval petals around a warm centre, planted on a visible
    /// stem whose length is chosen per bloom so the bank is not one height.
    private func drawDaisy(context: GraphicsContext, at point: CGPoint,
                           petal: Color, scale: CGFloat, opacity: CGFloat,
                           tilt: Double, stemHeight: CGFloat,
                           stemLean: CGFloat = 0) {
        var planted = context
        planted.opacity = Double(opacity)

        let stemGreen = Color(red: 0.18, green: 0.50, blue: 0.12)
        let stemLength = max(6.5 * scale, stemHeight)
        var stem = Path()
        stem.move(to: CGPoint(x: point.x + 0.2 * scale, y: point.y + 2.4 * scale))
        stem.addQuadCurve(
            to: CGPoint(x: point.x + stemLean, y: point.y + stemLength),
            control: CGPoint(x: point.x + stemLean * 0.35 + 2.4 * scale,
                             y: point.y + stemLength * 0.48)
        )
        planted.stroke(stem,
                       with: .color(stemGreen),
                       style: StrokeStyle(lineWidth: max(1.35, 1.7 * scale),
                                          lineCap: .round))

        if stemLength > 15 * scale {
            let leafY = point.y + stemLength * 0.52
            let side: CGFloat = stemLean >= 0 ? 1 : -1
            var leaf = Path()
            leaf.move(to: CGPoint(x: point.x, y: leafY))
            leaf.addQuadCurve(
                to: CGPoint(x: point.x + side * 6.2 * scale,
                            y: leafY - 4.6 * scale),
                control: CGPoint(x: point.x + side * 2.2 * scale,
                                 y: leafY - 0.8 * scale)
            )
            leaf.addQuadCurve(
                to: CGPoint(x: point.x + side * 0.4 * scale,
                            y: leafY - 1.6 * scale),
                control: CGPoint(x: point.x + side * 3.6 * scale,
                                 y: leafY - 6.0 * scale)
            )
            planted.fill(leaf, with: .color(stemGreen.opacity(0.88)))
        }

        var flower = planted
        flower.translateBy(x: point.x, y: point.y)
        flower.rotate(by: .degrees(tilt))

        for index in 0..<8 {
            let angle = Double(index) * .pi * 2 / 8 - .pi / 2
            let reach = 4.8 * scale
            let petalPath = Path(ellipseIn: CGRect(x: -2.4 * scale,
                                                   y: -7.8 * scale,
                                                   width: 4.8 * scale,
                                                   height: 8.0 * scale))
            let transform = CGAffineTransform(rotationAngle: CGFloat(angle + .pi / 2))
                .concatenating(
                    CGAffineTransform(translationX: CGFloat(cos(angle)) * reach,
                                      y: CGFloat(sin(angle)) * reach)
                )
            var placed = Path()
            placed.addPath(petalPath, transform: transform)
            flower.fill(placed, with: .color(petal))
        }

        let heart = CGRect(x: -2.8 * scale, y: -2.8 * scale,
                           width: 5.6 * scale, height: 5.6 * scale)
        flower.fill(Path(ellipseIn: heart), with: .radialGradient(
            Gradient(colors: [
                Color(red: 1.00, green: 0.92, blue: 0.42),
                Color(red: 0.98, green: 0.62, blue: 0.12)
            ]),
            center: CGPoint(x: -0.6 * scale, y: -0.7 * scale),
            startRadius: 0,
            endRadius: 3.4 * scale))
        flower.fill(Path(ellipseIn: CGRect(x: -1.3 * scale, y: -1.5 * scale,
                                           width: 1.8 * scale, height: 1.5 * scale)),
                    with: .color(Color.white.opacity(0.45)))
    }

    private func drawAnswerSign(context: GraphicsContext, size: CGSize) {
        // Before the landscape scenery pass, this sign deliberately used only
        // the phone's width. Reusing the new height-aware scenery scale made a
        // tall iPhone board roughly 60% larger. iPad's current size is right,
        // so retain the richer surface scale there and restore the phone value.
        let scale = isPad
            ? surfaceScale(in: size)
            : HabitatDraw.scale(for: size.width)
        let wood = Color(red: 0.70, green: 0.42, blue: 0.18)
        let woodLight = Color(red: 0.90, green: 0.68, blue: 0.38)
        let woodDark = Color(red: 0.34, green: 0.16, blue: 0.06)
        let parchment = Color(red: 0.99, green: 0.94, blue: 0.82)
        let parchmentDeep = Color(red: 0.93, green: 0.84, blue: 0.66)
        let boardWidth = 142 * scale
        let boardHeight = 58 * scale
        let centre = CGPoint(x: size.width - boardWidth / 2 - 8 * scale,
                             y: grassY - boardHeight / 2 - 16 * scale)
        guard let blownSign = blownDressing(context, pivot: centre,
                                            direction: 1, size: size) else { return }
        var sign = blownSign
        sign.translateBy(x: centre.x, y: centre.y)
        sign.rotate(by: .degrees(2.2))

        let postWidth = 10.4 * scale
        let postInset = boardWidth * 0.28
        let postXs = [-postInset, postInset]
        let grassLine = grassY - centre.y
        sign.drawLayer { posts in
            // Cut the stakes at the turf so they never continue into the
            // soil cross-section. Grass drawn afterwards hides the cut.
            posts.clip(to: Path(CGRect(x: -boardWidth, y: -boardHeight * 1.4,
                                       width: boardWidth * 2,
                                       height: grassLine + boardHeight * 1.4 + 3 * scale)))
            for px in postXs {
                let top = -boardHeight / 2 - 4 * scale
                let bottom = grassLine + 6 * scale
                let stake = Path(roundedRect: CGRect(x: px - postWidth / 2,
                                                     y: top,
                                                     width: postWidth,
                                                     height: bottom - top),
                                 cornerRadius: postWidth / 2)
                posts.fill(stake, with: .linearGradient(
                    Gradient(colors: [woodLight, wood, woodDark]),
                    startPoint: CGPoint(x: px - postWidth / 2, y: 0),
                    endPoint: CGPoint(x: px + postWidth / 2, y: 0)))
                posts.stroke(stake, with: .color(woodDark.opacity(0.72)),
                             lineWidth: 1.05 * scale)
                posts.fill(Path(ellipseIn: CGRect(x: px - postWidth * 0.22,
                                                  y: top + 4 * scale,
                                                  width: postWidth * 0.28,
                                                  height: (bottom - top) * 0.45)),
                           with: .color(Color.white.opacity(0.16)))
            }
        }
        for px in postXs {
            let socket = CGRect(x: px - postWidth * 0.85,
                                y: grassLine - 4.5 * scale,
                                width: postWidth * 1.7,
                                height: 8 * scale)
            sign.fill(Path(ellipseIn: socket),
                      with: .color(Color(red: 0.28, green: 0.14, blue: 0.06).opacity(0.72)))
        }

        let frame = answerBoardPath(width: boardWidth, height: boardHeight,
                                    scale: scale)
        let inset = 6.56 * scale
        let panel = answerBoardPath(width: boardWidth - inset * 2,
                                    height: boardHeight - inset * 2,
                                    scale: scale)
        var underside = sign
        underside.translateBy(x: 0.9 * scale, y: 3.8 * scale)
        underside.fill(frame, with: .color(woodDark.opacity(0.90)))

        sign.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.26), radius: 3.4 * scale,
                                    x: 1.2 * scale, y: 3.2 * scale))
            layer.fill(frame,
                       with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.96, green: 0.76, blue: 0.46),
                                  location: 0),
                            .init(color: woodLight, location: 0.18),
                            .init(color: wood, location: 0.62),
                            .init(color: Color(red: 0.48, green: 0.24, blue: 0.08),
                                  location: 1)
                        ]),
                        startPoint: CGPoint(x: 0, y: -boardHeight / 2),
                        endPoint: CGPoint(x: 0, y: boardHeight / 2)))
        }
        sign.stroke(frame, with: .color(woodDark.opacity(0.82)),
                    style: StrokeStyle(lineWidth: 1.7 * scale, lineJoin: .round))

        var recess = sign
        recess.translateBy(x: 0, y: 1.1 * scale)
        recess.fill(panel, with: .color(woodDark.opacity(0.28)))

        sign.fill(panel, with: .linearGradient(
            Gradient(colors: [parchment, parchmentDeep]),
            startPoint: CGPoint(x: 0, y: -boardHeight / 2 + inset),
            endPoint: CGPoint(x: 0, y: boardHeight / 2 - inset)))
        sign.stroke(panel, with: .color(woodDark.opacity(0.16)),
                    style: StrokeStyle(lineWidth: 0.9 * scale, lineJoin: .round))

        let title = languageCode == "nl" ? "Pak het juiste" : "Grab the right"
        let punch = languageCode == "nl" ? "antwoord!" : "answer!"
        let panelBox = CGRect(x: -boardWidth / 2 + inset + 5 * scale,
                              y: -boardHeight / 2 + inset + 3 * scale,
                              width: boardWidth - inset * 2 - 10 * scale,
                              height: boardHeight - inset * 2 - 6 * scale)
        let ink = Color(red: 0.32, green: 0.16, blue: 0.06)
        var titleSize = min(13.2 * scale, panelBox.height * 0.34)
        for _ in 0..<8 {
            let width = sign.resolve(
                Text(title)
                    .font(.system(size: titleSize, weight: .heavy, design: .rounded))
            ).measure(in: CGSize(width: 480, height: 80)).width
            if width <= panelBox.width * 0.92 { break }
            titleSize *= 0.94
        }
        let punchSize = min(titleSize * 1.08, panelBox.height * 0.38)
        let lineGap = panelBox.height * 0.46
        let titleY = panelBox.minY + panelBox.height * 0.30
        let punchY = titleY + lineGap

        var readableText = sign
        if isRightToLeft {
            readableText.scaleBy(x: -1, y: 1)
        }
        func drawLine(_ copy: String, size: CGFloat, at point: CGPoint) {
            var resolved = sign.resolve(
                Text(copy)
                    .font(.system(size: size, weight: .heavy, design: .rounded))
            )
            resolved.shading = .color(ink)
            var shadow = resolved
            shadow.shading = .color(Color(red: 0.42, green: 0.24, blue: 0.10).opacity(0.28))
            let readableX = isRightToLeft ? -point.x : point.x
            let nudge = isRightToLeft ? -0.7 * scale : 0.7 * scale
            readableText.draw(shadow,
                              at: CGPoint(x: readableX + nudge,
                                          y: point.y + 0.85 * scale),
                              anchor: .center)
            readableText.draw(resolved,
                              at: CGPoint(x: readableX, y: point.y),
                              anchor: .center)
        }
        drawLine(title, size: titleSize, at: CGPoint(x: 0, y: titleY))
        drawLine(punch, size: punchSize, at: CGPoint(x: 0, y: punchY))

        let punchWidth = sign.resolve(
            Text(punch)
                .font(.system(size: punchSize, weight: .heavy, design: .rounded))
        ).measure(in: CGSize(width: 480, height: 80)).width
        let foodHeight = 16.8 * scale
        let foodReach = min(panelBox.width * 0.38,
                            punchWidth / 2 + foodHeight * 0.55)
        let foodTilt = Angle.degrees(32)
        sign.drawLayer { layer in
            layer.clip(to: panel)
            drawSignFood(context: layer,
                         at: CGPoint(x: -foodReach, y: punchY + 0.4 * scale),
                         height: foodHeight,
                         rotation: foodTilt,
                         mirrored: true)
            drawSignFood(context: layer,
                         at: CGPoint(x: foodReach, y: punchY + 0.4 * scale),
                         height: foodHeight,
                         rotation: foodTilt,
                         mirrored: false)
        }

        drawSignGrass(context: sign, baseY: grassY - centre.y,
                      scale: scale, postXs: postXs)
    }

    private func drawSignGrass(context: GraphicsContext, baseY: CGFloat,
                               scale: CGFloat, postXs: [CGFloat]) {
        let grassDark = habitatGround.lushDeep
        let grassMid = habitatGround.lushMid
        let grassLight = habitatGround.lushLight
        let grassGlow = habitatGround.lushGlow

        for postX in postXs {
            for (x, width, height) in [
                (postX / scale - 9, 16, 7),
                (postX / scale + 2, 15, 6)
            ] as [(CGFloat, CGFloat, CGFloat)] {
                let rect = CGRect(x: (x - width / 2) * scale,
                                  y: baseY - height * 0.55 * scale,
                                  width: width * scale, height: height * scale)
                context.fill(Path(ellipseIn: rect),
                             with: .color(grassDark.opacity(0.90)))
            }
            for tooth in -4...4 {
                    let extra = CGFloat(abs(tooth)) * 1.6
                    let centreBoost: CGFloat = tooth == 0 ? 6 : 0
                    drawFilledGrassBlade(
                    context: context,
                    root: CGPoint(x: postX + CGFloat(tooth) * 2.2 * scale,
                                  y: baseY + 0.4 * scale),
                    height: (11 + extra + centreBoost) * scale,
                    lean: CGFloat(tooth) * 2.4 * scale,
                    halfWidth: 1.25 * scale,
                    color: {
                        switch abs(tooth) {
                        case 0: return grassGlow
                        case 1, 2: return grassLight
                        default: return grassMid
                        }
                    }()
                )
            }
        }

        for index in 0..<18 {
            let span = (postXs.last ?? 24 * scale) - (postXs.first ?? -24 * scale)
            let x = (postXs.first ?? -24 * scale) + span * CGFloat(index) / 17
            let side: CGFloat = x < 0 ? -1 : 1
            let height = (7 + CGFloat((index * 7) % 8)) * scale
            drawFilledGrassBlade(
                context: context,
                root: CGPoint(x: x, y: baseY + CGFloat(index % 2) * scale),
                height: height,
                lean: side * (1.5 + CGFloat(index % 4)) * scale,
                halfWidth: 0.95 * scale,
                color: index.isMultiple(of: 3) ? grassLight : grassDark
            )
        }
    }

    private func answerBoardPath(width: CGFloat, height: CGFloat,
                                 scale: CGFloat) -> Path {
        // Rounded rectangle with a light hand-drawn wobble — close to the
        // wooden plaque in the reference, not a puffy two-hump blob.
        let hw = width / 2
        let hh = height / 2
        let corner = min(hw, hh) * 0.36
        var board = Path()
        board.move(to: CGPoint(x: -hw + corner, y: -hh + 1.1 * scale))
        board.addQuadCurve(to: CGPoint(x: hw - corner, y: -hh + 1.4 * scale),
                           control: CGPoint(x: 0, y: -hh - 1.6 * scale))
        board.addQuadCurve(to: CGPoint(x: hw - 0.4 * scale, y: -hh + corner),
                           control: CGPoint(x: hw + 1.1 * scale, y: -hh + 0.8 * scale))
        board.addQuadCurve(to: CGPoint(x: hw - 0.3 * scale, y: hh - corner),
                           control: CGPoint(x: hw + 1.8 * scale, y: 0.4 * scale))
        board.addQuadCurve(to: CGPoint(x: hw - corner, y: hh - 1.0 * scale),
                           control: CGPoint(x: hw + 1.0 * scale, y: hh - 0.4 * scale))
        board.addQuadCurve(to: CGPoint(x: -hw + corner, y: hh - 1.3 * scale),
                           control: CGPoint(x: 0, y: hh + 1.5 * scale))
        board.addQuadCurve(to: CGPoint(x: -hw + 0.4 * scale, y: hh - corner),
                           control: CGPoint(x: -hw - 1.1 * scale, y: hh - 0.5 * scale))
        board.addQuadCurve(to: CGPoint(x: -hw + 0.5 * scale, y: -hh + corner),
                           control: CGPoint(x: -hw - 1.7 * scale, y: -0.2 * scale))
        board.addQuadCurve(to: CGPoint(x: -hw + corner, y: -hh + 1.1 * scale),
                           control: CGPoint(x: -hw - 1.0 * scale, y: -hh + 0.7 * scale))
        board.closeSubpath()
        return board
    }

    private func drawSignFood(context: GraphicsContext, at point: CGPoint,
                              height: CGFloat, rotation: Angle,
                              mirrored: Bool = false) {
        let width = height * CGFloat(pickupStyle.canvasAspectRatio)
        var stamp = context
        stamp.translateBy(x: point.x, y: point.y)
        if mirrored {
            stamp.scaleBy(x: -1, y: 1)
        }
        stamp.rotate(by: rotation)
        stamp.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.26),
                                    radius: height * 0.08,
                                    x: height * 0.04, y: height * 0.07))
            let art = layer.resolve(Image(pickupStyle.assetName))
            layer.draw(art, in: CGRect(x: -width / 2, y: -height / 2,
                                       width: width, height: height))
        }
    }
}

/// The moving glints are deliberately their own tiny canvas. Everything that
/// determines their position is shared with `RabbitHoleSoil.drawSunbeam`, so
/// separating the render pass does not change their appearance or placement.
private struct RabbitHoleSunbeamSparkles: View {
    let grassY: CGFloat
    let floorDropped: Bool
    let fallShift: CGFloat
    let shaftReveal: CGFloat
    let skyAmount: CGFloat
    let clock: Double
    let finaleLayout: Bool
    let finaleCameraShift: CGFloat

    var body: some View {
        Canvas { context, size in
            let inset = max(18, size.width * 0.06)
            let shift = finaleLayout
                ? min(size.width * 0.48, max(0, finaleCameraShift))
                : 0
            let left = inset - shift
            let right = size.width - inset - shift
            let wallTop = grassY * (1 - min(1, max(0, shaftReveal)))
            let origin = max(0, wallTop)
            let floorY = floorDropped ? size.height + 4 : grassY + fallShift
            let shaftHeight = max(8, min(floorY, grassY + 8) - origin)
            let strength = max(0.38, min(1, skyAmount / 0.84))

            for index in 0..<7 {
                let progress = CGFloat(index) / 6
                let x = left + 16 + progress * (right - left - 32)
                let y = origin + 18
                    + CGFloat((index * 37) % 80) / 80 * min(shaftHeight * 0.45, 80)
                let rect = CGRect(x: x, y: y, width: 3.5, height: 3.5)
                let opacity = (0.16 + 0.10 * sin(clock * 2.2 + Double(index)))
                    * Double(strength)
                context.fill(Path(ellipseIn: rect),
                             with: .color(Color.white.opacity(opacity)))
            }
        }
    }
}

// MARK: - Crane

private struct CraneRig: View {
    let character: AnimalCharacter
    let isPad: Bool
    let surface: CGRect
    let fieldSize: CGSize
    let floorIndex: Int
    /// Zero while the old floor is gone, one once the tracks meet the next
    /// floor. Keeping this separate from the character art lets the loose PNG
    /// remain untouched while its contact with the world still feels physical.
    let groundContact: CGFloat
    let boom: CGPoint
    let hook: CGPoint
    let entrance: CGFloat
    let reach: CGFloat
    let squash: CGFloat
    let hop: CGFloat
    let travelX: CGFloat
    let tilt: Double
    let flip: Double
    let hookWiggle: Double

    private var slide: CGFloat { (1 - entrance) * (-surface.width * 0.7) }

    /// Transform around the track contact point, so squash and landing tilt do
    /// not make the supposedly stationary machine slide vertically. Derived from
    /// the boom so underground lift, grass nestle and landing squash share one
    /// contact.
    private var groundAnchor: UnitPoint {
        let contactY = RabbitHoleCraneLayout.worldPoint(
            CGPoint(x: RabbitHoleCraneLayout.canvasTracksCenterX,
                    y: RabbitHoleCraneLayout.canvasTracksY),
            boom: boom,
            isPad: isPad
        ).y
        return UnitPoint(x: boom.x / max(1, fieldSize.width),
                         y: contactY / max(1, fieldSize.height))
    }

    var body: some View {
        let angle = atan2(Double(hook.x - boom.x), Double(hook.y - boom.y))
        let pose = RabbitHoleCraneLayout.trolleyPose(boom: boom, angle: angle, isPad: isPad)
        let rot = Angle.radians(pose.rotation)
        let downX = CGFloat(-sin(pose.rotation))
        let downY = CGFloat(cos(pose.rotation))
        let topSize = RabbitHoleCraneLayout.topSize(isPad: isPad)
        let clawSize = RabbitHoleCraneLayout.clawSize(isPad: isPad)
        let canvasSize = RabbitHoleCraneLayout.displayedCanvasSize(isPad: isPad)
        let canvasCenter = RabbitHoleCraneLayout.canvasFrameCenter(boom: boom, isPad: isPad)
        let rearTrack = RabbitHoleCraneLayout.worldPoint(
            RabbitHoleCraneLayout.canvasTracksRear,
            boom: boom,
            isPad: isPad
        )
        let trackContact = RabbitHoleCraneLayout.worldPoint(
            CGPoint(x: RabbitHoleCraneLayout.canvasTracksCenterX,
                    y: RabbitHoleCraneLayout.canvasTracksY),
            boom: boom,
            isPad: isPad
        )
        let flipAnchor = UnitPoint(x: rearTrack.x / max(1, fieldSize.width),
                                   y: rearTrack.y / max(1, fieldSize.height))
        let extra = max(0, hypot(hook.x - boom.x, hook.y - boom.y)
                        - RabbitHoleCraneLayout.restHang(isPad: isPad))
        let clawGlue = CGPoint(x: pose.glue.x + downX * extra,
                               y: pose.glue.y + downY * extra)

        ZStack {
            CraneContactShadow(isPad: isPad,
                               floorIndex: floorIndex,
                               contact: groundContact,
                               hop: hop,
                               flip: flip)
                .position(x: trackContact.x, y: trackContact.y - (isPad ? 6 : 5))
                .offset(x: slide + travelX)

            CraneHookShadow(isPad: isPad,
                            floorIndex: floorIndex,
                            contact: groundContact,
                            hop: hop,
                            flip: flip,
                            heightAbove: trackContact.y - hook.y)
                .position(x: (clawGlue.x + hook.x) / 2,
                          y: trackContact.y - (isPad ? 6 : 5))
                .offset(x: slide + travelX)

            ZStack {
                cabStack(size: canvasSize)
                    .position(x: canvasCenter.x, y: canvasCenter.y)

                // The telescoping rails leave the top assembly and pass in
                // front of the cab/operator artwork on their way to the claw.
                // Their order is visual, not physical: placing them before the
                // large cab textures hid the rails behind the character.
                extensionRods(from: pose.glue, to: clawGlue)

                CraneSprite(name: "claw",
                            size: clawSize,
                            anchor: UnitPoint(x: RabbitHoleCraneLayout.clawBarX,
                                              y: RabbitHoleCraneLayout.clawTopY),
                            angle: rot + .degrees(hookWiggle))
                    .position(x: clawGlue.x, y: clawGlue.y)

                CraneSprite(name: "top_part",
                            size: topSize,
                            anchor: RabbitHoleCraneLayout.topCentroid,
                            angle: rot)
                    .position(x: pose.centroid.x, y: pose.centroid.y)
            }
            .frame(width: fieldSize.width, height: fieldSize.height)
            .scaleEffect(x: 1 / max(0.55, squash), y: squash, anchor: groundAnchor)
            .rotationEffect(.degrees(tilt), anchor: groundAnchor)
            .rotationEffect(.degrees(flip), anchor: flipAnchor)
            .offset(x: slide + travelX, y: -hop)

            // Surface grass belongs to the stationary meadow. Drawing a
            // second grass strip inside this moving rig made green blades
            // slide in with the excavator during the opening animation.
            if floorIndex > 0 {
                CraneTerrainOverlap(isPad: isPad,
                                    floorIndex: floorIndex,
                                    contact: groundContact,
                                    hop: hop,
                                    flip: flip)
                    .position(x: trackContact.x, y: trackContact.y)
                    .offset(x: slide + travelX)
            }
        }
        .frame(width: fieldSize.width, height: fieldSize.height)
        .allowsHitTesting(false)
    }

    /// Main body, then the stick, then the operator arm — all on the shared canvas.
    /// Rest uses the pre art as drawn. A full grab uses the after art as drawn.
    /// In between, the poke hinges clockwise around its foot and the arm slides.
    private func cabStack(size: CGSize) -> some View {
        let kit = character.excavatorKit
        let thrown = reach >= 1
        let scale = RabbitHoleCraneLayout.canvasScale(isPad: isPad)
        let armShift = CGSize(width: kit.armSlide.width * scale * reach,
                              height: kit.armSlide.height * scale * reach)
        return ZStack {
            Image(kit.body)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
            Image(thrown ? kit.pokeAfter : kit.pokePre)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(thrown ? 0 : kit.pokeThrowDegrees * Double(reach)),
                                anchor: kit.pokePivot)
            Image(thrown ? kit.armAfter : kit.armPre)
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .offset(x: thrown ? 0 : armShift.width,
                        y: thrown ? 0 : armShift.height)
        }
        .frame(width: size.width, height: size.height)
    }

    /// Two rods, only while the claw is away from the trolley.
    @ViewBuilder
    private func extensionRods(from: CGPoint, to: CGPoint) -> some View {
        let span = hypot(to.x - from.x, to.y - from.y)
        if span > 6 {
            let angle = atan2(Double(to.x - from.x), Double(to.y - from.y))
            let nx = CGFloat(cos(angle))
            let ny = -CGFloat(sin(angle))
            let gap: CGFloat = isPad ? 9 : 7
            let width: CGFloat = isPad ? 4.5 : 3.5
            let rod = Color(red: 0.16, green: 0.16, blue: 0.18)
            let shine = Color(red: 0.46, green: 0.47, blue: 0.50)
            ForEach([-0.5, 0.5] as [CGFloat], id: \.self) { side in
                let ox = nx * gap * side
                let oy = ny * gap * side
                Path { path in
                    path.move(to: CGPoint(x: from.x + ox, y: from.y + oy))
                    path.addLine(to: CGPoint(x: to.x + ox, y: to.y + oy))
                }
                .stroke(rod, style: StrokeStyle(lineWidth: width, lineCap: .round))
                Path { path in
                    path.move(to: CGPoint(x: from.x + ox - nx * 0.8, y: from.y + oy - ny * 0.8))
                    path.addLine(to: CGPoint(x: to.x + ox - nx * 0.8, y: to.y + oy - ny * 0.8))
                }
                .stroke(shine.opacity(0.7), style: StrokeStyle(lineWidth: width * 0.35, lineCap: .round))
            }
        }
    }
}

/// A terrain-aware shadow at the crawler contact patch. The former broad drop
/// shadow outlined the complete transparent asset and made it read like a
/// sticker. This low, soft shape grounds that same loose asset without baking
/// grass or soil into any of the character PNGs.
private struct CraneContactShadow: View {
    let isPad: Bool
    let floorIndex: Int
    let contact: CGFloat
    let hop: CGFloat
    let flip: Double

    private var isUnderground: Bool { floorIndex > 0 }
    private var width: CGFloat { isPad ? 238 : 180 }
    private var height: CGFloat { isPad ? 34 : 25 }

    private var presence: Double {
        let hopFade = max(0, 1 - hop / (isPad ? 42 : 32))
        let flipFade = max(0, 1 - abs(flip) / 18)
        return Double(max(0, min(1, contact * hopFade * CGFloat(flipFade))))
    }

    private var terrainShade: Color {
        isUnderground
            ? Color(red: 0.16, green: 0.095, blue: 0.045)
            : Color(red: 0.12, green: 0.22, blue: 0.075)
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(terrainShade.opacity(isUnderground ? 0.58 : 0.46))
                .frame(width: width, height: height)
                .blur(radius: isPad ? 7 : 5)

            // Two denser patches follow the large near crawler and the small
            // far crawler. Breaking the core keeps it from reading as a clean
            // UI ellipse on the organic terrain.
            Ellipse()
                .fill(Color.black.opacity(isUnderground ? 0.34 : 0.26))
                .frame(width: width * 0.69, height: height * 0.31)
                .offset(x: -width * 0.12)
                .blur(radius: isPad ? 2.4 : 1.8)

            Ellipse()
                .fill(Color.black.opacity(isUnderground ? 0.29 : 0.21))
                .frame(width: width * 0.27, height: height * 0.26)
                .offset(x: width * 0.36)
                .blur(radius: isPad ? 2.2 : 1.6)
        }
        .frame(width: width + 24, height: height + 18)
        .compositingGroup()
        .blendMode(.multiply)
        .opacity(presence)
        .scaleEffect(x: 0.94 + 0.06 * contact,
                     y: 0.82 + 0.18 * contact)
        .allowsHitTesting(false)
    }
}

/// A faint overhead-cast disc under the claw. It stays on the dirt plane and
/// only strengthens a little as the hook comes down, so a high rest pose
/// does not print a second machine-sized shadow.
private struct CraneHookShadow: View {
    let isPad: Bool
    let floorIndex: Int
    let contact: CGFloat
    let hop: CGFloat
    let flip: Double
    let heightAbove: CGFloat

    private var isUnderground: Bool { floorIndex > 0 }
    private var width: CGFloat { isPad ? 42 : 32 }
    private var height: CGFloat { isPad ? 12 : 9 }

    private var presence: Double {
        let hopFade = max(0, 1 - hop / (isPad ? 42 : 32))
        let flipFade = max(0, 1 - abs(flip) / 18)
        let reach: CGFloat = isPad ? 130 : 96
        let proximity = max(0, min(1, 1 - abs(heightAbove) / reach))
        return Double(max(0, min(1, contact * hopFade * CGFloat(flipFade) * proximity)))
    }

    var body: some View {
        Ellipse()
            .fill(Color.black.opacity(isUnderground ? 0.22 : 0.16))
            .frame(width: width, height: height)
            .blur(radius: isPad ? 4 : 3)
            .blendMode(.multiply)
            .opacity(presence * 0.85)
            .scaleEffect(x: 0.72 + 0.28 * CGFloat(presence),
                         y: 0.68 + 0.32 * CGFloat(presence))
            .allowsHitTesting(false)
    }
}

/// A few pixels of underground terrain cross in front of the crawler baseline.
/// That small occlusion makes the otherwise independent transparent artwork
/// feel planted: loose clods and stones share the floor's progressively darker
/// earth colour. Surface grass is part of the stationary meadow instead.
private struct CraneTerrainOverlap: View {
    let isPad: Bool
    let floorIndex: Int
    let contact: CGFloat
    let hop: CGFloat
    let flip: Double

    private var width: CGFloat { isPad ? 190 : 144 }
    private var height: CGFloat { isPad ? 28 : 21 }
    private var scale: CGFloat { isPad ? 1.28 : 1 }

    private var presence: Double {
        let hopFade = max(0, 1 - hop / (isPad ? 42 : 32))
        let flipFade = max(0, 1 - abs(flip) / 18)
        return Double(max(0, min(1, contact * hopFade * CGFloat(flipFade))))
    }

    private var earth: Color {
        let depth = min(7, max(1, floorIndex))
        return Color(red: 0.42 - Double(depth) * 0.018,
                     green: 0.245 - Double(depth) * 0.012,
                     blue: 0.125 - Double(depth) * 0.006)
    }

    private var earthDeep: Color {
        let depth = min(7, max(1, floorIndex))
        return Color(red: 0.245 - Double(depth) * 0.012,
                     green: 0.135 - Double(depth) * 0.007,
                     blue: 0.070 - Double(depth) * 0.003)
    }

    var body: some View {
        Canvas { context, size in
            drawEarth(context: context, size: size)
        }
        .frame(width: width, height: height)
        .opacity(presence)
        .allowsHitTesting(false)
    }

    private func drawEarth(context: GraphicsContext, size: CGSize) {
        let stones: [(CGFloat, CGFloat, CGFloat)] = [
            (0.04, 2.4, -0.5), (0.17, 3.4, 1), (0.31, 2.0, -1),
            (0.64, 2.7, 0.5), (0.79, 3.5, -1), (0.94, 2.2, 0.5)
        ]
        let baseY = size.height * 0.59
        for (index, stone) in stones.enumerated() {
            let radius = stone.1 * scale
            let centre = CGPoint(x: size.width * stone.0,
                                 y: baseY + stone.2 * scale)
            let rect = CGRect(x: centre.x - radius,
                              y: centre.y - radius * 0.58,
                              width: radius * 2,
                              height: radius * 1.16)
            context.fill(Path(ellipseIn: rect),
                         with: .color((index.isMultiple(of: 2) ? earth : earthDeep)
                            .opacity(0.92)))

            let glint = CGRect(x: centre.x - radius * 0.43,
                               y: centre.y - radius * 0.40,
                               width: radius * 0.62,
                               height: max(0.7, radius * 0.20))
            context.fill(Path(ellipseIn: glint),
                         with: .color(Color.white.opacity(0.12)))
        }
    }
}

private struct CraneSprite: View {
    let name: String
    let size: CGSize
    let anchor: UnitPoint
    let angle: Angle

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .frame(width: size.width, height: size.height)
            .offset(x: size.width * (0.5 - anchor.x),
                    y: size.height * (0.5 - anchor.y))
            .rotationEffect(angle)
    }
}

// MARK: - Answer pickup

private struct AnswerPickupView: View {
    let text: String
    let style: FoodPickupStyle
    let isPad: Bool
    let isRightToLeft: Bool
    var scale: CGFloat = 1
    var spin: Double = 0
    var opacity: Double = 1

    private var height: CGFloat {
        GameConfig.rabbitHoleDisplayedItemLength(isPad: isPad) * scale
    }
    private var width: CGFloat { height * CGFloat(style.canvasAspectRatio) }

    private var numberColor: Color {
        switch style.numberContrast {
        case .light:
            return .white
        case .cocoa:
            return Color(red: 0.24, green: 0.10, blue: 0.035)
        case .plum:
            return Color(red: 0.31, green: 0.045, blue: 0.20)
        case .violet:
            return Color(red: 0.19, green: 0.08, blue: 0.32)
        }
    }

    private var numberOutline: Color {
        style.numberContrast == .light
            ? Color.black.opacity(0.78)
            : Color.white.opacity(0.88)
    }

    var body: some View {
        ZStack {
            Image(style.assetName)
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.28), radius: 5, y: 3)

            Text(verbatim: text)
                .font(.system(size: height * 0.20, weight: .black, design: .rounded))
                .foregroundStyle(numberColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(width: width * CGFloat(style.numberWidthFraction))
                .shadow(color: numberOutline,
                        radius: max(0.8, height * 0.012))
                .shadow(color: numberOutline.opacity(0.65),
                        radius: max(0.5, height * 0.006), y: 1)
                .offset(y: height * CGFloat(style.numberYOffsetFraction))
                // Cancel the world reflection for the answer only. The carrot
                // or alternate pickup and its trajectory still mirror.
                .scaleEffect(x: isRightToLeft ? -1 : 1, y: 1)
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(spin))
        .opacity(opacity)
        .accessibilityHidden(true)
    }
}

// MARK: - Dynamite

/// A live preview of the path the claw will take if the player taps now.
/// Both endpoints come from the arena's real grab geometry, so the guide never
/// teaches an approximation that differs from the actual hook.
private struct TutorialHookGuide: View {
    let start: CGPoint
    let end: CGPoint
    let isPad: Bool

    var body: some View {
        Canvas { context, _ in
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path,
                           with: .color(.white.opacity(0.92)),
                           style: StrokeStyle(lineWidth: isPad ? 4 : 3,
                                              lineCap: .round,
                                              dash: isPad ? [4, 10] : [3, 8]))

            let radius: CGFloat = isPad ? 11 : 8
            let target = Path(ellipseIn: CGRect(x: end.x - radius,
                                                y: end.y - radius,
                                                width: radius * 2,
                                                height: radius * 2))
            context.fill(target, with: .color(.white.opacity(0.18)))
            context.stroke(target,
                           with: .color(.white.opacity(0.95)),
                           style: StrokeStyle(lineWidth: isPad ? 3 : 2,
                                              dash: [3, 4]))
        }
        .accessibilityHidden(true)
    }
}

/// Clearly blocks the tutorial bomb without hiding it. The double translucent
/// shell reads as a protective bubble, while the slow pulse keeps it visibly
/// separate from ordinary floor decoration.
private struct DynamiteShieldView: View {
    let isPad: Bool
    let clock: Double

    private var size: CGFloat { isPad ? 150 : 98 }

    var body: some View {
        let pulse = 1 + CGFloat(sin(clock * 2.4)) * 0.025
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.14))
                .overlay {
                    Circle().stroke(Color.white.opacity(0.92), lineWidth: isPad ? 4 : 3)
                }
                .overlay {
                    Circle()
                        .stroke(Color.cyan.opacity(0.78), lineWidth: isPad ? 2.5 : 2)
                        .padding(isPad ? 8 : 6)
                }
                .shadow(color: Color.cyan.opacity(0.55), radius: isPad ? 12 : 8)

            Image(systemName: "shield.fill")
                .font(.system(size: isPad ? 31 : 21, weight: .bold))
                .foregroundStyle(.white.opacity(0.92), Color.cyan.opacity(0.72))
                .offset(y: size * 0.34)
        }
        .frame(width: size, height: size)
        .scaleEffect(pulse)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

private struct DynamiteStickView: View {
    let item: RabbitHoleItem
    let seconds: Double
    let isPad: Bool
    let isRightToLeft: Bool
    let clock: Double

    private var height: CGFloat {
        // The final asset is a genuinely bigger bundle. The first pass forced
        // both source images to one height, making the swap hard to notice.
        GameConfig.rabbitHoleDisplayedItemLength(isPad: isPad)
            * (item.isFinalDynamite ? 1.12 : 1)
    }
    private var width: CGFloat {
        height * (item.isFinalDynamite ? 498.0 / 578.0 : 396.0 / 445.0)
    }
    private var assetName: String { item.isFinalDynamite ? "big bomb" : "small bomb" }
    private var burnProgress: CGFloat {
        guard seconds <= 5 else { return 0 }
        return min(1, max(0, CGFloat((5 - seconds) / 5)))
    }

    var body: some View {
        let time = max(0, Int(ceil(seconds)))
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .topLeading) {
                Image(assetName)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: size.width, height: size.height)
                    .mask {
                        BombArtworkMask(isFinal: item.isFinalDynamite,
                                        burnProgress: burnProgress)
                    }
                    .shadow(color: .black.opacity(0.28), radius: 5, y: 3)

                BombTimerDisplay(time: time,
                                 isFinal: item.isFinalDynamite,
                                 bombRotation: item.spin,
                                 isRightToLeft: isRightToLeft)
                    .frame(width: size.width, height: size.height)

                if seconds > 0, seconds <= 5 {
                    FuseFlame(clock: clock)
                        .frame(width: max(10, size.height * 0.14),
                               height: max(13, size.height * 0.18))
                        .position(BombFuseShape.point(at: burnProgress,
                                                     in: CGRect(origin: .zero, size: size),
                                                     isFinal: item.isFinalDynamite))
                }
            }
            .rotationEffect(.degrees(item.spin))
        }
        .frame(width: width, height: height)
        .accessibilityLabel(Text(verbatim: "\(time)"))
    }
}

private struct BombArtworkMask: View {
    let isFinal: Bool
    let burnProgress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let bodyTop = proxy.size.height * (isFinal ? 0.145 : 0.205)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .frame(width: proxy.size.width,
                           height: proxy.size.height - bodyTop)
                    .offset(y: bodyTop)
                BombFuseShape(isFinal: isFinal)
                    .trim(from: burnProgress, to: 1)
                    .stroke(style: StrokeStyle(lineWidth: proxy.size.height * 0.09,
                                               lineCap: .round,
                                               lineJoin: .round))
            }
        }
    }
}

private struct BombFuseShape: Shape {
    let isFinal: Bool

    func path(in rect: CGRect) -> Path {
        let geometry = Self.geometry(isFinal: isFinal)
        var path = Path()
        path.move(to: Self.denormalize(geometry.start, in: rect))
        path.addCurve(to: Self.denormalize(geometry.end, in: rect),
                      control1: Self.denormalize(geometry.control1, in: rect),
                      control2: Self.denormalize(geometry.control2, in: rect))
        return path
    }

    static func point(at progress: CGFloat, in rect: CGRect, isFinal: Bool) -> CGPoint {
        let g = geometry(isFinal: isFinal)
        let t = min(1, max(0, progress))
        let mt = 1 - t
        let x = mt * mt * mt * g.start.x
            + 3 * mt * mt * t * g.control1.x
            + 3 * mt * t * t * g.control2.x
            + t * t * t * g.end.x
        let y = mt * mt * mt * g.start.y
            + 3 * mt * mt * t * g.control1.y
            + 3 * mt * t * t * g.control2.y
            + t * t * t * g.end.y
        return denormalize(CGPoint(x: x, y: y), in: rect)
    }

    private static func geometry(isFinal: Bool) -> (start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint) {
        if isFinal {
            return (CGPoint(x: 0.602, y: 0.012),
                    CGPoint(x: 0.590, y: 0.050),
                    CGPoint(x: 0.530, y: 0.125),
                    CGPoint(x: 0.534, y: 0.205))
        }
        return (CGPoint(x: 0.505, y: 0.004),
                CGPoint(x: 0.600, y: 0.060),
                CGPoint(x: 0.565, y: 0.175),
                CGPoint(x: 0.548, y: 0.270))
    }

    private static func denormalize(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + point.x * rect.width,
                y: rect.minY + point.y * rect.height)
    }
}

private struct BombTimerDisplay: View {
    let time: Int
    let isFinal: Bool
    let bombRotation: Double
    let isRightToLeft: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            // Centres measured from the actual cream label interiors. The
            // frame sizes retain a comfortable inset on every side, including
            // after the whole bomb is rotated.
            let center = CGPoint(x: size.width * (isFinal ? 0.505 : 0.501),
                                 y: size.height * (isFinal ? 0.629 : 0.609))
            SevenSegmentNumber(value: time)
                // Sized against the worst-case 13° counter-rotation, so even
                // the corners of two wide digits stay inside the cream panel.
                .frame(width: size.height * (isFinal ? 0.215 : 0.155),
                       height: size.height * (isFinal ? 0.160 : 0.150))
                // Applied before the counter-rotation: after the bomb and the
                // complete gameplay world rotate/reflect, the digits remain
                // upright and retain their normal left-to-right order.
                .scaleEffect(x: isRightToLeft ? -1 : 1, y: 1)
                // The position follows the rotated label, while the digits
                // counter-rotate so the countdown itself remains upright.
                .rotationEffect(.degrees(-bombRotation))
                .position(center)
        }
    }
}

private struct SevenSegmentNumber: View {
    let value: Int

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(99, max(0, value))
            HStack(spacing: proxy.size.height * 0.10) {
                SevenSegmentDigit(value: clamped / 10)
                SevenSegmentDigit(value: clamped % 10)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityLabel(Text(verbatim: "\(value)"))
    }
}

private struct SevenSegmentDigit: View {
    let value: Int

    private static let activeSegments: [Set<Int>] = [
        [0, 1, 2, 3, 4, 5],       // 0
        [1, 2],                   // 1
        [0, 1, 6, 4, 3],         // 2
        [0, 1, 6, 2, 3],         // 3
        [5, 6, 1, 2],            // 4
        [0, 5, 6, 2, 3],         // 5
        [0, 5, 6, 4, 2, 3],      // 6
        [0, 1, 2],                // 7
        [0, 1, 2, 3, 4, 5, 6],   // 8
        [0, 1, 2, 3, 5, 6]       // 9
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let thickness = max(1.2, size.height * 0.105)
            let active = Self.activeSegments[min(9, max(0, value))]
            ZStack {
                segment(0, active: active, width: size.width * 0.70, height: thickness,
                        x: size.width * 0.50, y: size.height * 0.07)
                segment(3, active: active, width: size.width * 0.70, height: thickness,
                        x: size.width * 0.50, y: size.height * 0.93)
                segment(6, active: active, width: size.width * 0.70, height: thickness,
                        x: size.width * 0.50, y: size.height * 0.50)
                segment(5, active: active, width: thickness, height: size.height * 0.34,
                        x: size.width * 0.12, y: size.height * 0.285)
                segment(1, active: active, width: thickness, height: size.height * 0.34,
                        x: size.width * 0.88, y: size.height * 0.285)
                segment(4, active: active, width: thickness, height: size.height * 0.34,
                        x: size.width * 0.12, y: size.height * 0.715)
                segment(2, active: active, width: thickness, height: size.height * 0.34,
                        x: size.width * 0.88, y: size.height * 0.715)
            }
        }
    }

    private func segment(_ index: Int,
                         active: Set<Int>,
                         width: CGFloat,
                         height: CGFloat,
                         x: CGFloat,
                         y: CGFloat) -> some View {
        Capsule()
            .fill(Color(red: 0.43, green: 0.075, blue: 0.035)
                .opacity(active.contains(index) ? 0.96 : 0.075))
            .frame(width: width, height: height)
            .shadow(color: active.contains(index) ? .red.opacity(0.16) : .clear,
                    radius: 0.7)
            .position(x: x, y: y)
    }
}

private struct FuseFlame: View {
    let clock: Double

    var body: some View {
        let flicker = CGFloat(0.90 + 0.10 * sin(clock * 29))
        ZStack {
            Capsule()
                .fill(Color.orange.opacity(0.35))
                .frame(width: 13, height: 17)
                .blur(radius: 4)
            Capsule()
                .fill(LinearGradient(colors: [.red, .orange, .yellow],
                                     startPoint: .bottom,
                                     endPoint: .top))
                .frame(width: 8, height: 14)
            Capsule()
                .fill(LinearGradient(colors: [.yellow, .white],
                                     startPoint: .bottom,
                                     endPoint: .top))
                .frame(width: 3.5, height: 8)
                .offset(y: 2)
        }
        .scaleEffect(x: 1 / flicker, y: flicker, anchor: .bottom)
        .rotationEffect(.degrees(sin(clock * 23) * 7))
        .allowsHitTesting(false)
    }
}

// MARK: - Particles

private struct RabbitHoleFireball: View {
    let origin: CGPoint
    let pulse: CGFloat
    let size: CGSize

    var body: some View {
        Canvas { context, _ in
            guard pulse > 0.01 else { return }
            let margin = max(18, size.width * 0.06)
            let left = origin.x - (origin.x - margin) * pulse
            let right = origin.x + (size.width - margin - origin.x) * pulse
            let span = max(40, right - left)
            let height = 70 + 130 * pulse
            let center = CGPoint(x: (left + right) / 2, y: origin.y)
            let glowRect = CGRect(x: center.x - span / 2, y: center.y - height / 2,
                                  width: span, height: height)
            context.fill(Path(ellipseIn: glowRect), with: .linearGradient(
                Gradient(colors: [
                    Color.orange.opacity(0.20 * Double(pulse)),
                    Color.yellow.opacity(0.78 * Double(pulse)),
                    Color.white.opacity(0.70 * Double(pulse)),
                    Color.yellow.opacity(0.78 * Double(pulse)),
                    Color.orange.opacity(0.20 * Double(pulse))
                ]),
                startPoint: CGPoint(x: left, y: center.y),
                endPoint: CGPoint(x: right, y: center.y)
            ))
            let lobeRadius = max(span * 0.28, height * 0.55)
            for x in [left + span * 0.18, center.x, right - span * 0.18] {
                let lobe = CGRect(x: x - lobeRadius, y: center.y - height * 0.48,
                                  width: lobeRadius * 2, height: height * 0.96)
                context.fill(Path(ellipseIn: lobe), with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.70 * Double(pulse)),
                        Color.yellow.opacity(0.55 * Double(pulse)),
                        Color.orange.opacity(0.28 * Double(pulse)),
                        Color.red.opacity(0)
                    ]),
                    center: CGPoint(x: x, y: center.y),
                    startRadius: 0,
                    endRadius: lobeRadius
                ))
            }
            let coreH = height * 0.42
            let coreW = span * 0.42
            let coreRect = CGRect(x: center.x - coreW / 2, y: center.y - coreH / 2,
                                  width: coreW, height: coreH)
            context.fill(Path(ellipseIn: coreRect), with: .radialGradient(
                Gradient(colors: [
                    Color.white.opacity(Double(pulse)),
                    Color.yellow.opacity(0.9 * Double(pulse)),
                    Color.orange.opacity(0)
                ]),
                center: center,
                startRadius: 0,
                endRadius: max(coreW, coreH) * 0.55
            ))
            let ringRect = glowRect.insetBy(dx: -12 * pulse, dy: -8 * pulse)
            context.stroke(Path(ellipseIn: ringRect),
                           with: .color(Color.orange.opacity(0.50 * Double(1 - pulse * 0.35))),
                           lineWidth: 8 * (1.1 - pulse * 0.4))
            let ring2 = glowRect.insetBy(dx: span * 0.12, dy: height * 0.18)
            context.stroke(Path(ellipseIn: ring2),
                           with: .color(Color.yellow.opacity(0.38 * Double(max(0, 0.85 - pulse)))),
                           lineWidth: 4)
        }
        .allowsHitTesting(false)
    }
}

private struct RabbitHoleParticles: View {
    let particles: [RabbitHoleParticle]

    var body: some View {
        Canvas { context, _ in
            for particle in particles {
                let fade = max(0, 1 - particle.age / particle.life)
                let rect = CGRect(x: particle.position.x - particle.radius,
                                  y: particle.position.y - particle.radius,
                                  width: particle.radius * 2,
                                  height: particle.radius * 2)
                switch particle.kind {
                case .dust:
                    let puff = Path(ellipseIn: rect)
                    context.fill(puff, with: .color(Color(red: 0.48, green: 0.32, blue: 0.18).opacity(fade * 0.55)))
                    context.fill(Path(ellipseIn: rect.insetBy(dx: particle.radius * 0.25, dy: particle.radius * 0.35)),
                                 with: .color(Color(red: 0.62, green: 0.44, blue: 0.26).opacity(fade * 0.28)))
                case .clod:
                    drawDirtClod(context: context, particle: particle, fade: fade)
                case .spark:
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(Color(red: 1.0, green: 0.82, blue: 0.28).opacity(fade)))
                    context.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)),
                                 with: .color(Color.orange.opacity(fade * 0.35)))
                case .fire:
                    let color = Color(red: 1.0, green: 0.45 + 0.4 * fade, blue: 0.12)
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(fade)))
                case .smoke:
                    context.fill(Path(ellipseIn: rect),
                                 with: .color(Color(red: 0.28, green: 0.24, blue: 0.22).opacity(fade * 0.45)))
                case .shard:
                    drawDirtClod(context: context, particle: particle, fade: fade)
                case .confetti:
                    let color = [Color.orange, Color.yellow, Color.pink, Color.green][abs(Int(particle.spin)) % 4]
                    context.fill(Path(ellipseIn: rect), with: .color(color.opacity(fade)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawDirtClod(context: GraphicsContext, particle: RabbitHoleParticle, fade: Double) {
        let r = particle.radius
        let seed = particle.spin
        let sides = 5 + abs(Int(seed)) % 3
        let angle = seed * .pi / 180
        var clod = Path()
        for i in 0..<sides {
            let t = Double(i) / Double(sides) * .pi * 2 + angle
            let wobble = 0.62 + 0.38 * abs(sin(seed * 0.17 + Double(i) * 1.7))
            let x = particle.position.x + CGFloat(cos(t)) * r * wobble
            let y = particle.position.y + CGFloat(sin(t)) * r * wobble * 0.82
            if i == 0 {
                clod.move(to: CGPoint(x: x, y: y))
            } else {
                clod.addLine(to: CGPoint(x: x, y: y))
            }
        }
        clod.closeSubpath()
        let mix = abs(sin(seed * 0.05))
        let dirt = Color(red: 0.32 + 0.16 * mix, green: 0.18 + 0.10 * mix, blue: 0.10 + 0.04 * mix)
        context.fill(clod, with: .color(dirt.opacity(fade)))
        let hx = particle.position.x + CGFloat(cos(angle - 0.8)) * r * 0.18
        let hy = particle.position.y + CGFloat(sin(angle - 0.8)) * r * 0.18
        context.fill(Path(ellipseIn: CGRect(x: hx - r * 0.28, y: hy - r * 0.22,
                                            width: r * 0.5, height: r * 0.32)),
                     with: .color(Color(red: 0.55, green: 0.38, blue: 0.22).opacity(fade * 0.45)))
        if abs(Int(seed)) % 3 == 0 {
            let tx = particle.position.x + CGFloat(cos(angle - .pi / 2)) * r * 0.2
            let ty = particle.position.y + CGFloat(sin(angle - .pi / 2)) * r * 0.2
            let tip = CGPoint(x: particle.position.x + CGFloat(cos(angle - .pi / 2)) * r * 1.05,
                              y: particle.position.y + CGFloat(sin(angle - .pi / 2)) * r * 1.05)
            var blade = Path()
            blade.move(to: CGPoint(x: tx, y: ty))
            blade.addQuadCurve(to: tip,
                               control: CGPoint(x: tx + CGFloat(cos(angle)) * r * 0.35,
                                                y: ty + CGFloat(sin(angle)) * r * 0.35))
            context.stroke(blade, with: .color(Color(red: 0.34, green: 0.58, blue: 0.18).opacity(fade * 0.85)),
                           style: StrokeStyle(lineWidth: max(1.2, r * 0.12), lineCap: .round))
        }
    }
}

// MARK: - Banner

/// The warm paper inside the sum card. HUD controls reuse the exact same fill
/// so the score and pause glyph belong visually to the question they support.
enum RabbitHoleHUDStyle {
    static var questionInterior: LinearGradient {
        LinearGradient(colors: [
            Color(red: 1.00, green: 0.96, blue: 0.88),
            Color(red: 0.98, green: 0.90, blue: 0.76)
        ], startPoint: .top, endPoint: .bottom)
    }
}

struct RabbitHoleQuestionBanner: View {
    let prompt: String
    let roundID: UUID?
    let accent: Color
    let deep: Color
    let isPad: Bool

    @State private var shownPrompt = ""
    @State private var isVisible = true

    var body: some View {
        promptLabel
            .font(.system(size: isPad ? 34 : 24, weight: .black, design: .rounded))
            .minimumScaleFactor(0.34)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, isPad ? 18 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                        .fill(RabbitHoleHUDStyle.questionInterior)
                    RoundedRectangle(cornerRadius: isPad ? 22 : 18, style: .continuous)
                        .stroke(accent.opacity(0.70), lineWidth: 3)
                    RoundedRectangle(cornerRadius: isPad ? 16 : 12, style: .continuous)
                        .stroke(deep.opacity(0.28), style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))
                        .padding(6)
                }
                .shadow(color: deep.opacity(0.20), radius: 8, y: 4)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .onAppear { shownPrompt = prompt }
            .onChange(of: Question(id: roundID, prompt: prompt)) { question in
                reveal(question.prompt)
            }
            .accessibilityIdentifier("question-card")
            .accessibilityLabel(Text(L("game.question \(prompt)")))
    }

    private var promptLabel: Text {
        Text(verbatim: shownPrompt).foregroundColor(deep)
    }

    private struct Question: Equatable {
        let id: UUID?
        let prompt: String
    }

    private func reveal(_ newPrompt: String) {
        guard !shownPrompt.isEmpty else {
            shownPrompt = newPrompt
            return
        }
        withAnimation(.easeOut(duration: 0.10)) { isVisible = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            shownPrompt = newPrompt
            withAnimation(.easeOut(duration: 0.20)) { isVisible = true }
        }
    }
}

#if canImport(UIKit)
private final class HoleTapPassthrough: UIView {
    var onTouchesBegan: ((CGPoint) -> Void)?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { onTouchesBegan?(touch.location(in: self)) }
    }
}

private struct HoleTapView: UIViewRepresentable {
    let onTap: (CGPoint) -> Void
    func makeUIView(context: Context) -> HoleTapPassthrough {
        let view = HoleTapPassthrough()
        view.backgroundColor = .clear
        view.onTouchesBegan = onTap
        return view
    }
    func updateUIView(_ uiView: HoleTapPassthrough, context: Context) {
        uiView.onTouchesBegan = onTap
    }
}
#endif
