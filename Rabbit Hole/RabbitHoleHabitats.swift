//
//  RabbitHoleHabitats.swift
//  Rabbit Hole
//
//  Above-ground set dressing for every character except the bunny, whose
//  meadow in RabbitHolePlayfield is the quality reference. Each habitat is
//  a full landscape — background, mid-ground and foreground — built from
//  Canvas paths. The playable centre stays quieter; richness lives at the
//  sides and behind the excavator.
//

import SwiftUI

enum HabitatKind: String, Equatable {
    case bunny, dog, lion, octopus, crab, elephant, bear, fox, frog, penguin

    init(characterID: String) {
        self = HabitatKind(rawValue: characterID) ?? .bunny
    }
}

struct HabitatGroundPalette {
    let lushLight: Color
    let lushMid: Color
    let lushDeep: Color
    let lushGlow: Color
    let sodSoil: Color
    let sodSoilDark: Color
    let sodSoilLight: Color
    let sparseBlades: Bool
}

struct HabitatSkyPalette {
    let top: (Double, Double, Double)
    let mid: (Double, Double, Double)
    let horizon: (Double, Double, Double)
    let sun: (Double, Double, Double)
    /// Share of the sky width. Kept on the right so the sun never sits
    /// under the pause control on the left.
    let sunUnitX: CGFloat
    let sunUnitY: CGFloat
    let sunSize: CGFloat
}

