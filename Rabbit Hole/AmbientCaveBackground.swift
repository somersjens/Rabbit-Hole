//
//  AmbientCaveBackground.swift
//  Rabbit Hole
//
//  A menu version of the underground: looking up a rabbit hole at a grass-rimmed
//  opening, with dirt walls, hanging roots, rocks and drifting grit. The centre
//  stays light enough for copy; the scenery lives in the edges, ceiling and floor.
//

import SwiftUI

struct AmbientCaveBackground: View {
    let character: AnimalCharacter
    var showsCaveFloor = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var atmosphere: CaveAtmosphere { CaveAtmosphere(character: character) }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                atmosphere.air

                AmbientCaveScene(atmosphere: atmosphere, showsFloor: showsCaveFloor)
                    .frame(width: size.width, height: size.height)

                AmbientDaylightShafts(paused: reduceMotion)
                    .opacity(0.22)

                TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: reduceMotion)) { timeline in
                    let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    AmbientGritField(phase: phase, size: size, lit: atmosphere.gritLit, dust: atmosphere.grit)
                }

                // Lighten the reading area without flattening the walls and floor.
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 24,
                    endRadius: max(size.width, size.height) * 0.58
                )
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Character-tinted soil. The air in the middle still carries the animal's
/// colour; the walls and floor are mostly earth, with just enough of that
/// colour mixed in that a bunny cave and a dog cave do not look the same.
private struct CaveAtmosphere {
    typealias RGB = (Double, Double, Double)

    let air: Color
    let skyTop: Color
    let skyLip: Color
    let earth: Color
    let earthMid: Color
    let earthDeep: Color
    let rock: Color
    let rockLight: Color
    let root: Color
    let grit: Color
    let gritLit: Color
    let grassLight: Color
    let grassMid: Color
    let grassDeep: Color
    let grassGlow: Color

    private static let soilLight: RGB = (0.72, 0.50, 0.30)
    private static let soilMid: RGB = (0.50, 0.32, 0.18)
    private static let soilDeep: RGB = (0.22, 0.12, 0.08)

    init(character: AnimalCharacter) {
        air = Self.mix(character.tintRGB, Self.soilLight, 0.38)
        skyTop = Color(red: 0.42, green: 0.82, blue: 1.00)
        skyLip = Self.mix(character.skyRGB, (0.72, 0.90, 0.98), 0.55)
        earth = Self.mix(Self.soilMid, character.tintRGB, 0.28)
        earthMid = Self.mix(Self.soilMid, character.deepRGB, 0.22)
        earthDeep = Self.mix(Self.soilDeep, character.deepRGB, 0.18)
        rock = Self.mix((0.30, 0.22, 0.16), character.deepRGB, 0.22)
        rockLight = Self.mix((0.48, 0.36, 0.24), character.tintRGB, 0.18)
        root = Color(red: 0.38, green: 0.22, blue: 0.10)
        grit = Self.mix(character.tintRGB, Self.soilLight, 0.45)
        gritLit = Color(red: 1.00, green: 0.95, blue: 0.72)
        grassLight = Color(red: 0.58, green: 0.90, blue: 0.28)
        grassMid = Color(red: 0.34, green: 0.74, blue: 0.16)
        grassDeep = Color(red: 0.16, green: 0.50, blue: 0.10)
        grassGlow = Color(red: 0.74, green: 0.95, blue: 0.36)
    }

    private static func mix(_ a: RGB, _ b: RGB, _ t: Double) -> Color {
        Color(red: a.0 + (b.0 - a.0) * t,
              green: a.1 + (b.1 - a.1) * t,
              blue: a.2 + (b.2 - a.2) * t)
    }
}

private struct AmbientCaveScene: View {
    let atmosphere: CaveAtmosphere
    let showsFloor: Bool

    var body: some View {
        Canvas { context, size in
            guard size.width > 8, size.height > 8 else { return }
            CaveSceneRenderer(atmosphere: atmosphere,
                              size: size,
                              showsFloor: showsFloor)
                .draw(in: &context)
        }
    }
}

private struct CaveSceneRenderer {
    let atmosphere: CaveAtmosphere
    let size: CGSize
    let showsFloor: Bool

