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
    var tutorialPlan = CrabTutorialPlan()
    var reservesTutorialMessage = false
    let topReserve: CGFloat
    let bottomReserve: CGFloat
    let scoreTarget: CGPoint?

    let onCorrect: (UUID) -> Bool
    var onWrong: (String) -> Void = { _ in }
    var onDynamiteMistake: () -> Void = {}
    var onTimeout: () -> Void = {}
    var onSmash: () -> Void = {}
    let onShellArrived: () -> Void
    var onBonusCrabCaught: () -> Void = {}
    var onLifeCrabArrived: () -> Bool = { false }
    let onKingEntranceComplete: () -> Void
    var onLevelCompletionStarted: () -> Void = {}
    let onLevelCompletionFinished: () -> Void
    var onTutorialEvent: (CrabTutorialEvent) -> Void = { _ in }
    var onGuardedArrival: ((UUID) -> Bool)? = nil
    var onSmashedGuard: (() -> Bool)? = nil
    var onBreach: (() -> Void)? = nil
    var onSweep: (() -> Void)? = nil

    @StateObject private var arena = RabbitHoleArena()
    @ObservedObject private var language = LanguageManager.shared

    private var palette: ReefPalette { ReefPalette.palette(for: character) }

    private var surfaceTop: CGFloat {
        topReserve + (isPad ? 8 : 4)
            + (reservesTutorialMessage ? ArenaConfig.tutorialMessageReserve(isPad: isPad) : 0)
    }

    private func grassLine(in size: CGSize) -> CGFloat {
        let target = size.height * GameConfig.rabbitHoleGrassShare
        let minGrass = surfaceTop + (isPad ? 132 : 100)
        let maxGrass = size.height - bottomReserve - (isPad ? 280 : 220)
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
            let skyVisibility: CGFloat = arena.floorIndex == 0
                ? 1
                : max(arena.finaleSurfaceReveal, 1 - arena.shaftReveal)
            // A clean patch of sky remains visible behind the surviving grass
            // rim on floor one. It contains no sun or clouds and fades away
            // continuously during the descent to floor two.
            let openingVisibility: CGFloat = arena.floorIndex == 0
                ? 0
                : max(arena.finaleSurfaceReveal,
                      min(1, max(0, 2 - travelledFloors)))

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

                RabbitHoleSky(palette: palette, clock: arena.clock, amount: arena.skyAmount)
                    .opacity(Double(skyVisibility))

                RabbitHoleSoil(palette: palette,
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
                               clock: arena.clock,
                               languageCode: language.effective.code,
                               carrotPockets: arena.items
                                   .filter { !$0.isDynamite }
                                   .map(\.rest),
                               dynamitePocket: arena.items
                                   .first(where: \.isDynamite)?.rest,
                               finaleLayout: arena.isCelebrating,
                               finaleSurfaceProgress: arena.finaleSurfaceReveal,
                               finaleCameraShift: arena.isCelebrating
                                   ? min(size.width * 0.48,
                                         max(0, arena.finaleTravelX) * 1.1)
                                   : 0)
                    .equatable()
                    .frame(width: size.width, height: size.height)

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

                CraneRig(isPad: isPad,
                         surface: surface,
                         fieldSize: size,
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
                arena.layout(size: size, field: field, surface: surface, isPad: isPad)
                arena.setRemainingQuestions(remainingQuestions,
                                            maximum: maximumRounds,
                                            mistakes: mistakeCount)
                arena.setRound(round)
                arena.setLive(isLive)
                arena.setReduceMotion(reduceMotion)
                arena.setSpeedMultiplier(1)
                arena.setScoreTarget(localScoreTarget(scoreTarget, in: proxy))
                arena.setTutorialActive(tutorialPlan.isActive)
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
        .onChange(of: tutorialPlan.isActive) { active in
            arena.setTutorialActive(active)
            skipCrabOnlySteps(tutorialPlan)
        }
        .onChange(of: tutorialPlan.wantsLifeCrab) { wants in
            if wants { onTutorialEvent(.lifeCrabArrived) }
        }
        .onChange(of: tutorialPlan.wantsBonusCrab) { wants in
            if wants { onTutorialEvent(.caughtBonusCrab) }
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
        return CGPoint(x: global.x - origin.x, y: global.y - origin.y)
    }

    @ViewBuilder
    private func floorItem(_ item: RabbitHoleItem) -> some View {
        if item.isDynamite {
            DynamiteStickView(item: item,
                              seconds: item.flight == .blast ? 0 : arena.dynamiteTime,
                              isPad: isPad,
                              clock: arena.clock)
                .scaleEffect(item.scale)
                .opacity(item.opacity)
        } else {
            AnswerCarrotView(text: item.text,
                             isPad: isPad,
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
        arena.onTimeout = onTimeout
        arena.onShellArrived = onShellArrived
        arena.onDrop = onSmash
        arena.onExplode = { AppAudio.shared.playFlamethrower() }
        arena.onTutorialEvent = onTutorialEvent
    }

    /// The walkthrough still talks about helper crabs. Those never spawn here,
    /// so those two steps close themselves the moment they are asked for.
    private func skipCrabOnlySteps(_ plan: CrabTutorialPlan) {
        if plan.wantsLifeCrab { onTutorialEvent(.lifeCrabArrived) }
        if plan.wantsBonusCrab { onTutorialEvent(.caughtBonusCrab) }
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

    var body: some View {
        let dusk = min(1, max(0, 1 - amount))
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.27 - 0.13 * dusk,
                          green: 0.76 - 0.24 * dusk,
                          blue: 1.00 - 0.16 * dusk),
                    Color(red: 0.48 - 0.16 * dusk,
                          green: 0.86 - 0.28 * dusk,
                          blue: 1.00 - 0.19 * dusk),
                    Color(red: 0.77 - 0.30 * dusk,
                          green: 0.94 - 0.34 * dusk,
                          blue: 0.72 - 0.20 * dusk)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(Color(red: 1, green: 0.92, blue: 0.45).opacity(0.95 - 0.35 * dusk))
                .frame(width: 64, height: 64)
                .position(x: 56, y: 78)
                .blur(radius: 0.4)
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
            let cloudFill = LinearGradient(
                colors: [.white,
                         Color(red: 0.91, green: 0.97, blue: 1.0),
                         Color(red: 0.82, green: 0.92, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
            ZStack {
                RabbitPuffyCloudShape()
                    .fill(cloudFill)
                    .frame(width: 112 * scale, height: 52 * scale)
                RabbitPuffyCloudShape()
                    .stroke(Color.white.opacity(0.38), lineWidth: 0.8 * scale)
                    .frame(width: 112 * scale, height: 52 * scale)
                Capsule()
                    .fill(.white.opacity(0.48))
                    .frame(width: 35 * scale, height: 6 * scale)
                    .offset(x: -14 * scale, y: -13 * scale)
                    .blur(radius: 1.5 * scale)
            }
            .frame(width: 118 * scale, height: 58 * scale)
            .opacity(0.96 - 0.24 * dusk)
            .position(x: proxy.size.width * progress, y: proxy.size.height * y)
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
        // One broad terminal lobe tapers straight into the underside. There is
        // no extra small bump at the right that can read as another cloud.
        path.addCurve(to: CGPoint(x: w * 0.93, y: h * 0.70),
                      control1: CGPoint(x: w * 0.84, y: h * 0.30),
                      control2: CGPoint(x: w * 0.995, y: h * 0.48))
        path.addCurve(to: CGPoint(x: w * 0.79, y: h * 0.86),
                      control1: CGPoint(x: w * 0.96, y: h * 0.82),
                      control2: CGPoint(x: w * 0.88, y: h * 0.87))
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
    let clock: Double
    let languageCode: String
    var carrotPockets: [CGPoint] = []
    var dynamitePocket: CGPoint?
    var finaleLayout = false
    var finaleSurfaceProgress: CGFloat = 0
    var finaleCameraShift: CGFloat = 0

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.palette == rhs.palette
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
            && abs(lhs.clock - rhs.clock) < 0.08
            && lhs.languageCode == rhs.languageCode
            && lhs.carrotPockets == rhs.carrotPockets
            && lhs.dynamitePocket == rhs.dynamitePocket
            && lhs.finaleLayout == rhs.finaleLayout
            && abs(lhs.finaleSurfaceProgress - rhs.finaleSurfaceProgress) < 0.008
            && abs(lhs.finaleCameraShift - rhs.finaleCameraShift) < 0.4
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
                let soil = Path(CGRect(x: 0, y: grassY, width: size.width, height: size.height - grassY + 4))
                context.fill(soil, with: .linearGradient(
                    Gradient(colors: colors),
                    startPoint: CGPoint(x: 0, y: grassY),
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
                                   progress: finaleSurfaceProgress)
                }
                // The original surface rim is visible from the first basement
                // only. The second blast takes that last green silhouette out
                // of frame; deeper floors are dirt walls all the way up.
                if !finaleLayout, floorIndex == 1, !collapsing {
                    drawPitRims(context: context, size: size, edges: edges,
                                rimY: (grassY - 22) * (1 - reveal) + 10 * reveal)
                }
                drawWallRoots(context: context, size: size, edges: edges,
                              wallTop: wallTop, floorY: wellEnd)
            } else if collapsing {
                drawCollapsingGrass(context: context, size: size, edges: edges)
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

    private func drawGrassCap(context: GraphicsContext, size: CGSize,
                              x: CGFloat, width: CGFloat, y: CGFloat) {
        guard width > 4 else { return }
        let rect = CGRect(x: x, y: y - 22, width: width, height: 26)
        context.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.45, green: 0.78, blue: 0.28),
                Color(red: 0.28, green: 0.58, blue: 0.18)
            ]),
            startPoint: CGPoint(x: 0, y: y - 22),
            endPoint: CGPoint(x: 0, y: y + 4)
        ))
        var i = x + 6
        while i < x + width - 6 {
            var blade = Path()
            blade.move(to: CGPoint(x: i, y: y - 4))
            blade.addQuadCurve(to: CGPoint(x: i + 3, y: y - 14),
                               control: CGPoint(x: i + 6, y: y - 8))
            context.stroke(blade, with: .color(Color(red: 0.38, green: 0.70, blue: 0.22)),
                           lineWidth: 2)
            i += 14
        }
        _ = size
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

        for i in 0..<7 {
            let t = CGFloat(i) / 6
            let x = edges.left + 16 + t * (edges.right - edges.left - 32)
            let y = origin + 18 + CGFloat((i * 37) % 80) / 80 * min(shaftH * 0.45, 80)
            let spark = Path(ellipseIn: CGRect(x: x, y: y, width: 3.5, height: 3.5))
            let sparkle = (0.16 + 0.10 * sin(clock * 2.2 + Double(i))) * Double(strength)
            context.fill(spark, with: .color(Color.white.opacity(sparkle)))
        }
    }

    private func drawWallRoots(context: GraphicsContext, size: CGSize,
                               edges: (left: CGFloat, right: CGFloat),
                               wallTop: CGFloat, floorY: CGFloat) {
        let origin = max(0, wallTop)
        let lip = max(origin + 8, min(floorY, size.height))
        let span = max(40, lip - origin - 16)
        let spacing = max(58, span / 6)
        let phase = shaftScroll.truncatingRemainder(dividingBy: spacing)
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
    /// `rimY` is the top of the grass band (surface cap at grassY-22, shaft rest at 10).
    private func drawPitRims(context: GraphicsContext, size: CGSize,
                             edges: (left: CGFloat, right: CGFloat),
                             rimY: CGFloat) {
        let grassTop = Color(red: 0.45, green: 0.78, blue: 0.28)
        let grassBot = Color(red: 0.28, green: 0.58, blue: 0.18)
        for rect in [CGRect(x: 0, y: rimY, width: edges.left, height: 22),
                     CGRect(x: edges.right, y: rimY, width: size.width - edges.right, height: 22)] {
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [grassTop, grassBot]),
                startPoint: CGPoint(x: 0, y: rimY),
                endPoint: CGPoint(x: 0, y: rimY + 22)
            ))
        }
        for i in stride(from: 6, to: size.width, by: 14) {
            guard i < edges.left - 4 || i > edges.right + 4 else { continue }
            var blade = Path()
            blade.move(to: CGPoint(x: i, y: rimY + 8))
            blade.addQuadCurve(to: CGPoint(x: i + 3, y: rimY - 4),
                               control: CGPoint(x: i + 6, y: rimY + 2))
            context.stroke(blade, with: .color(Color(red: 0.38, green: 0.70, blue: 0.22)),
                           lineWidth: 2)
        }
    }

    /// Grass grows into view geometrically on the two existing wall tops. It
    /// deliberately contains no meadow dressing: that fence and those flowers
    /// belong to the original screen, which is now off to the left.
    private func drawFinaleRims(context: GraphicsContext, size: CGSize,
                                edges: (left: CGFloat, right: CGFloat),
                                progress: CGFloat) {
        let p = min(1, max(0, progress))
        let height = 22 * p
        guard height > 0.5 else { return }
        let y = grassY - height
        let grassTop = Color(red: 0.45, green: 0.78, blue: 0.28)
        let grassBottom = Color(red: 0.28, green: 0.58, blue: 0.18)
        let caps = [
            CGRect(x: 0, y: y, width: max(0, edges.left), height: height + 4),
            CGRect(x: max(0, edges.right), y: y,
                   width: max(0, size.width - max(0, edges.right)),
                   height: height + 4)
        ]
        for cap in caps where cap.width > 1 {
            context.fill(Path(cap), with: .linearGradient(
                Gradient(colors: [grassTop, grassBottom]),
                startPoint: CGPoint(x: 0, y: y),
                endPoint: CGPoint(x: 0, y: grassY + 4)
            ))
        }

        guard p > 0.34 else { return }
        for x in stride(from: CGFloat(5), through: size.width, by: 13) {
            guard x < edges.left - 2 || x > edges.right + 2 else { continue }
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: y + min(height, 10)))
            blade.addQuadCurve(to: CGPoint(x: x + 2, y: y - 4 * p),
                               control: CGPoint(x: x + 5, y: y + 2))
            context.stroke(blade,
                           with: .color(Color(red: 0.38, green: 0.70, blue: 0.22)),
                           lineWidth: 1.8)
        }
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
        // Grass sits on the dirt lip (grassY). Blades and flowers stand above it
        // so the rabbit can park on top rather than float in the sky.
        var grass = Path()
        grass.move(to: CGPoint(x: 0, y: grassY - 18))
        grass.addQuadCurve(to: CGPoint(x: size.width, y: grassY - 18),
                           control: CGPoint(x: size.width * 0.5, y: grassY - 28))
        grass.addLine(to: CGPoint(x: size.width, y: grassY + 8))
        grass.addLine(to: CGPoint(x: 0, y: grassY + 8))
        grass.closeSubpath()
        if holeOpen > 0.01 {
            grass.addPath(craterPath(size: size))
        }
        context.fill(grass, with: .linearGradient(
            Gradient(colors: [
                Color(red: 0.56, green: 0.85, blue: 0.30).opacity(opacity),
                Color(red: 0.38, green: 0.70, blue: 0.20).opacity(opacity),
                Color(red: 0.28, green: 0.58, blue: 0.18).opacity(opacity)
            ]),
            startPoint: CGPoint(x: 0, y: grassY - 24),
            endPoint: CGPoint(x: 0, y: grassY + 8)
        ), style: FillStyle(eoFill: true))

        var freshEdge = Path()
        freshEdge.move(to: CGPoint(x: 0, y: grassY - 18))
        freshEdge.addQuadCurve(to: CGPoint(x: size.width, y: grassY - 18),
                               control: CGPoint(x: size.width * 0.5,
                                                y: grassY - 28))
        context.stroke(freshEdge,
                       with: .color(Color(red: 0.65, green: 0.89, blue: 0.30)
                          .opacity(0.72 * opacity)),
                       style: StrokeStyle(lineWidth: 2.1, lineCap: .round))

        let edges = pitEdges(in: size)
        // Two overlapping rows of rounded sod clumps keep the meeting point
        // between meadow and soil organic instead of one ruler-straight stripe.
        for index in 0..<34 {
            let x = size.width * (CGFloat(index) + 0.18) / 34
            if holeOpen > 0.2, x > edges.left, x < edges.right { continue }
            let lift = CGFloat((index * 7) % 5)
            let width = 8.5 + CGFloat((index * 3) % 5)
            let clump = CGRect(x: x - width / 2,
                               y: grassY - 3.5 - lift * 0.45,
                               width: width, height: 5.5 + lift * 0.22)
            let color = index.isMultiple(of: 3)
                ? Color(red: 0.47, green: 0.78, blue: 0.22)
                : Color(red: 0.34, green: 0.67, blue: 0.17)
            context.fill(Path(ellipseIn: clump),
                         with: .color(color.opacity(0.86 * opacity)))

            if index.isMultiple(of: 4) {
                let glint = CGRect(x: clump.minX + 1.5, y: clump.minY + 0.6,
                                   width: clump.width * 0.46, height: 1.25)
                context.fill(Path(ellipseIn: glint),
                             with: .color(Color(red: 0.75, green: 0.93, blue: 0.34)
                                .opacity(0.62 * opacity)))
            }
        }

        for index in 0..<27 {
            let x = size.width * (CGFloat(index) + 0.58) / 27
            if holeOpen > 0.2, x > edges.left, x < edges.right { continue }
            let drop = CGFloat((index * 11) % 5)
            let width = 9 + CGFloat((index * 5) % 6)
            let clump = CGRect(x: x - width / 2,
                               y: grassY + 1 + drop * 0.55,
                               width: width, height: 4.2 + drop * 0.25)
            context.fill(Path(ellipseIn: clump),
                         with: .color(Color(red: 0.20, green: 0.49, blue: 0.11)
                            .opacity((0.76 + Double(index % 3) * 0.06) * opacity)))
        }

        // A darker, irregular underside turns the thin green line into a soft
        // turf mat that visually reaches the bottom of the parked tracks.
        var turfFringe = Path()
        for x in stride(from: 0, through: size.width, by: 7) {
            if holeOpen > 0.2, x > edges.left, x < edges.right { continue }
            let drop = 2 + CGFloat(Int(x / 7) % 4)
            turfFringe.move(to: CGPoint(x: x, y: grassY + 4))
            turfFringe.addLine(to: CGPoint(x: x + 3.5, y: grassY + 7 + drop))
            turfFringe.addLine(to: CGPoint(x: x + 7, y: grassY + 4))
        }
        context.fill(turfFringe,
                     with: .color(Color(red: 0.18, green: 0.43, blue: 0.11)
                        .opacity(0.92 * opacity)))

        // Tiny turf pockets and roots give the slimmer edge texture without
        // turning it back into a thick solid band.
        for index in 0..<20 {
            let x = size.width * (CGFloat(index) + 0.35) / 20
            if holeOpen > 0.2, x > edges.left, x < edges.right { continue }
            let y = grassY + 3 + CGFloat((index * 7) % 5)
            context.fill(Path(ellipseIn: CGRect(x: x - 2.2, y: y,
                                                width: 4.4, height: 2.2)),
                         with: .color(Color(red: 0.13, green: 0.34, blue: 0.08)
                            .opacity(0.48 * opacity)))
            if index.isMultiple(of: 2) {
                var root = Path()
                root.move(to: CGPoint(x: x, y: grassY + 5))
                root.addQuadCurve(to: CGPoint(x: x + 1.5, y: grassY + 10),
                                  control: CGPoint(x: x - 1.8, y: grassY + 7))
                context.stroke(root,
                               with: .color(Color(red: 0.62, green: 0.51, blue: 0.24)
                                  .opacity(0.38 * opacity)),
                               style: StrokeStyle(lineWidth: 0.8,
                                                  lineCap: .round))
            }

            if index.isMultiple(of: 3) {
                let crumbX = x + CGFloat((index % 2 == 0) ? 4 : -4)
                let crumbY = grassY + 9 + CGFloat((index * 3) % 4)
                context.fill(Path(ellipseIn: CGRect(x: crumbX - 1.3,
                                                    y: crumbY - 0.9,
                                                    width: 2.6, height: 1.8)),
                             with: .color(Color(red: 0.45, green: 0.29, blue: 0.12)
                                .opacity(0.66 * opacity)))
            }
        }

        // Two staggered rows keep the grass from reading as one repeated comb.
        // The pattern is deterministic so it stays still while the crane moves.
        for i in stride(from: 3, to: size.width, by: 9) {
            if holeOpen > 0.2, i > edges.left + 4, i < edges.right - 4 { continue }
            let height = 5 + CGFloat(Int(i) % 8)
            var fineBlade = Path()
            fineBlade.move(to: CGPoint(x: i, y: grassY - 7))
            fineBlade.addQuadCurve(to: CGPoint(x: i - 2, y: grassY - 7 - height),
                                   control: CGPoint(x: i + 1, y: grassY - 11))
            context.stroke(fineBlade,
                           with: .color(Color(red: 0.20, green: 0.50, blue: 0.12)
                               .opacity(0.72 * opacity)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
        for i in stride(from: 8, to: size.width, by: 14) {
            if holeOpen > 0.2, i > edges.left + 4, i < edges.right - 4 { continue }
            var blade = Path()
            let h = 10 + CGFloat((i / 17).truncatingRemainder(dividingBy: 7))
            blade.move(to: CGPoint(x: i, y: grassY - 4))
            blade.addQuadCurve(to: CGPoint(x: i + 3, y: grassY - 4 - h),
                               control: CGPoint(x: i + 6, y: grassY - 8))
            context.stroke(blade, with: .color(Color(red: 0.38, green: 0.70, blue: 0.22).opacity(opacity)),
                           lineWidth: 2)
        }

        for i in [0.16, 0.34, 0.58, 0.82] as [CGFloat] {
            let p = CGPoint(x: size.width * i, y: grassY - 14)
            if holeOpen > 0.2, p.x > edges.left, p.x < edges.right { continue }
            drawFlower(context: context, at: p,
                       color: i == 0.34 || i == 0.82
                           ? Color(red: 1.0, green: 0.78, blue: 0.18)
                           : palette.character.color,
                       scale: 0.94, opacity: opacity)
        }

        // Light flecks suggest clover and fresh shoots between the blades.
        for i in 0..<14 {
            let x = size.width * (CGFloat(i) + 0.45) / 14
            if holeOpen > 0.2, x > edges.left, x < edges.right { continue }
            let y = grassY - 14 - CGFloat((i * 7) % 9)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3.5, height: 2.2)),
                         with: .color(Color(red: 0.72, green: 0.91, blue: 0.32)
                            .opacity(0.65 * opacity)))
        }
    }

    /// Surface set dressing lives behind the excavator and is made entirely
    /// from Canvas paths. That keeps it crisp without adding image assets.
    private func drawSurfaceBackdrop(context: GraphicsContext, size: CGSize) {
        let scale = max(0.86, min(1.32, size.width / 390))
        let fenceTop = grassY - 78 * scale
        let fenceBottom = grassY - 9
        let wood = Color(red: 0.67, green: 0.39, blue: 0.17)
        let woodLight = Color(red: 0.83, green: 0.57, blue: 0.28)
        let woodDark = Color(red: 0.42, green: 0.23, blue: 0.10)

        drawMeadow(context: context, size: size, scale: scale)

        // The fence begins outside the left edge and leans gently into view.
        let fenceStart = -16 * scale
        let fenceWidth = min(size.width * 0.43, 158 * scale)
        let fencePivot = CGPoint(x: fenceStart + fenceWidth / 2,
                                 y: fenceTop + 39 * scale)
        var fence = context
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

        let backgroundFlowers: [(CGFloat, CGFloat, Color, CGFloat)] = [
            (0.08, 52, Color.white, 1.15),
            (0.19, 35, Color(red: 1.0, green: 0.49, blue: 0.66), 1.02),
            (0.60, 43, Color(red: 0.55, green: 0.42, blue: 0.96), 1.12),
            (0.69, 65, Color(red: 1.0, green: 0.45, blue: 0.60), 1.30),
            (0.91, 42, Color(red: 0.98, green: 0.78, blue: 0.20), 1.08)
        ]
        for flower in backgroundFlowers {
            let point = CGPoint(x: size.width * flower.0,
                                y: grassY - flower.1 * scale)
            drawFlower(context: context, at: point, color: flower.2,
                       scale: flower.3 * scale, opacity: 1)
        }

    }

    private func drawMeadow(context: GraphicsContext, size: CGSize, scale: CGFloat) {
        let meadowBottom = grassY - 8

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

        // Small highlights make the three bands read as a flowered meadow,
        // while remaining quiet enough to sit behind the game machinery.
        for index in 0..<18 {
            let x = size.width * (CGFloat(index) + 0.35) / 18
            let y = grassY - (14 + CGFloat((index * 17) % 23)) * scale
            let color = index.isMultiple(of: 3)
                ? Color.white.opacity(0.72)
                : Color(red: 0.94, green: 0.83, blue: 0.24).opacity(0.64)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y,
                                                width: 3.2 * scale,
                                                height: 2.7 * scale)),
                         with: .color(color))
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

    private func drawFlower(context: GraphicsContext, at point: CGPoint,
                            color: Color, scale: CGFloat, opacity: CGFloat) {
        var stem = Path()
        stem.move(to: CGPoint(x: point.x, y: point.y + 4 * scale))
        stem.addQuadCurve(to: CGPoint(x: point.x - 1.5 * scale, y: grassY - 6),
                          control: CGPoint(x: point.x + 3 * scale,
                                           y: (point.y + grassY) / 2))
        context.stroke(stem,
                       with: .color(Color(red: 0.20, green: 0.49, blue: 0.13)
                           .opacity(opacity)),
                       style: StrokeStyle(lineWidth: 1.8 * scale, lineCap: .round))
        for petal in 0..<5 {
            let angle = Double(petal) * .pi * 2 / 5 - .pi / 2
            let px = point.x + CGFloat(cos(angle)) * 5.2 * scale
            let py = point.y + CGFloat(sin(angle)) * 5.2 * scale
            context.fill(Path(ellipseIn: CGRect(x: px - 3.4 * scale,
                                                y: py - 4.5 * scale,
                                                width: 6.8 * scale,
                                                height: 9 * scale)),
                         with: .color(color.opacity(opacity)))
        }
        context.fill(Path(ellipseIn: CGRect(x: point.x - 3.2 * scale,
                                            y: point.y - 3.2 * scale,
                                            width: 6.4 * scale,
                                            height: 6.4 * scale)),
                     with: .color(Color(red: 1.0, green: 0.76, blue: 0.12)
                        .opacity(opacity)))
    }

    private func drawAnswerSign(context: GraphicsContext, size: CGSize) {
        let scale = max(0.86, min(1.32, size.width / 390))
        let wood = Color(red: 0.67, green: 0.39, blue: 0.17)
        let woodLight = Color(red: 0.94, green: 0.68, blue: 0.36)
        let woodDark = Color(red: 0.39, green: 0.20, blue: 0.075)
        let boardWidth = 84 * scale
        let boardHeight = 44 * scale
        let centre = CGPoint(x: size.width - boardWidth / 2 - 10 * scale,
                             y: grassY - boardHeight / 2 - 20 * scale)
        var sign = context
        sign.translateBy(x: centre.x, y: centre.y)
        sign.rotate(by: .degrees(3.0))

        // A broad carved stake, visible above the single plank like the
        // reference sign and planted a few points into the turf below it.
        let post = CGRect(x: -4.5 * scale, y: -boardHeight / 2 - 8 * scale,
                          width: 9 * scale, height: boardHeight + 34 * scale)
        sign.fill(Path(roundedRect: post, cornerRadius: 3 * scale),
                  with: .linearGradient(
                    Gradient(colors: [woodLight, wood,
                                      Color(red: 0.48, green: 0.25, blue: 0.09)]),
                    startPoint: CGPoint(x: post.minX, y: 0),
                    endPoint: CGPoint(x: post.maxX, y: 0)))
        sign.stroke(Path(roundedRect: post, cornerRadius: 3 * scale),
                    with: .color(woodDark.opacity(0.82)), lineWidth: 1.25 * scale)

        var postGrain = Path()
        postGrain.move(to: CGPoint(x: -1.8 * scale,
                                   y: -boardHeight / 2 - 5 * scale))
        postGrain.addQuadCurve(to: CGPoint(x: 1.2 * scale,
                                           y: boardHeight / 2 + 24 * scale),
                               control: CGPoint(x: 3.2 * scale, y: 4 * scale))
        sign.stroke(postGrain, with: .color(woodDark.opacity(0.24)),
                    style: StrokeStyle(lineWidth: 0.8 * scale,
                                       lineCap: .round))

        let board = answerBoardPath(width: boardWidth, height: boardHeight,
                                    scale: scale)
        var underside = sign
        underside.translateBy(x: 0.7 * scale, y: 3.2 * scale)
        underside.fill(board, with: .color(woodDark.opacity(0.92)))

        sign.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.27), radius: 3.2 * scale,
                                    x: 1.2 * scale, y: 3.2 * scale))
            layer.fill(board,
                       with: .linearGradient(
                        Gradient(stops: [
                            .init(color: Color(red: 0.98, green: 0.76, blue: 0.45),
                                  location: 0),
                            .init(color: woodLight, location: 0.24),
                            .init(color: Color(red: 0.86, green: 0.56, blue: 0.27),
                                  location: 0.73),
                            .init(color: Color(red: 0.69, green: 0.37, blue: 0.14),
                                  location: 1)
                        ]),
                        startPoint: CGPoint(x: 0, y: -boardHeight / 2),
                        endPoint: CGPoint(x: 0, y: boardHeight / 2)))
        }
        sign.stroke(board, with: .color(woodDark.opacity(0.88)),
                    style: StrokeStyle(lineWidth: 1.7 * scale,
                                       lineJoin: .round))

        var topBevel = Path()
        topBevel.move(to: CGPoint(x: -boardWidth / 2 + 7 * scale,
                                  y: -boardHeight / 2 + 3.2 * scale))
        topBevel.addQuadCurve(to: CGPoint(x: boardWidth / 2 - 7 * scale,
                                          y: -boardHeight / 2 + 3.7 * scale),
                              control: CGPoint(x: 0,
                                               y: -boardHeight / 2 + 1.2 * scale))
        sign.stroke(topBevel, with: .color(Color.white.opacity(0.30)),
                    style: StrokeStyle(lineWidth: 1.25 * scale,
                                       lineCap: .round))

        var bottomBevel = Path()
        bottomBevel.move(to: CGPoint(x: -boardWidth / 2 + 7 * scale,
                                     y: boardHeight / 2 - 3 * scale))
        bottomBevel.addQuadCurve(to: CGPoint(x: boardWidth / 2 - 7 * scale,
                                             y: boardHeight / 2 - 3.3 * scale),
                                 control: CGPoint(x: 0,
                                                  y: boardHeight / 2 - 1.2 * scale))
        sign.stroke(bottomBevel, with: .color(woodDark.opacity(0.30)),
                    style: StrokeStyle(lineWidth: 1.1 * scale,
                                       lineCap: .round))

        let grainLines: [(CGFloat, CGFloat, CGFloat)] = [
            (-13, -1.5, 0.17), (-5, 1.2, 0.12),
            (7, -1.0, 0.14), (14, 1.0, 0.18)
        ]
        for (y, bend, alpha) in grainLines {
            var grain = Path()
            grain.move(to: CGPoint(x: -boardWidth / 2 + 7 * scale,
                                   y: y * scale))
            grain.addQuadCurve(to: CGPoint(x: boardWidth / 2 - 8 * scale,
                                           y: (y + bend * 0.45) * scale),
                               control: CGPoint(x: -2 * scale,
                                                y: (y + bend) * scale))
            sign.stroke(grain, with: .color(woodDark.opacity(alpha)),
                        style: StrokeStyle(lineWidth: 0.75 * scale,
                                           lineCap: .round))
        }

        let fasteners: [CGPoint] = [
            CGPoint(x: -boardWidth / 2 + 7 * scale,
                    y: -boardHeight / 2 + 7 * scale),
            CGPoint(x: boardWidth / 2 - 7 * scale,
                    y: -boardHeight / 2 + 7 * scale),
            CGPoint(x: -boardWidth / 2 + 8 * scale,
                    y: boardHeight / 2 - 7 * scale),
            CGPoint(x: boardWidth / 2 - 8 * scale,
                    y: boardHeight / 2 - 7 * scale)
        ]
        for point in fasteners {
            sign.fill(Path(ellipseIn: CGRect(x: point.x - 1.3 * scale,
                                             y: point.y - 1.3 * scale,
                                             width: 2.6 * scale,
                                             height: 2.6 * scale)),
                      with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(0.55), woodDark]),
                        center: point,
                        startRadius: 0,
                        endRadius: 1.5 * scale))
        }

        var crack = Path()
        crack.move(to: CGPoint(x: -boardWidth / 2 + 5 * scale,
                               y: -boardHeight / 2 + 10 * scale))
        crack.addLine(to: CGPoint(x: -boardWidth / 2 + 11 * scale,
                                  y: -boardHeight / 2 + 12 * scale))
        crack.addLine(to: CGPoint(x: -boardWidth / 2 + 15 * scale,
                                  y: -boardHeight / 2 + 9 * scale))
        sign.stroke(crack, with: .color(woodDark.opacity(0.38)),
                    style: StrokeStyle(lineWidth: 0.85 * scale,
                                       lineCap: .round,
                                       lineJoin: .round))

        // Dutch is the only alternate copy requested for now; every other app
        // language deliberately receives the English fallback.
        let lines = languageCode == "nl"
            ? ["Pak het juiste", "antwoord!"]
            : ["Grab the right", "answer!"]
        for (index, line) in lines.enumerated() {
            var resolved = sign.resolve(
                Text(line)
                    .font(.system(size: 8.9 * scale,
                                  weight: .black, design: .rounded))
                    .foregroundColor(woodDark)
            )
            resolved.shading = .color(woodDark)
            var textShadow = resolved
            textShadow.shading = .color(Color.black.opacity(0.20))
            let textPoint = CGPoint(x: -7.5 * scale,
                                    y: (CGFloat(index) * 12 - 5.8) * scale)
            sign.draw(textShadow,
                      at: CGPoint(x: textPoint.x + 0.65 * scale,
                                  y: textPoint.y + 0.75 * scale),
                      anchor: .center)
            sign.draw(resolved,
                      at: textPoint,
                      anchor: .center)
        }

        drawCarrot(context: sign,
                   at: CGPoint(x: boardWidth / 2 - 13.5 * scale, y: 3 * scale),
                   scale: 0.54 * scale,
                   rotation: .degrees(24))

        // Foreground blades overlap the bottom of the stake so it reads as
        // planted in the same lush turf as the reference sign.
        drawSignGrass(context: sign, baseY: grassY - centre.y,
                      scale: scale)
    }

    private func drawSignGrass(context: GraphicsContext, baseY: CGFloat,
                               scale: CGFloat) {
        let grassDark = Color(red: 0.16, green: 0.43, blue: 0.075)
        let grassMid = Color(red: 0.29, green: 0.66, blue: 0.12)
        let grassLight = Color(red: 0.51, green: 0.79, blue: 0.19)

        // Long side blades establish the playful outward fan first.
        let sideBlades: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-10, -29, 15, -2), (-6, -22, 19, 1),
            (7, 24, 18, -1), (11, 31, 14, 2)
        ]
        for (index, blade) in sideBlades.enumerated() {
            let startX = blade.0 * scale
            let tipX = blade.1 * scale
            let tipY = baseY - blade.2 * scale
            let base = baseY + blade.3 * scale
            var leaf = Path()
            leaf.move(to: CGPoint(x: startX - 1.3 * scale, y: base))
            leaf.addQuadCurve(to: CGPoint(x: tipX, y: tipY),
                              control: CGPoint(x: (startX + tipX) * 0.42,
                                               y: base - blade.2 * 0.34 * scale))
            leaf.addQuadCurve(to: CGPoint(x: startX + 1.3 * scale, y: base),
                              control: CGPoint(x: (startX + tipX) * 0.66,
                                               y: base - blade.2 * 0.24 * scale))
            leaf.closeSubpath()
            context.fill(leaf,
                         with: .color((index.isMultiple(of: 2) ? grassMid : grassDark)
                            .opacity(0.96)))
            context.stroke(leaf, with: .color(grassDark.opacity(0.72)),
                           lineWidth: 0.45 * scale)
        }

        // Soft clumps hide the perfectly straight meeting point of wood and
        // ground before the finer front row is added.
        for (x, width, height) in [
            (-18, 18, 6), (-7, 17, 7), (5, 19, 7), (17, 17, 6)
        ] as [(CGFloat, CGFloat, CGFloat)] {
            let rect = CGRect(x: (x - width / 2) * scale,
                              y: baseY - height * 0.55 * scale,
                              width: width * scale, height: height * scale)
            context.fill(Path(ellipseIn: rect),
                         with: .color(grassDark.opacity(0.90)))
        }

        // Dense irregular blades wrap the pole. Their lean increases toward
        // both sides so the centre stays upright while the silhouette fans out.
        for index in 0..<23 {
            let x = (CGFloat(index) - 11) * 2.15 * scale
            let side: CGFloat = x < 0 ? -1 : 1
            let distance = abs(CGFloat(index) - 11) / 11
            let height = (7 + CGFloat((index * 7) % 8) + distance * 3) * scale
            let lean = side * (1.2 + distance * 6.5) * scale
                + CGFloat(sin(Double(index) * 1.7)) * 1.3 * scale
            let base = baseY + CGFloat((index * 5) % 3) * scale
            let halfWidth = (0.65 + CGFloat(index % 3) * 0.18) * scale
            var blade = Path()
            blade.move(to: CGPoint(x: x - halfWidth, y: base))
            blade.addQuadCurve(to: CGPoint(x: x + lean, y: base - height),
                               control: CGPoint(x: x + lean * 0.18,
                                                y: base - height * 0.53))
            blade.addQuadCurve(to: CGPoint(x: x + halfWidth, y: base),
                               control: CGPoint(x: x + lean * 0.72,
                                                y: base - height * 0.38))
            blade.closeSubpath()
            let color: Color
            switch index % 4 {
            case 0: color = grassLight
            case 1: color = grassDark
            default: color = grassMid
            }
            context.fill(blade, with: .color(color.opacity(0.98)))
        }

        // A few tiny highlights across the front keep the clump from becoming
        // one dark mass at phone size.
        for index in 0..<7 {
            let x = (CGFloat(index) - 3) * 5.2 * scale
            var shoot = Path()
            shoot.move(to: CGPoint(x: x, y: baseY + 0.5 * scale))
            shoot.addQuadCurve(to: CGPoint(x: x + (index.isMultiple(of: 2) ? -2 : 2) * scale,
                                           y: baseY - (7 + CGFloat(index % 3) * 2) * scale),
                               control: CGPoint(x: x + 1.5 * scale,
                                                y: baseY - 4 * scale))
            context.stroke(shoot, with: .color(grassLight.opacity(0.88)),
                           style: StrokeStyle(lineWidth: 1.0 * scale,
                                              lineCap: .round))
        }
    }

    private func answerBoardPath(width: CGFloat, height: CGFloat,
                                 scale: CGFloat) -> Path {
        var board = Path()
        board.move(to: CGPoint(x: -width / 2 + 7 * scale,
                               y: -height / 2 + 0.8 * scale))
        board.addQuadCurve(to: CGPoint(x: width / 2 - 6 * scale,
                                       y: -height / 2 + 1.8 * scale),
                           control: CGPoint(x: 1 * scale,
                                            y: -height / 2 - 1.2 * scale))
        board.addQuadCurve(to: CGPoint(x: width / 2 - 0.5 * scale,
                                       y: -height / 2 + 7 * scale),
                           control: CGPoint(x: width / 2 + 1.5 * scale,
                                            y: -height / 2 + 2.5 * scale))
        board.addQuadCurve(to: CGPoint(x: width / 2 - 1.8 * scale,
                                       y: height / 2 - 6 * scale),
                           control: CGPoint(x: width / 2 + 1.8 * scale, y: 1 * scale))
        board.addQuadCurve(to: CGPoint(x: width / 2 - 7 * scale,
                                       y: height / 2 - 0.5 * scale),
                           control: CGPoint(x: width / 2 - 1 * scale,
                                            y: height / 2 + 1.3 * scale))
        board.addQuadCurve(to: CGPoint(x: -width / 2 + 6 * scale,
                                       y: height / 2 - 1.2 * scale),
                           control: CGPoint(x: -2 * scale,
                                            y: height / 2 + 1.6 * scale))
        board.addQuadCurve(to: CGPoint(x: -width / 2 + 0.7 * scale,
                                       y: height / 2 - 7 * scale),
                           control: CGPoint(x: -width / 2 - 1.6 * scale,
                                            y: height / 2 - 1.5 * scale))
        board.addQuadCurve(to: CGPoint(x: -width / 2 + 1.5 * scale,
                                       y: -height / 2 + 7 * scale),
                           control: CGPoint(x: -width / 2 - 1.5 * scale, y: 0))
        board.addQuadCurve(to: CGPoint(x: -width / 2 + 7 * scale,
                                       y: -height / 2 + 0.8 * scale),
                           control: CGPoint(x: -width / 2 + 2 * scale,
                                            y: -height / 2 + 1 * scale))
        board.closeSubpath()
        return board
    }

    private func drawCarrot(context: GraphicsContext, at point: CGPoint,
                            scale: CGFloat, rotation: Angle) {
        var carrot = context
        carrot.translateBy(x: point.x, y: point.y)
        carrot.rotate(by: rotation)
        let point = CGPoint.zero
        var body = Path()
        body.move(to: CGPoint(x: point.x - 6 * scale, y: point.y - 8 * scale))
        body.addQuadCurve(to: CGPoint(x: point.x + 7 * scale, y: point.y - 5 * scale),
                          control: CGPoint(x: point.x + 2 * scale, y: point.y - 12 * scale))
        body.addQuadCurve(to: CGPoint(x: point.x - 2 * scale, y: point.y + 15 * scale),
                          control: CGPoint(x: point.x + 5 * scale, y: point.y + 7 * scale))
        body.addQuadCurve(to: CGPoint(x: point.x - 6 * scale, y: point.y - 8 * scale),
                          control: CGPoint(x: point.x - 7 * scale, y: point.y + 3 * scale))
        body.closeSubpath()
        carrot.drawLayer { layer in
            layer.addFilter(.shadow(color: .black.opacity(0.23),
                                    radius: 1.2 * scale,
                                    x: 0.8 * scale, y: 1.2 * scale))
            layer.fill(body, with: .linearGradient(
                Gradient(colors: [Color(red: 1.0, green: 0.70, blue: 0.10),
                                  Color(red: 0.98, green: 0.42, blue: 0.035),
                                  Color(red: 0.82, green: 0.22, blue: 0.025)]),
                startPoint: CGPoint(x: point.x - 5 * scale, y: point.y - 8 * scale),
                endPoint: CGPoint(x: point.x + 3 * scale, y: point.y + 14 * scale)))
        }
        carrot.stroke(body,
                      with: .color(Color(red: 0.58, green: 0.17, blue: 0.025)),
                      lineWidth: 1.15 * scale)

        var carrotGlint = Path()
        carrotGlint.move(to: CGPoint(x: -3.7 * scale, y: -5.5 * scale))
        carrotGlint.addQuadCurve(to: CGPoint(x: -1.4 * scale, y: 3.5 * scale),
                                 control: CGPoint(x: -4.5 * scale, y: 0))
        carrot.stroke(carrotGlint, with: .color(Color.white.opacity(0.34)),
                      style: StrokeStyle(lineWidth: 1.0 * scale,
                                         lineCap: .round))

        for (index, shift) in ([-4, 0, 4] as [CGFloat]).enumerated() {
            var leaf = Path()
            leaf.move(to: CGPoint(x: point.x + shift * 0.35 * scale,
                                  y: point.y - 7 * scale))
            leaf.addQuadCurve(to: CGPoint(x: point.x + shift * scale,
                                          y: point.y - 16 * scale),
                              control: CGPoint(x: point.x + shift * 1.2 * scale,
                                               y: point.y - 11 * scale))
            leaf.addQuadCurve(to: CGPoint(x: point.x + shift * 0.35 * scale,
                                          y: point.y - 7 * scale),
                              control: CGPoint(x: point.x + shift * 0.15 * scale,
                                               y: point.y - 12 * scale))
            let leafColor = index == 1
                ? Color(red: 0.30, green: 0.68, blue: 0.16)
                : Color(red: 0.20, green: 0.54, blue: 0.11)
            carrot.fill(leaf, with: .color(leafColor))
            carrot.stroke(leaf, with: .color(Color(red: 0.12, green: 0.38, blue: 0.08)
                .opacity(0.72)), lineWidth: 0.55 * scale)
        }
    }
}