enum HabitatWorld {
    static func ground(for kind: HabitatKind) -> HabitatGroundPalette {
        switch kind {
        case .bunny:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.58, green: 0.90, blue: 0.28),
                lushMid: Color(red: 0.34, green: 0.74, blue: 0.16),
                lushDeep: Color(red: 0.16, green: 0.50, blue: 0.10),
                lushGlow: Color(red: 0.74, green: 0.95, blue: 0.36),
                sodSoil: Color(red: 0.42, green: 0.24, blue: 0.11),
                sodSoilDark: Color(red: 0.22, green: 0.11, blue: 0.05),
                sodSoilLight: Color(red: 0.56, green: 0.34, blue: 0.15),
                sparseBlades: false)
        case .dog:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.40, green: 0.82, blue: 0.52),
                lushMid: Color(red: 0.18, green: 0.62, blue: 0.44),
                lushDeep: Color(red: 0.10, green: 0.44, blue: 0.34),
                lushGlow: Color(red: 0.58, green: 0.92, blue: 0.62),
                sodSoil: Color(red: 0.40, green: 0.26, blue: 0.12),
                sodSoilDark: Color(red: 0.22, green: 0.12, blue: 0.06),
                sodSoilLight: Color(red: 0.54, green: 0.36, blue: 0.16),
                sparseBlades: false)
        case .lion:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.84, green: 0.74, blue: 0.32),
                lushMid: Color(red: 0.70, green: 0.56, blue: 0.22),
                lushDeep: Color(red: 0.50, green: 0.38, blue: 0.14),
                lushGlow: Color(red: 0.92, green: 0.82, blue: 0.42),
                sodSoil: Color(red: 0.58, green: 0.40, blue: 0.18),
                sodSoilDark: Color(red: 0.36, green: 0.22, blue: 0.10),
                sodSoilLight: Color(red: 0.72, green: 0.54, blue: 0.28),
                sparseBlades: true)
        case .octopus:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.56, green: 0.48, blue: 0.78),
                lushMid: Color(red: 0.36, green: 0.40, blue: 0.62),
                lushDeep: Color(red: 0.24, green: 0.22, blue: 0.46),
                lushGlow: Color(red: 0.72, green: 0.64, blue: 0.90),
                sodSoil: Color(red: 0.48, green: 0.42, blue: 0.46),
                sodSoilDark: Color(red: 0.28, green: 0.24, blue: 0.32),
                sodSoilLight: Color(red: 0.62, green: 0.56, blue: 0.60),
                sparseBlades: true)
        case .crab:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.78, green: 0.62, blue: 0.28),
                lushMid: Color(red: 0.62, green: 0.44, blue: 0.16),
                lushDeep: Color(red: 0.46, green: 0.28, blue: 0.10),
                lushGlow: Color(red: 0.90, green: 0.72, blue: 0.38),
                sodSoil: Color(red: 0.90, green: 0.80, blue: 0.56),
                sodSoilDark: Color(red: 0.74, green: 0.60, blue: 0.38),
                sodSoilLight: Color(red: 0.96, green: 0.90, blue: 0.72),
                sparseBlades: true)
        case .elephant:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.46, green: 0.70, blue: 0.48),
                lushMid: Color(red: 0.28, green: 0.52, blue: 0.42),
                lushDeep: Color(red: 0.16, green: 0.36, blue: 0.34),
                lushGlow: Color(red: 0.62, green: 0.82, blue: 0.58),
                sodSoil: Color(red: 0.72, green: 0.58, blue: 0.36),
                sodSoilDark: Color(red: 0.48, green: 0.34, blue: 0.18),
                sodSoilLight: Color(red: 0.84, green: 0.70, blue: 0.46),
                sparseBlades: false)
        case .bear:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.38, green: 0.60, blue: 0.26),
                lushMid: Color(red: 0.26, green: 0.46, blue: 0.18),
                lushDeep: Color(red: 0.14, green: 0.30, blue: 0.12),
                lushGlow: Color(red: 0.50, green: 0.70, blue: 0.34),
                sodSoil: Color(red: 0.36, green: 0.24, blue: 0.14),
                sodSoilDark: Color(red: 0.20, green: 0.12, blue: 0.08),
                sodSoilLight: Color(red: 0.48, green: 0.34, blue: 0.20),
                sparseBlades: false)
        case .fox:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.74, green: 0.56, blue: 0.22),
                lushMid: Color(red: 0.56, green: 0.40, blue: 0.14),
                lushDeep: Color(red: 0.38, green: 0.26, blue: 0.10),
                lushGlow: Color(red: 0.88, green: 0.66, blue: 0.30),
                sodSoil: Color(red: 0.42, green: 0.26, blue: 0.12),
                sodSoilDark: Color(red: 0.24, green: 0.14, blue: 0.06),
                sodSoilLight: Color(red: 0.56, green: 0.36, blue: 0.16),
                sparseBlades: false)
        case .frog:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.46, green: 0.74, blue: 0.28),
                lushMid: Color(red: 0.28, green: 0.54, blue: 0.18),
                lushDeep: Color(red: 0.14, green: 0.36, blue: 0.12),
                lushGlow: Color(red: 0.62, green: 0.84, blue: 0.36),
                sodSoil: Color(red: 0.38, green: 0.28, blue: 0.16),
                sodSoilDark: Color(red: 0.22, green: 0.16, blue: 0.10),
                sodSoilLight: Color(red: 0.50, green: 0.38, blue: 0.22),
                sparseBlades: false)
        case .penguin:
            return HabitatGroundPalette(
                lushLight: Color(red: 0.96, green: 0.98, blue: 1.00),
                lushMid: Color(red: 0.84, green: 0.90, blue: 0.96),
                lushDeep: Color(red: 0.70, green: 0.78, blue: 0.88),
                lushGlow: Color(red: 1.00, green: 1.00, blue: 1.00),
                sodSoil: Color(red: 0.78, green: 0.84, blue: 0.90),
                sodSoilDark: Color(red: 0.52, green: 0.60, blue: 0.70),
                sodSoilLight: Color(red: 0.92, green: 0.95, blue: 0.98),
                sparseBlades: true)
        }
    }

    static func sky(for kind: HabitatKind) -> HabitatSkyPalette {
        switch kind {
        case .bunny:
            return HabitatSkyPalette(
                top: (0.27, 0.76, 1.00), mid: (0.48, 0.86, 1.00),
                horizon: (0.77, 0.94, 0.72), sun: (1.00, 0.92, 0.45),
                sunUnitX: 0.84, sunUnitY: 0.108, sunSize: 64)
        case .dog:
            return HabitatSkyPalette(
                top: (0.30, 0.74, 0.98), mid: (0.52, 0.84, 0.98),
                horizon: (0.82, 0.93, 0.70), sun: (1.00, 0.94, 0.52),
                sunUnitX: 0.82, sunUnitY: 0.100, sunSize: 62)
        case .lion:
            return HabitatSkyPalette(
                top: (0.42, 0.68, 0.92), mid: (0.78, 0.82, 0.62),
                horizon: (0.96, 0.78, 0.42), sun: (1.00, 0.82, 0.28),
                sunUnitX: 0.80, sunUnitY: 0.118, sunSize: 72)
        case .octopus:
            return HabitatSkyPalette(
                top: (0.22, 0.62, 0.88), mid: (0.42, 0.78, 0.92),
                horizon: (0.70, 0.88, 0.86), sun: (1.00, 0.90, 0.62),
                sunUnitX: 0.86, sunUnitY: 0.102, sunSize: 64)
        case .crab:
            return HabitatSkyPalette(
                top: (0.32, 0.72, 0.98), mid: (0.58, 0.86, 0.98),
                horizon: (0.90, 0.88, 0.62), sun: (1.00, 0.90, 0.40),
                sunUnitX: 0.83, sunUnitY: 0.096, sunSize: 66)
        case .elephant:
            return HabitatSkyPalette(
                top: (0.34, 0.70, 0.94), mid: (0.58, 0.82, 0.94),
                horizon: (0.86, 0.90, 0.72), sun: (1.00, 0.93, 0.50),
                sunUnitX: 0.85, sunUnitY: 0.104, sunSize: 62)
        case .bear:
            return HabitatSkyPalette(
                top: (0.28, 0.56, 0.82), mid: (0.52, 0.72, 0.88),
                horizon: (0.78, 0.84, 0.76), sun: (1.00, 0.94, 0.70),
                sunUnitX: 0.87, sunUnitY: 0.092, sunSize: 60)
        case .fox:
            return HabitatSkyPalette(
                top: (0.46, 0.62, 0.86), mid: (0.86, 0.72, 0.52),
                horizon: (0.96, 0.70, 0.40), sun: (1.00, 0.78, 0.32),
                sunUnitX: 0.81, sunUnitY: 0.112, sunSize: 62)
        case .frog:
            return HabitatSkyPalette(
                top: (0.36, 0.72, 0.90), mid: (0.58, 0.84, 0.86),
                horizon: (0.72, 0.90, 0.68), sun: (1.00, 0.95, 0.58),
                sunUnitX: 0.84, sunUnitY: 0.100, sunSize: 62)
        case .penguin:
            return HabitatSkyPalette(
                top: (0.18, 0.36, 0.62), mid: (0.48, 0.64, 0.82),
                horizon: (0.82, 0.88, 0.92), sun: (0.98, 0.96, 0.88),
                sunUnitX: 0.88, sunUnitY: 0.090, sunSize: 58)
        }
    }

    static func drawBackdrop(kind: HabitatKind, context: GraphicsContext,
                             size: CGSize, grassY: CGFloat) {
        guard kind != .bunny else { return }
        switch kind {
        case .octopus: drawOctopus(context, size: size, grassY: grassY)
        case .crab: drawCrab(context, size: size, grassY: grassY)
        case .bear: drawBear(context, size: size, grassY: grassY)
        case .fox: drawFox(context, size: size, grassY: grassY)
        case .frog: drawFrog(context, size: size, grassY: grassY)
        case .penguin: drawPenguin(context, size: size, grassY: grassY)
        case .dog: drawDog(context, size: size, grassY: grassY)
        case .lion: drawLion(context, size: size, grassY: grassY)
        case .elephant: drawElephant(context, size: size, grassY: grassY)
        case .bunny: break
        }
    }

    static func drawLeftProp(kind: HabitatKind, context: GraphicsContext,
                             size: CGSize, grassY: CGFloat, scatter: CGFloat) {
        guard kind != .bunny else { return }
        let scale = HabitatDraw.scale(for: size, grassY: grassY)
        switch kind {
        case .octopus:
            drawOctopusProp(context, size: size, grassY: grassY,
                            scale: scale, scatter: scatter)
        case .crab:
            drawCrabProp(context, size: size, grassY: grassY,
                         scale: scale, scatter: scatter)
        case .bear:
            drawBearProp(context, size: size, grassY: grassY,
                         scale: scale, scatter: scatter)
        case .fox:
            drawFoxProp(context, size: size, grassY: grassY,
                        scale: scale, scatter: scatter)
        case .frog:
            drawFrogProp(context, size: size, grassY: grassY,
                         scale: scale, scatter: scatter)
        case .penguin:
            drawPenguinProp(context, size: size, grassY: grassY,
                            scale: scale, scatter: scatter)
        case .dog:
            drawDogProp(context, size: size, grassY: grassY,
                        scale: scale, scatter: scatter)
        case .lion:
            drawLionProp(context, size: size, grassY: grassY,
                         scale: scale, scatter: scatter)
        case .elephant:
            drawElephantProp(context, size: size, grassY: grassY,
                             scale: scale, scatter: scatter)
        case .bunny: break
        }
    }

    static func drawLipDetails(kind: HabitatKind, context: GraphicsContext,
                               size: CGSize, grassY: CGFloat,
                               holeLeft: CGFloat, holeRight: CGFloat,
                               holeOpen: CGFloat) {
        guard kind != .bunny else { return }
        let scale = HabitatDraw.scale(for: size, grassY: grassY)
        func hidden(_ x: CGFloat) -> Bool {
            holeOpen > 0.18 && x > holeLeft + 8 && x < holeRight - 8
        }
        switch kind {
        case .octopus: drawOctopusLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .crab: drawCrabLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .bear: drawBearLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .fox: drawFoxLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .frog: drawFrogLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .penguin: drawPenguinLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .dog: drawDogLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .lion: drawLionLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .elephant: drawElephantLip(context, size: size, grassY: grassY, scale: scale, hidden: hidden)
        case .bunny: break
        }
    }
}