    private var opening: CGRect {
        // Same width as the shaft: the hole sits on the inner faces of the
        // rock walls (with a slight overlap so they clip the circle).
        let left = wallInnerX(y: 0, isLeft: true)
        let right = wallInnerX(y: 0, isLeft: false)
        let overlap = size.width * 0.025
        let holeWidth = (right - left) + overlap * 2
        return CGRect(x: left - overlap,
                      y: -size.height * 0.08,
                      width: holeWidth,
                      height: size.height * 0.20)
    }

    func draw(in context: inout GraphicsContext) {
        drawSky(in: &context)
        drawOpeningGlow(in: &context)
        drawWalls(in: &context)
        drawCeiling(in: &context)
        drawGrassRim(in: &context)
        drawWallStrata(in: &context)
        drawWallRocks(in: &context)
        drawHangingRoots(in: &context)
        if showsFloor {
            drawFloor(in: &context)
        }
    }

    // MARK: Opening

    private func drawSky(in context: inout GraphicsContext) {
        context.fill(
            Path(ellipseIn: opening),
            with: .linearGradient(
                Gradient(colors: [atmosphere.skyTop, atmosphere.skyLip]),
                startPoint: CGPoint(x: opening.midX, y: opening.minY),
                endPoint: CGPoint(x: opening.midX, y: opening.maxY)
            )
        )
    }