// MARK: - Crane

private struct CraneRig: View {
    let isPad: Bool
    let surface: CGRect
    let fieldSize: CGSize
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
    /// not make the supposedly stationary machine slide vertically.
    private var groundAnchor: UnitPoint {
        UnitPoint(x: boom.x / max(1, fieldSize.width),
                  y: (surface.maxY + RabbitHoleCraneLayout.trackSink(isPad: isPad))
                    / max(1, fieldSize.height))
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
        let flipAnchor = UnitPoint(x: canvasCenter.x / max(1, fieldSize.width),
                                   y: canvasCenter.y / max(1, fieldSize.height))
        let extra = max(0, hypot(hook.x - boom.x, hook.y - boom.y)
                        - RabbitHoleCraneLayout.restHang(isPad: isPad))
        let clawGlue = CGPoint(x: pose.glue.x + downX * extra,
                               y: pose.glue.y + downY * extra)

        ZStack {
            ZStack {
                extensionRods(from: pose.glue, to: clawGlue)

                cabStack(size: canvasSize)
                    .position(x: canvasCenter.x, y: canvasCenter.y)

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
            .shadow(color: .black.opacity(0.22), radius: 8, y: 5)
        }
        .frame(width: fieldSize.width, height: fieldSize.height)
        .offset(x: slide + travelX, y: -hop)
        .allowsHitTesting(false)
    }

    /// Main body, then the stick, then the operator arm — all on the shared canvas.
    private func cabStack(size: CGSize) -> some View {
        let throwAngle = RabbitHoleCraneLayout.joystickThrowDegrees * (1 - Double(reach))
        let armShift = RabbitHoleCraneLayout.armSlide
            * RabbitHoleCraneLayout.canvasScale(isPad: isPad)
            * reach
        return ZStack {
            Image("main_no_arm")
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
            Image("joystick_pre")
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .rotationEffect(.degrees(throwAngle),
                                anchor: RabbitHoleCraneLayout.joystickPivot)
            Image("arm_pre")
                .resizable()
                .interpolation(.high)
                .frame(width: size.width, height: size.height)
                .offset(x: armShift)
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

// MARK: - Carrot

private struct AnswerCarrotView: View {
    let text: String
    let isPad: Bool
    var scale: CGFloat = 1
    var spin: Double = 0
    var opacity: Double = 1

    private var height: CGFloat {
        GameConfig.rabbitHoleDisplayedItemLength(isPad: isPad) * scale
    }
    private var width: CGFloat { height * (530.0 / 677.0) }

    var body: some View {
        ZStack {
            Image("carrot")
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.28), radius: 5, y: 3)

            Text(verbatim: text)
                .font(.system(size: height * 0.20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(width: width * 0.70)
                .shadow(color: .black.opacity(0.62), radius: 1, y: 1)
                .offset(y: height * 0.12)
        }
        .frame(width: width, height: height)
        .rotationEffect(.degrees(spin))
        .opacity(opacity)
        .accessibilityHidden(true)
    }
}

// MARK: - Dynamite

private struct DynamiteStickView: View {
    let item: RabbitHoleItem
    let seconds: Double
    let isPad: Bool
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
                                 bombRotation: item.spin)
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
                        .fill(
                            LinearGradient(colors: [
                                Color(red: 1.00, green: 0.96, blue: 0.88),
                                Color(red: 0.98, green: 0.90, blue: 0.76)
                            ], startPoint: .top, endPoint: .bottom)
                        )
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