// MARK: - Shared drawing

enum HabitatDraw {
    static func scale(for width: CGFloat) -> CGFloat {
        max(0.86, min(1.32, width / 390))
    }

    /// Width keeps phone scenery stable; extra sky on iPad lifts the hills
    /// so the above-ground band is not a thin ribbon under a huge empty sky.
    static func scale(for size: CGSize, grassY: CGFloat) -> CGFloat {
        let widthScale = scale(for: size.width)
        let heightScale = min(1.82, max(0.9, grassY / 250))
        if heightScale <= widthScale { return widthScale }
        return min(1.78, widthScale + (heightScale - widthScale) * 0.88)
    }

    static func noise(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898 + 4.1414) * 43_758.5453
        return CGFloat(value - value.rounded(.down))
    }

    static func blown(_ context: GraphicsContext, pivot: CGPoint,
                      direction: CGFloat, scatter: CGFloat,
                      size: CGSize) -> GraphicsContext? {
        if scatter >= 0.98 { return nil }
        guard scatter > 0.001 else { return context }
        let t = scatter
        var blown = context
        let dx = direction * t * (size.width * 0.64 + 40)
        let lift = CGFloat(sin(Double(t) * .pi * 0.78)) * 86 + t * 26
        blown.translateBy(x: pivot.x + dx, y: pivot.y - lift)
        blown.rotate(by: .degrees(Double(direction) * t * (34 + t * 28)))
        blown.translateBy(x: -pivot.x, y: -pivot.y)
        blown.opacity = Double(max(0, 1 - t * 0.7))
        return blown
    }

    static func fillBand(_ context: GraphicsContext, width: CGFloat, bottom: CGFloat,
                         startY: CGFloat,
                         midX: CGFloat, midY: CGFloat, midCX: CGFloat, midCY: CGFloat,
                         endY: CGFloat, endCX: CGFloat, endCY: CGFloat,
                         colors: [Color]) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: startY))
        path.addQuadCurve(to: CGPoint(x: width * midX, y: midY),
                          control: CGPoint(x: width * midCX, y: midCY))
        path.addQuadCurve(to: CGPoint(x: width, y: endY),
                          control: CGPoint(x: width * endCX, y: endCY))
        path.addLine(to: CGPoint(x: width, y: bottom))
        path.addLine(to: CGPoint(x: 0, y: bottom))
        path.closeSubpath()
        let top = min(startY, midY, midCY, endY, endCY)
        context.fill(path, with: .linearGradient(
            Gradient(colors: colors),
            startPoint: CGPoint(x: 0, y: top),
            endPoint: CGPoint(x: 0, y: bottom)))
    }

    static func rock(_ context: GraphicsContext, centre: CGPoint, radius: CGFloat,
                     seed: Int, fill: Color, highlight: Color) {
        let count = 7
        var path = Path()
        for index in 0..<count {
            let angle = Double(index) / Double(count) * .pi * 2
                + Double(noise(seed + index)) * 0.2
            let reach = radius * (0.70 + noise(seed + 20 + index) * 0.34)
            let point = CGPoint(
                x: centre.x + CGFloat(cos(angle)) * reach,
                y: centre.y + CGFloat(sin(angle)) * reach
                    * (0.58 + noise(seed + 40 + index) * 0.22)
            )
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        context.fill(path, with: .linearGradient(
            Gradient(colors: [highlight, fill]),
            startPoint: CGPoint(x: centre.x - radius * 0.4, y: centre.y - radius * 0.5),
            endPoint: CGPoint(x: centre.x + radius * 0.3, y: centre.y + radius * 0.4)))
        context.stroke(path, with: .color(fill.opacity(0.85)),
                       style: StrokeStyle(lineWidth: max(0.8, radius * 0.05), lineJoin: .round))
        context.fill(Path(ellipseIn: CGRect(
            x: centre.x - radius * 0.28, y: centre.y - radius * 0.36,
            width: radius * 0.34, height: radius * 0.18)),
                     with: .color(Color.white.opacity(0.18)))
    }

    static func blade(_ context: GraphicsContext, root: CGPoint, height: CGFloat,
                      lean: CGFloat, halfWidth: CGFloat, color: Color) {
        var path = Path()
        let tip = CGPoint(x: root.x + lean, y: root.y - height)
        path.move(to: CGPoint(x: root.x - halfWidth, y: root.y + 0.6))
        path.addQuadCurve(to: tip,
                          control: CGPoint(x: root.x - halfWidth * 0.2 + lean * 0.3,
                                           y: root.y - height * 0.45))
        path.addQuadCurve(to: CGPoint(x: root.x + halfWidth, y: root.y + 0.6),
                          control: CGPoint(x: root.x + halfWidth * 0.35 + lean * 0.7,
                                           y: root.y - height * 0.35))
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    static func pine(_ context: GraphicsContext, base: CGPoint, height: CGFloat,
                     dusk: CGFloat = 0,
                     ground: HabitatGroundPalette = HabitatWorld.ground(for: .bear)) {
        let trunkW = max(2.4, height * 0.085)
        context.fill(Path(roundedRect: CGRect(x: base.x - trunkW / 2,
                                              y: base.y - height * 0.24,
                                              width: trunkW, height: height * 0.26),
                          cornerRadius: 1),
                     with: .color(Color(red: 0.42, green: 0.28, blue: 0.16)))
        let lift = dusk
        let greens = [
            ground.lushDeep.opacity(0.94 - lift * 0.12),
            ground.lushMid.opacity(0.96 - lift * 0.08),
            ground.lushLight,
            ground.lushGlow
        ]
        for index in 0..<4 {
            let t = CGFloat(index) / 3
            let width = height * (0.62 - t * 0.34)
            let y = base.y - height * (0.16 + t * 0.20)
            var tri = Path()
            tri.move(to: CGPoint(x: base.x, y: y - height * 0.26))
            tri.addLine(to: CGPoint(x: base.x - width / 2, y: y + height * 0.05))
            tri.addLine(to: CGPoint(x: base.x + width / 2, y: y + height * 0.05))
            tri.closeSubpath()
            context.fill(tri, with: .color(greens[index]))
            if index == 3 {
                context.fill(Path(ellipseIn: CGRect(
                    x: base.x - width * 0.12, y: y - height * 0.22,
                    width: width * 0.22, height: height * 0.08)),
                             with: .color(Color.white.opacity(0.16)))
            }
        }
    }

    static func acacia(_ context: GraphicsContext, base: CGPoint, height: CGFloat,
                       ground: HabitatGroundPalette = HabitatWorld.ground(for: .lion)) {
        let trunkW = max(2.2, height * 0.07)
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - trunkW * 0.4, y: base.y))
        trunk.addQuadCurve(to: CGPoint(x: base.x - height * 0.16, y: base.y - height * 0.55),
                           control: CGPoint(x: base.x - trunkW, y: base.y - height * 0.28))
        trunk.addLine(to: CGPoint(x: base.x - height * 0.12, y: base.y - height * 0.55))
        trunk.addQuadCurve(to: CGPoint(x: base.x + trunkW * 0.2, y: base.y),
                           control: CGPoint(x: base.x, y: base.y - height * 0.26))
        trunk.closeSubpath()
        context.fill(trunk, with: .color(Color(red: 0.42, green: 0.28, blue: 0.14)))
        var fork = Path()
        fork.move(to: CGPoint(x: base.x, y: base.y - height * 0.32))
        fork.addQuadCurve(to: CGPoint(x: base.x + height * 0.18, y: base.y - height * 0.58),
                          control: CGPoint(x: base.x + height * 0.06, y: base.y - height * 0.40))
        context.stroke(fork, with: .color(Color(red: 0.42, green: 0.28, blue: 0.14)),
                       style: StrokeStyle(lineWidth: trunkW * 0.7, lineCap: .round))
        let canopy = CGRect(x: base.x - height * 0.48, y: base.y - height * 0.82,
                            width: height * 0.96, height: height * 0.34)
        context.fill(Path(ellipseIn: canopy), with: .linearGradient(
            Gradient(colors: [ground.lushLight, ground.lushDeep]),
            startPoint: CGPoint(x: canopy.midX, y: canopy.minY),
            endPoint: CGPoint(x: canopy.midX, y: canopy.maxY)))
        context.fill(Path(ellipseIn: CGRect(
            x: canopy.minX + canopy.width * 0.18, y: canopy.minY + canopy.height * 0.16,
            width: canopy.width * 0.28, height: canopy.height * 0.28)),
                     with: .color(Color.white.opacity(0.14)))
    }

    static func parkTree(_ context: GraphicsContext, base: CGPoint,
                         height: CGFloat, tint: Double,
                         ground: HabitatGroundPalette = HabitatWorld.ground(for: .dog)) {
        let trunkW = max(2.5, height * 0.075)
        context.fill(Path(roundedRect: CGRect(x: base.x - trunkW / 2,
                                              y: base.y - height * 0.56,
                                              width: trunkW, height: height * 0.58),
                          cornerRadius: trunkW / 2),
                     with: .color(Color(red: 0.50, green: 0.38, blue: 0.22)))
        let leaf = ground.lushLight.opacity(0.92 + tint * 0.08)
        let shade = ground.lushMid.opacity(0.90)
        let crowns: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.20, -0.66, 0.42), (0.18, -0.70, 0.48), (0.00, -0.86, 0.52),
            (-0.28, -0.88, 0.32), (0.28, -0.90, 0.34)
        ]
        for crown in crowns {
            let d = height * crown.2
            let rect = CGRect(x: base.x + height * crown.0 - d / 2,
                              y: base.y + height * crown.1 - d / 2,
                              width: d, height: d * 0.92)
            context.fill(Path(ellipseIn: rect), with: .linearGradient(
                Gradient(colors: [leaf.opacity(0.90), shade.opacity(0.86)]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
        }
    }

    static func autumnTree(_ context: GraphicsContext, base: CGPoint,
                           height: CGFloat, tint: Double) {
        let trunkW = max(2.6, height * 0.08)
        context.fill(Path(roundedRect: CGRect(x: base.x - trunkW / 2,
                                              y: base.y - height * 0.58,
                                              width: trunkW, height: height * 0.60),
                          cornerRadius: trunkW / 2),
                     with: .color(Color(red: 0.38, green: 0.24, blue: 0.14)))
        var branch = Path()
        branch.move(to: CGPoint(x: base.x, y: base.y - height * 0.40))
        branch.addLine(to: CGPoint(x: base.x - height * 0.20, y: base.y - height * 0.58))
        branch.move(to: CGPoint(x: base.x, y: base.y - height * 0.46))
        branch.addLine(to: CGPoint(x: base.x + height * 0.22, y: base.y - height * 0.64))
        context.stroke(branch, with: .color(Color(red: 0.38, green: 0.24, blue: 0.14).opacity(0.7)),
                       style: StrokeStyle(lineWidth: trunkW * 0.45, lineCap: .round))
        let leaf = Color(red: 0.86 + tint * 0.08, green: 0.42 + tint * 0.18, blue: 0.16)
        let shade = Color(red: 0.62 + tint * 0.08, green: 0.26 + tint * 0.10, blue: 0.10)
        let crowns: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.22, -0.68, 0.44), (0.20, -0.72, 0.50), (0.00, -0.88, 0.56),
            (-0.30, -0.90, 0.34), (0.30, -0.92, 0.36)
        ]
        for crown in crowns {
            let d = height * crown.2
            let rect = CGRect(x: base.x + height * crown.0 - d / 2,
                              y: base.y + height * crown.1 - d / 2,
                              width: d, height: d * 0.90)
            context.fill(Path(ellipseIn: rect), with: .linearGradient(
                Gradient(colors: [leaf.opacity(0.92), shade.opacity(0.88)]),
                startPoint: CGPoint(x: rect.midX, y: rect.minY),
                endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
        }
    }

    static func reed(_ context: GraphicsContext, root: CGPoint, height: CGFloat,
                     lean: CGFloat, color: Color) {
        var stem = Path()
        stem.move(to: root)
        stem.addQuadCurve(to: CGPoint(x: root.x + lean, y: root.y - height),
                          control: CGPoint(x: root.x + lean * 0.4,
                                           y: root.y - height * 0.5))
        context.stroke(stem, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.2, height * 0.035), lineCap: .round))
        let head = CGRect(x: root.x + lean - height * 0.045,
                          y: root.y - height - height * 0.12,
                          width: height * 0.09, height: height * 0.16)
        context.fill(Path(ellipseIn: head),
                     with: .color(Color(red: 0.42, green: 0.32, blue: 0.14)))
    }

    static func fern(_ context: GraphicsContext, root: CGPoint, height: CGFloat,
                     side: CGFloat, color: Color) {
        for tooth in 0..<5 {
            let t = CGFloat(tooth) / 4
            let y = root.y - height * (0.15 + t * 0.78)
            let reach = height * (0.22 + (1 - t) * 0.18) * side
            var frond = Path()
            frond.move(to: CGPoint(x: root.x + side * height * 0.02 * t, y: y))
            frond.addQuadCurve(to: CGPoint(x: root.x + reach, y: y - height * 0.08),
                               control: CGPoint(x: root.x + reach * 0.45, y: y + height * 0.02))
            frond.addQuadCurve(to: CGPoint(x: root.x + side * height * 0.04, y: y - height * 0.04),
                               control: CGPoint(x: root.x + reach * 0.55, y: y - height * 0.12))
            context.fill(frond, with: .color(color.opacity(0.88 - t * 0.12)))
        }
        var spine = Path()
        spine.move(to: root)
        spine.addQuadCurve(to: CGPoint(x: root.x + side * height * 0.08, y: root.y - height),
                           control: CGPoint(x: root.x + side * 4, y: root.y - height * 0.5))
        context.stroke(spine, with: .color(color.opacity(0.7)),
                       style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
    }

    static func lilyPad(_ context: GraphicsContext, at point: CGPoint, radius: CGFloat,
                        ground: HabitatGroundPalette = HabitatWorld.ground(for: .frog)) {
        var pad = Path()
        pad.addArc(center: point, radius: radius, startAngle: .degrees(28),
                   endAngle: .degrees(332), clockwise: false)
        pad.addLine(to: point)
        pad.closeSubpath()
        context.fill(pad, with: .linearGradient(
            Gradient(colors: [ground.lushLight, ground.lushDeep]),
            startPoint: CGPoint(x: point.x, y: point.y - radius),
            endPoint: CGPoint(x: point.x, y: point.y + radius)))
        context.stroke(pad, with: .color(ground.lushDeep.opacity(0.55)),
                       lineWidth: 0.8)
    }

    static func seaweed(_ context: GraphicsContext, root: CGPoint, height: CGFloat,
                        lean: CGFloat, color: Color) {
        var path = Path()
        path.move(to: root)
        path.addCurve(to: CGPoint(x: root.x + lean, y: root.y - height),
                      control1: CGPoint(x: root.x + lean * 0.8, y: root.y - height * 0.35),
                      control2: CGPoint(x: root.x - lean * 0.4, y: root.y - height * 0.70))
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: max(1.6, height * 0.06), lineCap: .round))
        var leaf = Path()
        leaf.move(to: CGPoint(x: root.x + lean * 0.3, y: root.y - height * 0.45))
        leaf.addQuadCurve(to: CGPoint(x: root.x + lean * 0.9, y: root.y - height * 0.62),
                          control: CGPoint(x: root.x + lean * 1.1, y: root.y - height * 0.48))
        context.stroke(leaf, with: .color(color.opacity(0.8)),
                       style: StrokeStyle(lineWidth: max(1.1, height * 0.04), lineCap: .round))
    }

    static func shell(_ context: GraphicsContext, at point: CGPoint, size: CGFloat,
                      fill: Color) {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y + size * 0.35))
        path.addQuadCurve(to: CGPoint(x: point.x - size * 0.48, y: point.y - size * 0.05),
                          control: CGPoint(x: point.x - size * 0.42, y: point.y + size * 0.28))
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y - size * 0.48),
                          control: CGPoint(x: point.x - size * 0.22, y: point.y - size * 0.42))
        path.addQuadCurve(to: CGPoint(x: point.x + size * 0.48, y: point.y - size * 0.05),
                          control: CGPoint(x: point.x + size * 0.22, y: point.y - size * 0.42))
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y + size * 0.35),
                          control: CGPoint(x: point.x + size * 0.42, y: point.y + size * 0.28))
        path.closeSubpath()
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(fill.opacity(0.5)), lineWidth: 0.7)
        for index in 0..<4 {
            let t = CGFloat(index + 1) / 5
            var rib = Path()
            rib.move(to: CGPoint(x: point.x, y: point.y + size * 0.22))
            rib.addQuadCurve(to: CGPoint(x: point.x + (t - 0.5) * size * 0.7,
                                         y: point.y - size * 0.18),
                             control: CGPoint(x: point.x + (t - 0.5) * size * 0.2,
                                              y: point.y))
            context.stroke(rib, with: .color(Color.white.opacity(0.35)), lineWidth: 0.6)
        }
    }

    static func driftwood(_ context: GraphicsContext, origin: CGPoint,
                          width: CGFloat, height: CGFloat) {
        var log = Path()
        log.move(to: CGPoint(x: origin.x, y: origin.y + height * 0.55))
        log.addQuadCurve(to: CGPoint(x: origin.x + width * 0.18, y: origin.y),
                         control: CGPoint(x: origin.x + width * 0.04, y: origin.y + height * 0.1))
        log.addQuadCurve(to: CGPoint(x: origin.x + width * 0.92, y: origin.y + height * 0.15),
                         control: CGPoint(x: origin.x + width * 0.55, y: origin.y - height * 0.25))
        log.addQuadCurve(to: CGPoint(x: origin.x + width, y: origin.y + height * 0.7),
                         control: CGPoint(x: origin.x + width * 0.98, y: origin.y + height * 0.35))
        log.addQuadCurve(to: CGPoint(x: origin.x + width * 0.12, y: origin.y + height),
                         control: CGPoint(x: origin.x + width * 0.6, y: origin.y + height * 1.1))
        log.closeSubpath()
        let wood = Color(red: 0.55, green: 0.38, blue: 0.22)
        let dark = Color(red: 0.32, green: 0.20, blue: 0.10)
        context.fill(log, with: .linearGradient(
            Gradient(colors: [Color(red: 0.70, green: 0.52, blue: 0.32), wood, dark]),
            startPoint: CGPoint(x: origin.x, y: origin.y),
            endPoint: CGPoint(x: origin.x, y: origin.y + height)))
        context.stroke(log, with: .color(dark.opacity(0.55)), lineWidth: 1.1)
        var knot = Path(ellipseIn: CGRect(x: origin.x + width * 0.42,
                                          y: origin.y + height * 0.32,
                                          width: height * 0.28, height: height * 0.22))
        context.fill(knot, with: .color(dark.opacity(0.45)))
    }

    static func iceChunk(_ context: GraphicsContext, base: CGPoint, height: CGFloat,
                         width: CGFloat) {
        var berg = Path()
        berg.move(to: CGPoint(x: base.x - width * 0.48, y: base.y))
        berg.addLine(to: CGPoint(x: base.x - width * 0.22, y: base.y - height * 0.72))
        berg.addLine(to: CGPoint(x: base.x + width * 0.06, y: base.y - height))
        berg.addLine(to: CGPoint(x: base.x + width * 0.38, y: base.y - height * 0.58))
        berg.addLine(to: CGPoint(x: base.x + width * 0.50, y: base.y))
        berg.closeSubpath()
        context.fill(berg, with: .linearGradient(
            Gradient(colors: [Color(red: 0.92, green: 0.97, blue: 1.00),
                              Color(red: 0.62, green: 0.78, blue: 0.90)]),
            startPoint: CGPoint(x: base.x, y: base.y - height),
            endPoint: CGPoint(x: base.x, y: base.y)))
        context.stroke(berg, with: .color(Color(red: 0.45, green: 0.62, blue: 0.78).opacity(0.55)),
                       lineWidth: 1.0)
        context.fill(Path(ellipseIn: CGRect(x: base.x - width * 0.12,
                                            y: base.y - height * 0.72,
                                            width: width * 0.16, height: height * 0.12)),
                     with: .color(Color.white.opacity(0.55)))
    }

    static func agilityCone(_ context: GraphicsContext, at point: CGPoint,
                            height: CGFloat) {
        var cone = Path()
        cone.move(to: CGPoint(x: point.x, y: point.y - height))
        cone.addLine(to: CGPoint(x: point.x - height * 0.38, y: point.y))
        cone.addLine(to: CGPoint(x: point.x + height * 0.38, y: point.y))
        cone.closeSubpath()
        context.fill(cone, with: .color(Color(red: 0.96, green: 0.42, blue: 0.12)))
        context.fill(Path(CGRect(x: point.x - height * 0.22, y: point.y - height * 0.42,
                                 width: height * 0.44, height: height * 0.12)),
                     with: .color(Color.white.opacity(0.92)))
        context.fill(Path(ellipseIn: CGRect(x: point.x - height * 0.42, y: point.y - 3,
                                            width: height * 0.84, height: 6)),
                     with: .color(Color(red: 0.86, green: 0.34, blue: 0.10)))
    }

    static func hurdle(_ context: GraphicsContext, origin: CGPoint,
                       width: CGFloat, height: CGFloat) {
        let postW = max(3.2, width * 0.08)
        let wood = Color(red: 0.78, green: 0.78, blue: 0.80)
        let stripe = Color(red: 0.92, green: 0.28, blue: 0.16)
        for x in [origin.x, origin.x + width] {
            context.fill(Path(roundedRect: CGRect(x: x - postW / 2, y: origin.y - height,
                                                  width: postW, height: height),
                              cornerRadius: 1.2),
                         with: .color(wood))
        }
        let bar = CGRect(x: origin.x - 2, y: origin.y - height * 0.72,
                         width: width + 4, height: height * 0.16)
        context.fill(Path(roundedRect: bar, cornerRadius: 2), with: .color(Color.white))
        for index in 0..<5 {
            if index.isMultiple(of: 2) { continue }
            let slice = bar.width / 5
            context.fill(Path(CGRect(x: bar.minX + CGFloat(index) * slice, y: bar.minY,
                                     width: slice, height: bar.height)),
                         with: .color(stripe))
        }
    }

    static func slalomPole(_ context: GraphicsContext, at point: CGPoint,
                           height: CGFloat, hue: Color) {
        context.fill(Path(roundedRect: CGRect(x: point.x - 2, y: point.y - height,
                                              width: 4, height: height),
                          cornerRadius: 1.5),
                     with: .color(Color(red: 0.85, green: 0.85, blue: 0.88)))
        context.fill(Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - height - 8,
                                            width: 12, height: 12)),
                     with: .color(hue))
        context.fill(Path(ellipseIn: CGRect(x: point.x - 3, y: point.y - height - 6,
                                            width: 4, height: 3)),
                     with: .color(Color.white.opacity(0.45)))
    }

    static func tunnel(_ context: GraphicsContext, origin: CGPoint,
                       width: CGFloat, height: CGFloat) {
        let blue = Color(red: 0.18, green: 0.52, blue: 0.78)
        let light = Color(red: 0.42, green: 0.72, blue: 0.92)
        var arch = Path()
        arch.addRect(CGRect(x: origin.x, y: origin.y - height * 0.55,
                            width: width * 0.18, height: height * 0.55))
        arch.addRect(CGRect(x: origin.x + width * 0.82, y: origin.y - height * 0.55,
                            width: width * 0.18, height: height * 0.55))
        context.fill(arch, with: .color(blue))
        var hood = Path()
        hood.addArc(center: CGPoint(x: origin.x + width / 2, y: origin.y - height * 0.52),
                    radius: width * 0.52, startAngle: .degrees(180),
                    endAngle: .degrees(0), clockwise: false)
        hood.addLine(to: CGPoint(x: origin.x + width * 0.82, y: origin.y - height * 0.52))
        hood.addLine(to: CGPoint(x: origin.x + width * 0.18, y: origin.y - height * 0.52))
        hood.closeSubpath()
        context.fill(hood, with: .linearGradient(
            Gradient(colors: [light, blue]),
            startPoint: CGPoint(x: origin.x, y: origin.y - height),
            endPoint: CGPoint(x: origin.x, y: origin.y - height * 0.4)))
        let mouth = CGRect(x: origin.x + width * 0.22, y: origin.y - height * 0.48,
                           width: width * 0.56, height: height * 0.48)
        context.fill(Path(roundedRect: mouth, cornerRadius: width * 0.12),
                     with: .color(Color(red: 0.08, green: 0.16, blue: 0.28).opacity(0.72)))
        for index in 0..<4 {
            let x = origin.x + width * (0.12 + CGFloat(index) * 0.22)
            context.fill(Path(CGRect(x: x, y: origin.y - height * 0.92,
                                     width: width * 0.08, height: height * 0.18)),
                         with: .color(index.isMultiple(of: 2) ? Color.white.opacity(0.85) : Color(red: 0.94, green: 0.32, blue: 0.18)))
        }
    }
}