    private func drawOpeningGlow(in context: inout GraphicsContext) {
        let center = CGPoint(x: opening.midX, y: opening.maxY * 0.45)
        let radius = max(size.width * 0.42, size.height * 0.38)
        let glow = Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius * 0.35,
            width: radius * 2,
            height: radius * 2.4
        ))
        context.fill(
            glow,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 1.00, green: 0.97, blue: 0.76).opacity(0.38), location: 0),
                    .init(color: Color(red: 1.00, green: 0.94, blue: 0.68).opacity(0.14), location: 0.32),
                    .init(color: Color.clear, location: 1)
                ]),
                center: center,
                startRadius: 6,
                endRadius: radius
            )
        )
    }

    private func drawGrassRim(in context: inout GraphicsContext) {
        let rx = opening.width / 2
        let ry = opening.height / 2
        let cx = opening.midX
        let cy = opening.midY

        var sod = Path()
        let steps = 22
        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let angle = CGFloat.pi * (0.12 + 0.76 * t)
            let x = cx + cos(angle) * rx
            let y = cy + sin(angle) * ry
            if index == 0 { sod.move(to: CGPoint(x: x, y: y + 5)) }
            else { sod.addLine(to: CGPoint(x: x, y: y + 5)) }
        }
        for index in (0...steps).reversed() {
            let t = CGFloat(index) / CGFloat(steps)
            let angle = CGFloat.pi * (0.12 + 0.76 * t)
            let x = cx + cos(angle) * (rx + 2)
            let y = cy + sin(angle) * (ry + 8)
            sod.addLine(to: CGPoint(x: x, y: y))
        }
        sod.closeSubpath()
        context.fill(sod, with: .linearGradient(
            Gradient(colors: [atmosphere.grassLight, atmosphere.grassMid, atmosphere.grassDeep]),
            startPoint: CGPoint(x: cx, y: opening.midY),
            endPoint: CGPoint(x: cx, y: opening.maxY + 12)
        ))

        for index in 0..<14 {
            let t = CGFloat(index) / 13
            let angle = CGFloat.pi * (0.16 + 0.68 * t)
            let root = CGPoint(x: cx + cos(angle) * rx,
                               y: cy + sin(angle) * ry - 1)
            let height: CGFloat = 8 + noise(40 + index) * 9
            let lean = (noise(80 + index) - 0.5) * 7
            let color: Color = index.isMultiple(of: 3)
                ? atmosphere.grassDeep
                : (index.isMultiple(of: 2) ? atmosphere.grassMid : atmosphere.grassLight)
            drawGrassBlade(in: &context, root: root, height: height, lean: lean, color: color)
        }
    }

    private func drawGrassBlade(in context: inout GraphicsContext,
                                root: CGPoint, height: CGFloat,
                                lean: CGFloat, color: Color) {
        let tip = CGPoint(x: root.x + lean, y: root.y - height)
        var blade = Path()
        blade.move(to: CGPoint(x: root.x - 1.5, y: root.y))
        blade.addQuadCurve(to: tip, control: CGPoint(x: root.x - 0.4 + lean * 0.35,
                                                     y: root.y - height * 0.45))
        blade.addQuadCurve(to: CGPoint(x: root.x + 1.5, y: root.y),
                           control: CGPoint(x: root.x + 0.4 + lean * 0.35,
                                            y: root.y - height * 0.45))
        blade.closeSubpath()
        context.fill(blade, with: .color(color.opacity(0.92)))
    }

    // MARK: Walls & ceiling

    private func drawWalls(in context: inout GraphicsContext) {
        let shade = GraphicsContext.Shading.linearGradient(
            Gradient(stops: [
                .init(color: atmosphere.earth, location: 0),
                .init(color: atmosphere.earthMid, location: 0.46),
                .init(color: atmosphere.earthDeep, location: 0.82),
                .init(color: atmosphere.earthMid, location: 1)
            ]),
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: 0, y: size.height)
        )
        context.fill(wallPath(isLeft: true), with: shade)
        context.fill(wallPath(isLeft: false), with: shade)

        for isLeft in [true, false] {
            context.stroke(wallInnerEdge(isLeft: isLeft),
                           with: .color(atmosphere.earthDeep.opacity(0.55)),
                           style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
            context.stroke(wallInnerEdge(isLeft: isLeft),
                           with: .color(atmosphere.earth.opacity(0.35)),
                           style: StrokeStyle(lineWidth: 1.1, lineCap: .round, lineJoin: .round))
        }
    }

    private func drawCeiling(in context: inout GraphicsContext) {
        // Darker soil packed into the top corners around the opening, so the
        // hole reads as a cut through the roof rather than a painted oval.
        for isLeft in [true, false] {
            var cap = Path()
            let outerX: CGFloat = isLeft ? 0 : size.width
            let innerTop = wallInnerX(y: 0, isLeft: isLeft)
            let lipY = opening.maxY + 8
            cap.move(to: CGPoint(x: outerX, y: 0))
            cap.addLine(to: CGPoint(x: innerTop, y: 0))
            cap.addLine(to: CGPoint(x: wallInnerX(y: lipY, isLeft: isLeft), y: lipY))
            cap.addLine(to: CGPoint(x: outerX, y: lipY))
            cap.closeSubpath()
            context.fill(cap, with: .linearGradient(
                Gradient(colors: [atmosphere.earthDeep.opacity(0.55),
                                  atmosphere.earthDeep.opacity(0)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: lipY)
            ))
        }
    }

    private func wallPath(isLeft: Bool) -> Path {
        let steps = max(8, Int(ceil(size.height / 16)))
        var path = Path()
        let outerX: CGFloat = isLeft ? 0 : size.width
        path.move(to: CGPoint(x: outerX, y: 0))
        path.addLine(to: CGPoint(x: wallInnerX(y: 0, isLeft: isLeft), y: 0))
        for index in 1...steps {
            let y = size.height * CGFloat(index) / CGFloat(steps)
            path.addLine(to: CGPoint(x: wallInnerX(y: y, isLeft: isLeft), y: y))
        }
        path.addLine(to: CGPoint(x: outerX, y: size.height))
        path.closeSubpath()
        return path
    }

    private func wallInnerEdge(isLeft: Bool) -> Path {
        let steps = max(8, Int(ceil(size.height / 16)))
        var path = Path()
        for index in 0...steps {
            let y = size.height * CGFloat(index) / CGFloat(steps)
            let point = CGPoint(x: wallInnerX(y: y, isLeft: isLeft), y: y)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    /// Zoomed out: thinner walls so more of the shaft is visible, with a
    /// modest toe where they meet the floor.
    private func wallInnerX(y: CGFloat, isLeft: Bool) -> CGFloat {
        let t = min(1, max(0, y / max(1, size.height)))
        let topWidth = size.width * 0.15
        let midWidth = size.width * 0.09
        let floorWidth = size.width * 0.13
        let width: CGFloat
        if t < 0.22 {
            let u = t / 0.22
            width = topWidth + (midWidth - topWidth) * u
        } else if t < 0.68 {
            width = midWidth
        } else {
            let u = (t - 0.68) / 0.32
            let s = u * u * (3 - 2 * u)
            width = midWidth + (floorWidth - midWidth) * s
        }
        let wave = sin(Double(y) * 0.016 + (isLeft ? 0.62 : 2.18)) * size.width * 0.028
        let ledge = sin(Double(y) * 0.041 + (isLeft ? 1.4 : 0.55)) * size.width * 0.012
        let chip = sin(Double(y) * 0.093 + (isLeft ? 2.1 : 1.05)) * size.width * 0.008
        let offset = CGFloat(wave + ledge + chip)
        if isLeft {
            return min(size.width * 0.18, max(size.width * 0.055, width + offset))
        }
        return max(size.width * 0.82, min(size.width * 0.945, size.width - width - offset))
    }

    // MARK: Wall dressing

    private func drawWallStrata(in context: inout GraphicsContext) {
        let rows = max(10, Int(size.height / 38))
        for row in 0..<rows {
            let y = 18 + CGFloat(row) * (size.height - 36) / CGFloat(max(1, rows - 1))
                + (noise(200 + row) - 0.5) * 10
            for isLeft in [true, false] {
                let edge = wallInnerX(y: y, isLeft: isLeft)
                let inward: CGFloat = isLeft ? -1 : 1
                let startX = edge + inward * (8 + noise(220 + row) * 10)
                let length = size.width * (0.05 + noise(240 + row) * 0.05)
                let endX = startX + inward * length
                var stroke = Path()
                stroke.move(to: CGPoint(x: startX, y: y))
                stroke.addQuadCurve(
                    to: CGPoint(x: endX, y: y + (noise(260 + row) - 0.5) * 7),
                    control: CGPoint(x: (startX + endX) / 2,
                                     y: y - 3 - noise(280 + row) * 5)
                )
                context.stroke(stroke,
                               with: .color(atmosphere.earthDeep.opacity(0.28 + 0.16 * noise(300 + row))),
                               style: StrokeStyle(lineWidth: 1.2 + noise(320 + row) * 2.0,
                                                  lineCap: .round))
            }
        }
    }

    private func drawWallRocks(in context: inout GraphicsContext) {
        let placements: [(CGFloat, CGFloat, CGFloat, Int)] = [
            (0.10, 0.18, 12, 1),
            (0.06, 0.36, 16, 2),
            (0.11, 0.54, 11, 3),
            (0.05, 0.72, 15, 4),
            (0.09, 0.90, 12, 5),
            (0.90, 0.16, 14, 6),
            (0.94, 0.34, 11, 7),
            (0.88, 0.52, 16, 8),
            (0.93, 0.70, 10, 9),
            (0.91, 0.88, 14, 10)
        ]
        for place in placements {
            let centre = CGPoint(x: size.width * place.0, y: size.height * place.1)
            let rock = rockPath(centre: centre, radius: place.2, seed: 400 + place.3)
            context.fill(rock, with: .color(atmosphere.rock.opacity(0.78)))
            context.stroke(rock, with: .color(atmosphere.rockLight.opacity(0.40)),
                           style: StrokeStyle(lineWidth: 1.0, lineJoin: .round))
        }
    }

    private func drawHangingRoots(in context: inout GraphicsContext) {
        let roots: [(Bool, CGFloat, CGFloat, CGFloat, Int)] = [
            (true, 0.14, 22, 34, 1),
            (true, 0.28, 18, 26, 2),
            (true, 0.47, 26, 40, 3),
            (true, 0.63, 16, 24, 4),
            (true, 0.81, 22, 32, 5),
            (false, 0.12, 20, 30, 6),
            (false, 0.31, 24, 36, 7),
            (false, 0.49, 16, 22, 8),
            (false, 0.66, 24, 34, 9),
            (false, 0.84, 18, 28, 10)
        ]
        for root in roots {
            let y = size.height * root.1
            let startX = wallInnerX(y: y, isLeft: root.0)
            let direction: CGFloat = root.0 ? 1 : -1
            let end = CGPoint(x: startX + direction * root.2,
                              y: y + root.3)
            let control = CGPoint(x: startX + direction * root.2 * 0.46,
                                  y: y + root.3 * 0.18)
            var path = Path()
            path.move(to: CGPoint(x: startX, y: y))
            path.addQuadCurve(to: end, control: control)
            context.stroke(path,
                           with: .color(atmosphere.root.opacity(0.62)),
                           style: StrokeStyle(lineWidth: 1.6 + noise(500 + root.4) * 1.1,
                                              lineCap: .round))

            let branchT: CGFloat = 0.58
            let one = 1 - branchT
            let branchStart = CGPoint(
                x: one * one * startX + 2 * one * branchT * control.x + branchT * branchT * end.x,
                y: one * one * y + 2 * one * branchT * control.y + branchT * branchT * end.y
            )
            var branch = Path()
            branch.move(to: branchStart)
            branch.addQuadCurve(
                to: CGPoint(x: branchStart.x + direction * (10 + noise(520 + root.4) * 8),
                            y: branchStart.y + 8 + noise(540 + root.4) * 7),
                control: CGPoint(x: branchStart.x + direction * 4,
                                 y: branchStart.y + 3)
            )
            context.stroke(branch,
                           with: .color(atmosphere.root.opacity(0.48)),
                           style: StrokeStyle(lineWidth: 1.15, lineCap: .round))
        }
    }

    // MARK: Floor

    private func drawFloor(in context: inout GraphicsContext) {
        let floorTop = size.height * 0.88
        var earth = Path()
        earth.move(to: CGPoint(x: 0, y: size.height))
        earth.addLine(to: CGPoint(x: 0, y: floorTop + size.height * 0.04))
        earth.addCurve(
            to: CGPoint(x: size.width * 0.34, y: floorTop),
            control1: CGPoint(x: size.width * 0.10, y: floorTop - size.height * 0.03),
            control2: CGPoint(x: size.width * 0.22, y: floorTop + size.height * 0.05)
        )
        earth.addCurve(
            to: CGPoint(x: size.width * 0.68, y: floorTop + size.height * 0.015),
            control1: CGPoint(x: size.width * 0.48, y: floorTop - size.height * 0.04),
            control2: CGPoint(x: size.width * 0.56, y: floorTop + size.height * 0.05)
        )
        earth.addCurve(
            to: CGPoint(x: size.width, y: floorTop + size.height * 0.03),
            control1: CGPoint(x: size.width * 0.82, y: floorTop - size.height * 0.02),
            control2: CGPoint(x: size.width * 0.92, y: floorTop + size.height * 0.05)
        )
        earth.addLine(to: CGPoint(x: size.width, y: size.height))
        earth.closeSubpath()
        context.fill(earth, with: .linearGradient(
            Gradient(colors: [atmosphere.earth, atmosphere.earthMid, atmosphere.earthDeep]),
            startPoint: CGPoint(x: 0, y: floorTop),
            endPoint: CGPoint(x: 0, y: size.height)
        ))

        var ridge = Path()
        ridge.move(to: CGPoint(x: 0, y: floorTop + size.height * 0.04))
        ridge.addCurve(
            to: CGPoint(x: size.width * 0.34, y: floorTop),
            control1: CGPoint(x: size.width * 0.10, y: floorTop - size.height * 0.03),
            control2: CGPoint(x: size.width * 0.22, y: floorTop + size.height * 0.05)
        )
        ridge.addCurve(
            to: CGPoint(x: size.width * 0.68, y: floorTop + size.height * 0.015),
            control1: CGPoint(x: size.width * 0.48, y: floorTop - size.height * 0.04),
            control2: CGPoint(x: size.width * 0.56, y: floorTop + size.height * 0.05)
        )
        ridge.addCurve(
            to: CGPoint(x: size.width, y: floorTop + size.height * 0.03),
            control1: CGPoint(x: size.width * 0.82, y: floorTop - size.height * 0.02),
            control2: CGPoint(x: size.width * 0.92, y: floorTop + size.height * 0.05)
        )
        context.stroke(ridge, with: .color(atmosphere.earthDeep.opacity(0.40)),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

        let rocks: [(CGFloat, CGFloat, CGFloat, Int)] = [
            (0.10, 0.93, 16, 1),
            (0.18, 0.90, 11, 2),
            (0.28, 0.94, 14, 3),
            (0.40, 0.91, 9, 4),
            (0.60, 0.93, 12, 5),
            (0.72, 0.90, 15, 6),
            (0.82, 0.94, 10, 7),
            (0.91, 0.91, 14, 8)
        ]
        for rock in rocks {
            let centre = CGPoint(x: size.width * rock.0, y: size.height * rock.1)
            let path = rockPath(centre: centre, radius: rock.2, seed: 700 + rock.3)
            context.fill(path, with: .color(atmosphere.rock.opacity(0.82)))
            context.stroke(path, with: .color(atmosphere.rockLight.opacity(0.38)),
                           style: StrokeStyle(lineWidth: 1.0, lineJoin: .round))
        }

        var grit = Path()
        for index in 0..<18 {
            let x = size.width * (0.08 + noise(800 + index) * 0.84)
            let y = size.height * (0.90 + noise(820 + index) * 0.09)
            let w = 2.2 + noise(840 + index) * 4.0
            grit.addEllipse(in: CGRect(x: x, y: y, width: w, height: w * 0.6))
        }
        context.fill(grit, with: .color(atmosphere.earthDeep.opacity(0.40)))

        for index in 0..<4 {
            let x = size.width * (0.12 + CGFloat(index) * 0.24 + noise(900 + index) * 0.04)
            let y = floorTop + 10 + noise(920 + index) * 8
            var crack = Path()
            crack.move(to: CGPoint(x: x, y: y))
            crack.addQuadCurve(
                to: CGPoint(x: x + 18 + noise(940 + index) * 16,
                            y: y + 10 + noise(960 + index) * 8),
                control: CGPoint(x: x + 8, y: y - 4)
            )
            context.stroke(crack, with: .color(atmosphere.earthDeep.opacity(0.34)),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }

        for index in 0..<3 {
            let x = size.width * (0.22 + CGFloat(index) * 0.28)
            let start = CGPoint(x: x, y: floorTop + 6)
            var stub = Path()
            stub.move(to: start)
            stub.addQuadCurve(
                to: CGPoint(x: x + (index.isMultiple(of: 2) ? 10 : -8),
                            y: start.y - 16 - noise(980 + index) * 8),
                control: CGPoint(x: x + 2, y: start.y - 10)
            )
            context.stroke(stub, with: .color(atmosphere.root.opacity(0.50)),
                           style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
        }
    }

    // MARK: Helpers

    private func rockPath(centre: CGPoint, radius: CGFloat, seed: Int) -> Path {
        let pointCount = 7
        var path = Path()
        for index in 0..<pointCount {
            let angle = Double(index) / Double(pointCount) * .pi * 2
                + Double(noise(seed + index)) * 0.18
            let reach = radius * (0.72 + noise(seed + 20 + index) * 0.32)
            let point = CGPoint(
                x: centre.x + CGFloat(cos(angle)) * reach,
                y: centre.y + CGFloat(sin(angle)) * reach * (0.62 + noise(seed + 40 + index) * 0.18)
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private func noise(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + 4.1414) * 43_758.5453
        return CGFloat(value - value.rounded(.down))
    }
}

/// Warm daylight shafts. Driven by Core Animation so the cave canvas does not
/// rebuild when they sway.
private struct AmbientDaylightShafts: View {
    let paused: Bool

    @State private var drifted = false

    private static let leftSway = 27.0
    private static let midSway = 34.0
    private static let rightSway = 41.0

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack(alignment: .top) {
                beam(width: width * 0.38, height: height)
                    .offset(x: width * (drifted ? -0.08 : -0.12), y: -height * 0.14)
                    .animation(sway(Self.leftSway), value: drifted)

                beam(width: width * 0.28, height: height)
                    .offset(x: width * (drifted ? 0.02 : -0.01), y: -height * 0.16)
                    .animation(sway(Self.midSway), value: drifted)

                beam(width: width * 0.32, height: height)
                    .offset(x: width * (drifted ? 0.14 : 0.10), y: -height * 0.12)
                    .animation(sway(Self.rightSway), value: drifted)
            }
            .frame(width: width, height: height, alignment: .top)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white.opacity(0.55), location: 0.35),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .onAppear {
            guard !paused else { return }
            drifted = true
        }
    }

    private func sway(_ halfPeriod: Double) -> Animation {
        .easeInOut(duration: halfPeriod).repeatForever(autoreverses: true)
    }

    private func beam(width: CGFloat, height: CGFloat) -> some View {
        SoftSunbeam()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 1.00, green: 0.97, blue: 0.76).opacity(0.55), location: 0),
                        .init(color: Color(red: 1.00, green: 0.94, blue: 0.68).opacity(0.22), location: 0.22),
                        .init(color: Color(red: 1.00, green: 0.93, blue: 0.60).opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
            .blur(radius: 44)
    }
}

/// A shaft that is narrow at the hole and fans out, so the light has no
/// rectangular sides even before the blur.
private struct SoftSunbeam: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * 0.36
        path.move(to: CGPoint(x: rect.minX + topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct AmbientGritField: View {
    private struct Speck: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        let speed: CGFloat
        let wobble: CGFloat
        let lit: Bool
    }

    let phase: Double
    let size: CGSize
    let lit: Color
    let dust: Color

    private static let specks: [Speck] = [
        .init(id: 0, x: 0.08, y: 0.16, width: 8, height: 5, speed: 2.2, wobble: 7, lit: false),
        .init(id: 1, x: 0.15, y: 0.44, width: 13, height: 7, speed: 3.0, wobble: 10, lit: false),
        .init(id: 2, x: 0.22, y: 0.72, width: 6, height: 4, speed: 1.8, wobble: 5, lit: false),
        .init(id: 3, x: 0.38, y: 0.22, width: 7, height: 4, speed: 2.6, wobble: 8, lit: true),
        .init(id: 4, x: 0.47, y: 0.36, width: 11, height: 6, speed: 2.1, wobble: 6, lit: true),
        .init(id: 5, x: 0.54, y: 0.18, width: 5, height: 3, speed: 3.3, wobble: 5, lit: true),
        .init(id: 6, x: 0.58, y: 0.58, width: 9, height: 5, speed: 2.4, wobble: 9, lit: true),
        .init(id: 7, x: 0.67, y: 0.80, width: 7, height: 4, speed: 1.9, wobble: 6, lit: false),
        .init(id: 8, x: 0.78, y: 0.28, width: 12, height: 6, speed: 2.8, wobble: 8, lit: false),
        .init(id: 9, x: 0.86, y: 0.52, width: 6, height: 4, speed: 3.1, wobble: 7, lit: false),
        .init(id: 10, x: 0.93, y: 0.70, width: 10, height: 5, speed: 2.0, wobble: 9, lit: false),
        .init(id: 11, x: 0.11, y: 0.88, width: 5, height: 3, speed: 2.5, wobble: 4, lit: false),
        .init(id: 12, x: 0.42, y: 0.90, width: 8, height: 4, speed: 2.3, wobble: 6, lit: false),
        .init(id: 13, x: 0.73, y: 0.12, width: 6, height: 4, speed: 2.7, wobble: 5, lit: true)
    ]

    var body: some View {
        ZStack {
            ForEach(Self.specks) { speck in
                let travel = size.height + 90
                let shifted = speck.y * travel + CGFloat(phase) * speck.speed
                let wrapped = shifted.truncatingRemainder(dividingBy: travel)
                let y = wrapped >= 0 ? wrapped : wrapped + travel
                let drift = sin(phase * 0.55 + Double(speck.id) * 1.7) * speck.wobble
                let twinkle = 0.55 + 0.45 * sin(phase * 1.4 + Double(speck.id))

                Ellipse()
                    .fill((speck.lit ? lit : dust).opacity(speck.lit ? 0.55 * twinkle : 0.38))
                    .frame(width: speck.width, height: speck.height)
                    .position(x: speck.x * size.width + drift, y: y)
            }
        }
    }
}