// MARK: - Light ambient motion

/// A handful of specks, leaves or sparkles so the habitat breathes. Kept off
/// the main soil canvas so the landscape does not rebuild every frame.
struct HabitatAmbientMotion: View {
    let kind: HabitatKind
    let grassY: CGFloat
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                draw(context: context, size: size, phase: phase)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func draw(context: GraphicsContext, size: CGSize, phase: Double) {
        switch kind {
        case .bunny: pollen(context, size: size, phase: phase)
        case .octopus: sparkles(context, size: size, phase: phase, color: Color(red: 0.70, green: 0.90, blue: 0.96))
        case .crab: motes(context, size: size, phase: phase, color: Color(red: 0.92, green: 0.82, blue: 0.58), speed: 8)
        case .bear: motes(context, size: size, phase: phase, color: Color(red: 0.42, green: 0.36, blue: 0.22), speed: 6)
        case .fox: leaves(context, size: size, phase: phase)
        case .frog: sparkles(context, size: size, phase: phase, color: Color(red: 0.62, green: 0.88, blue: 0.78))
        case .penguin: snow(context, size: size, phase: phase)
        case .dog: motes(context, size: size, phase: phase, color: Color(red: 0.78, green: 0.86, blue: 0.42), speed: 7)
        case .lion: motes(context, size: size, phase: phase, color: Color(red: 0.86, green: 0.72, blue: 0.38), speed: 10)
        case .elephant: sparkles(context, size: size, phase: phase, color: Color(red: 0.70, green: 0.86, blue: 0.90))
        }
    }

    private func pollen(_ context: GraphicsContext, size: CGSize, phase: Double) {
        for index in 0..<6 {
            let xBase = size.width * (0.08 + CGFloat(index) * 0.16)
            if xBase > size.width * 0.32 && xBase < size.width * 0.68 { continue }
            let drift = sin(phase * 0.7 + Double(index) * 1.4) * 10
            let bob = cos(phase * 0.9 + Double(index)) * 6
            let y = grassY - 36 - CGFloat(index % 3) * 14 + bob
            context.fill(Path(ellipseIn: CGRect(x: xBase + drift, y: y, width: 4, height: 4)),
                         with: .color(Color(red: 1.00, green: 0.92, blue: 0.42)
                            .opacity(0.45 + 0.25 * sin(phase * 1.6 + Double(index)))))
        }
    }

    private func sparkles(_ context: GraphicsContext, size: CGSize, phase: Double,
                          color: Color) {
        for index in 0..<7 {
            let x = size.width * (index < 4 ? 0.06 + CGFloat(index) * 0.07 : 0.76 + CGFloat(index - 4) * 0.07)
            let twinkle = 0.25 + 0.55 * max(0, sin(phase * 2.1 + Double(index) * 1.3))
            let y = grassY - 28 - CGFloat(index % 3) * 10
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 3.4, height: 3.4)),
                         with: .color(color.opacity(twinkle)))
        }
    }

    private func motes(_ context: GraphicsContext, size: CGSize, phase: Double,
                       color: Color, speed: Double) {
        for index in 0..<8 {
            let travel = grassY + 40
            let shifted = CGFloat(index) * travel / 8 + CGFloat(phase) * speed
            let wrapped = shifted.truncatingRemainder(dividingBy: travel)
            let y = grassY - (wrapped >= 0 ? wrapped : wrapped + travel)
            let x = size.width * (index.isMultiple(of: 2) ? 0.07 + CGFloat(index) * 0.03 : 0.82 + CGFloat(index % 3) * 0.05)
            let wobble = sin(phase * 0.8 + Double(index)) * 8
            context.fill(Path(ellipseIn: CGRect(x: x + wobble, y: y, width: 3.2, height: 2.2)),
                         with: .color(color.opacity(0.38)))
        }
    }

    private func leaves(_ context: GraphicsContext, size: CGSize, phase: Double) {
        for index in 0..<6 {
            let travel = grassY + 50
            let shifted = CGFloat(index) * 18 + CGFloat(phase) * 11
            let wrapped = shifted.truncatingRemainder(dividingBy: travel)
            let y = (wrapped >= 0 ? wrapped : wrapped + travel) * 0.55
            let xBase = size.width * (index < 3 ? 0.06 + CGFloat(index) * 0.08 : 0.78 + CGFloat(index - 3) * 0.07)
            let wobble = sin(phase * 1.1 + Double(index) * 0.9) * 12
            var leaf = context
            leaf.translateBy(x: xBase + wobble, y: y)
            leaf.rotate(by: .degrees(sin(phase * 1.4 + Double(index)) * 24))
            leaf.fill(Path(ellipseIn: CGRect(x: -5, y: -3, width: 10, height: 6)),
                      with: .color(Color(red: 0.86, green: 0.40, blue: 0.14).opacity(0.72)))
        }
    }

    private func snow(_ context: GraphicsContext, size: CGSize, phase: Double) {
        for index in 0..<12 {
            let travel = grassY + 30
            let shifted = CGFloat(index) * travel / 12 + CGFloat(phase) * (9 + Double(index % 3))
            let wrapped = shifted.truncatingRemainder(dividingBy: travel)
            let y = wrapped >= 0 ? wrapped : wrapped + travel
            let x = size.width * (0.04 + CGFloat(index) * 0.08)
            let drift = sin(phase * 0.6 + Double(index)) * 10
            let flake = 2.4 + CGFloat(index % 3)
            context.fill(Path(ellipseIn: CGRect(x: x + drift, y: y, width: flake, height: flake)),
                         with: .color(Color.white.opacity(0.72)))
        }
    }
}
