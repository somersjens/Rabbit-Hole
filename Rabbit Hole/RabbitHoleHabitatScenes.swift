//
//  RabbitHoleHabitatScenes.swift
//  Rabbit Hole
//
//  One above-ground landscape per animal. Silhouette, vegetation and
//  materials do the differentiating — not a tint of the bunny meadow.
//

import SwiftUI

extension HabitatWorld {
    // MARK: Octopus — rocky coast, tide pools

    static func drawOctopus(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .octopus)

        var sea = Path()
        sea.move(to: CGPoint(x: 0, y: grassY - 78 * s))
        sea.addLine(to: CGPoint(x: size.width, y: grassY - 74 * s))
        sea.addLine(to: CGPoint(x: size.width, y: bottom))
        sea.addLine(to: CGPoint(x: 0, y: bottom))
        sea.closeSubpath()
        context.fill(sea, with: .linearGradient(
            Gradient(colors: [Color(red: 0.22, green: 0.52, blue: 0.68),
                              Color(red: 0.14, green: 0.38, blue: 0.52)]),
            startPoint: CGPoint(x: 0, y: grassY - 78 * s),
            endPoint: CGPoint(x: 0, y: bottom)))

        var horizon = Path()
        horizon.move(to: CGPoint(x: 0, y: grassY - 78 * s))
        horizon.addQuadCurve(to: CGPoint(x: size.width, y: grassY - 74 * s),
                             control: CGPoint(x: size.width * 0.5, y: grassY - 84 * s))
        context.stroke(horizon, with: .color(Color.white.opacity(0.28)),
                       style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 58 * s,
                             midX: 0.40, midY: grassY - 64 * s, midCX: 0.18, midCY: grassY - 86 * s,
                             endY: grassY - 52 * s, endCX: 0.78, endCY: grassY - 80 * s,
                             colors: [Color(red: 0.46, green: 0.44, blue: 0.42),
                                      Color(red: 0.32, green: 0.30, blue: 0.30)])

        for stack in [(0.06, 52, 38, 1), (0.16, 40, 30, 2),
                      (0.88, 44, 32, 3), (0.97, 56, 36, 4)] as [(CGFloat, CGFloat, CGFloat, Int)] {
            HabitatDraw.rock(context,
                             centre: CGPoint(x: size.width * stack.0,
                                             y: grassY - stack.1 * s * 0.35),
                             radius: stack.2 * s, seed: 80 + stack.3,
                             fill: Color(red: 0.38, green: 0.34, blue: 0.36),
                             highlight: Color(red: 0.58, green: 0.56, blue: 0.58))
            HabitatDraw.seaweed(context,
                                root: CGPoint(x: size.width * stack.0 - 4 * s,
                                              y: grassY - stack.1 * s * 0.55),
                                height: (18 + CGFloat(stack.3) * 4) * s,
                                lean: stack.3.isMultiple(of: 2) ? 6 * s : -5 * s,
                                color: ground.lushMid)
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 32 * s,
                             midX: 0.48, midY: grassY - 38 * s, midCX: 0.22, midCY: grassY - 52 * s,
                             endY: grassY - 26 * s, endCX: 0.80, endCY: grassY - 48 * s,
                             colors: [Color(red: 0.40, green: 0.42, blue: 0.38),
                                      Color(red: 0.26, green: 0.28, blue: 0.26)])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.55, midY: grassY - 22 * s, midCX: 0.28, midCY: grassY - 34 * s,
                             endY: grassY - 14 * s, endCX: 0.84, endCY: grassY - 30 * s,
                             colors: [Color(red: 0.48, green: 0.46, blue: 0.40),
                                      Color(red: 0.34, green: 0.32, blue: 0.28)])

        for pool in [(0.10, 28, 16), (0.22, 20, 12), (0.80, 18, 11), (0.93, 26, 14)] as [(CGFloat, CGFloat, CGFloat)] {
            let rect = CGRect(x: size.width * pool.0 - pool.2 * s,
                              y: grassY - pool.1 * s - pool.2 * s * 0.35,
                              width: pool.2 * 2 * s, height: pool.2 * 0.85 * s)
            context.fill(Path(ellipseIn: rect), with: .radialGradient(
                Gradient(colors: [Color(red: 0.28, green: 0.62, blue: 0.72).opacity(0.88),
                                  Color(red: 0.10, green: 0.32, blue: 0.46).opacity(0.90)]),
                center: CGPoint(x: rect.midX, y: rect.midY),
                startRadius: 2, endRadius: pool.2 * s))
            context.stroke(Path(ellipseIn: rect.insetBy(dx: -1.2 * s, dy: -1.2 * s)),
                           with: .color(Color(red: 0.30, green: 0.28, blue: 0.26).opacity(0.55)),
                           lineWidth: 1.4 * s)
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + rect.width * 0.18,
                                                y: rect.minY + rect.height * 0.18,
                                                width: rect.width * 0.28, height: rect.height * 0.22)),
                         with: .color(Color.white.opacity(0.35)))
        }

        let plant = ground.lushLight
        for index in 0..<8 {
            let x = size.width * (index < 4 ? 0.03 + CGFloat(index) * 0.06 : 0.78 + CGFloat(index - 4) * 0.055)
            HabitatDraw.blade(context,
                              root: CGPoint(x: x, y: grassY - (10 + HabitatDraw.noise(30 + index) * 8) * s),
                              height: (12 + HabitatDraw.noise(40 + index) * 10) * s,
                              lean: (HabitatDraw.noise(50 + index) - 0.5) * 8 * s,
                              halfWidth: 1.3 * s, color: plant)
        }
    }

    static func drawOctopusProp(_ context: GraphicsContext, size: CGSize,
                                grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 52 * scale, y: grassY - 28 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        let ground = HabitatWorld.ground(for: .octopus)
        HabitatDraw.rock(layer, centre: CGPoint(x: 28 * scale, y: grassY - 16 * scale),
                         radius: 20 * scale, seed: 11,
                         fill: Color(red: 0.36, green: 0.32, blue: 0.34),
                         highlight: Color(red: 0.56, green: 0.54, blue: 0.56))
        HabitatDraw.rock(layer, centre: CGPoint(x: 50 * scale, y: grassY - 28 * scale),
                         radius: 16 * scale, seed: 12,
                         fill: Color(red: 0.32, green: 0.30, blue: 0.34),
                         highlight: Color(red: 0.52, green: 0.52, blue: 0.58))
        HabitatDraw.rock(layer, centre: CGPoint(x: 72 * scale, y: grassY - 14 * scale),
                         radius: 14 * scale, seed: 13,
                         fill: Color(red: 0.40, green: 0.36, blue: 0.34),
                         highlight: Color(red: 0.60, green: 0.56, blue: 0.52))
        HabitatDraw.seaweed(layer, root: CGPoint(x: 44 * scale, y: grassY - 36 * scale),
                            height: 26 * scale, lean: 7 * scale,
                            color: ground.lushMid)
        HabitatDraw.seaweed(layer, root: CGPoint(x: 58 * scale, y: grassY - 40 * scale),
                            height: 22 * scale, lean: -6 * scale,
                            color: ground.lushDeep)
        let pool = CGRect(x: 34 * scale, y: grassY - 18 * scale, width: 28 * scale, height: 10 * scale)
        layer.fill(Path(ellipseIn: pool), with: .color(Color(red: 0.22, green: 0.54, blue: 0.66).opacity(0.8)))
    }

    static func drawOctopusLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                               scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let ground = HabitatWorld.ground(for: .octopus)
        let pebbles: [(CGFloat, CGFloat, Int)] = [
            (0.05, 8, 1), (0.11, 6, 2), (0.18, 9, 3), (0.26, 7, 4),
            (0.58, 6, 5), (0.66, 8, 6), (0.94, 7, 7), (0.98, 9, 8)
        ]
        for pebble in pebbles {
            let x = size.width * pebble.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 4 * scale),
                             radius: pebble.1 * scale, seed: 200 + pebble.2,
                             fill: Color(red: 0.42, green: 0.38, blue: 0.36),
                             highlight: Color(red: 0.62, green: 0.58, blue: 0.54))
        }
        for index in [0, 1, 2, 6, 7] {
            let x = size.width * (index < 3 ? 0.04 + CGFloat(index) * 0.08 : 0.78 + CGFloat(index - 3) * 0.07)
            if hidden(x) { continue }
            HabitatDraw.seaweed(context, root: CGPoint(x: x, y: grassY - 2 * scale),
                                height: (12 + CGFloat(index % 3) * 4) * scale,
                                lean: index.isMultiple(of: 2) ? 5 * scale : -4 * scale,
                                color: ground.lushMid)
        }
    }

    // MARK: Crab — dunes, beach, driftwood

    static func drawCrab(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .crab)

        var sea = Path()
        sea.move(to: CGPoint(x: 0, y: grassY - 72 * s))
        sea.addQuadCurve(to: CGPoint(x: size.width, y: grassY - 68 * s),
                         control: CGPoint(x: size.width * 0.5, y: grassY - 78 * s))
        sea.addLine(to: CGPoint(x: size.width, y: grassY - 52 * s))
        sea.addLine(to: CGPoint(x: 0, y: grassY - 54 * s))
        sea.closeSubpath()
        context.fill(sea, with: .linearGradient(
            Gradient(colors: [Color(red: 0.28, green: 0.68, blue: 0.82),
                              Color(red: 0.18, green: 0.52, blue: 0.70)]),
            startPoint: CGPoint(x: 0, y: grassY - 78 * s),
            endPoint: CGPoint(x: 0, y: grassY - 52 * s)))

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 54 * s,
                             midX: 0.38, midY: grassY - 66 * s, midCX: 0.16, midCY: grassY - 88 * s,
                             endY: grassY - 50 * s, endCX: 0.76, endCY: grassY - 82 * s,
                             colors: [Color(red: 0.92, green: 0.82, blue: 0.58),
                                      Color(red: 0.80, green: 0.66, blue: 0.42)])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 34 * s,
                             midX: 0.50, midY: grassY - 42 * s, midCX: 0.24, midCY: grassY - 58 * s,
                             endY: grassY - 30 * s, endCX: 0.82, endCY: grassY - 54 * s,
                             colors: [Color(red: 0.90, green: 0.78, blue: 0.52),
                                      Color(red: 0.76, green: 0.60, blue: 0.36)])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.46, midY: grassY - 22 * s, midCX: 0.22, midCY: grassY - 34 * s,
                             endY: grassY - 14 * s, endCX: 0.80, endCY: grassY - 30 * s,
                             colors: [Color(red: 0.94, green: 0.84, blue: 0.60),
                                      Color(red: 0.82, green: 0.68, blue: 0.44)])

        let duneGrass = ground.lushLight
        for index in 0..<14 {
            let side = index < 7
            let x = size.width * (side ? 0.03 + CGFloat(index) * 0.05 : 0.70 + CGFloat(index - 7) * 0.04)
            let y = grassY - (18 + HabitatDraw.noise(60 + index) * 22) * s
            HabitatDraw.blade(context, root: CGPoint(x: x, y: y),
                              height: (14 + HabitatDraw.noise(70 + index) * 16) * s,
                              lean: (HabitatDraw.noise(80 + index) - 0.4) * 10 * s,
                              halfWidth: 1.15 * s, color: duneGrass)
        }

        HabitatDraw.driftwood(context,
                              origin: CGPoint(x: size.width * 0.78, y: grassY - 28 * s),
                              width: 64 * s, height: 16 * s)
        HabitatDraw.shell(context, at: CGPoint(x: size.width * 0.08, y: grassY - 20 * s),
                          size: 10 * s, fill: Color(red: 0.94, green: 0.82, blue: 0.70))
        HabitatDraw.shell(context, at: CGPoint(x: size.width * 0.92, y: grassY - 18 * s),
                          size: 8 * s, fill: Color(red: 0.90, green: 0.72, blue: 0.62))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.18, y: grassY - 14 * s),
                         radius: 8 * s, seed: 21,
                         fill: Color(red: 0.62, green: 0.56, blue: 0.48),
                         highlight: Color(red: 0.78, green: 0.72, blue: 0.64))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.86, y: grassY - 12 * s),
                         radius: 7 * s, seed: 22,
                         fill: Color(red: 0.58, green: 0.52, blue: 0.46),
                         highlight: Color(red: 0.74, green: 0.68, blue: 0.60))
    }

    static func drawCrabProp(_ context: GraphicsContext, size: CGSize,
                             grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 70 * scale, y: grassY - 18 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.driftwood(layer, origin: CGPoint(x: 8 * scale, y: grassY - 22 * scale),
                              width: 108 * scale, height: 20 * scale)
        let ground = HabitatWorld.ground(for: .crab)
        HabitatDraw.shell(layer, at: CGPoint(x: 28 * scale, y: grassY - 8 * scale),
                          size: 12 * scale, fill: Color(red: 0.96, green: 0.86, blue: 0.74))
        HabitatDraw.shell(layer, at: CGPoint(x: 96 * scale, y: grassY - 10 * scale),
                          size: 9 * scale, fill: Color(red: 0.88, green: 0.62, blue: 0.50))
        for index in 0..<5 {
            HabitatDraw.blade(layer,
                              root: CGPoint(x: (18 + CGFloat(index) * 16) * scale,
                                            y: grassY - 20 * scale),
                              height: (16 + CGFloat(index % 3) * 5) * scale,
                              lean: CGFloat(index - 2) * 3 * scale,
                              halfWidth: 1.2 * scale,
                              color: ground.lushLight)
        }
    }

    static func drawCrabLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                            scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let ground = HabitatWorld.ground(for: .crab)
        let shells: [(CGFloat, CGFloat, Color)] = [
            (0.06, 9, Color(red: 0.96, green: 0.86, blue: 0.74)),
            (0.13, 7, Color(red: 0.90, green: 0.70, blue: 0.58)),
            (0.22, 8, Color(red: 0.94, green: 0.90, blue: 0.82)),
            (0.60, 7, Color(red: 0.88, green: 0.64, blue: 0.52)),
            (0.92, 8, Color(red: 0.96, green: 0.84, blue: 0.70)),
            (0.97, 6, Color(red: 0.86, green: 0.78, blue: 0.68))
        ]
        for shell in shells {
            let x = size.width * shell.0
            if hidden(x) { continue }
            HabitatDraw.shell(context, at: CGPoint(x: x, y: grassY - 5 * scale),
                              size: shell.1 * scale, fill: shell.2)
        }
        for index in [0, 1, 8, 9] {
            let x = size.width * (0.04 + CGFloat(index) * 0.105)
            if hidden(x) { continue }
            HabitatDraw.blade(context, root: CGPoint(x: x, y: grassY - 2 * scale),
                              height: 14 * scale, lean: index.isMultiple(of: 2) ? 5 * scale : -4 * scale,
                              halfWidth: 1.15 * scale,
                              color: ground.lushLight)
        }
    }

    // MARK: Bear — mountain pines

    static func drawBear(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .bear)

        var mountains = Path()
        mountains.move(to: CGPoint(x: 0, y: grassY - 70 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.14, y: grassY - 168 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.28, y: grassY - 102 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.44, y: grassY - 186 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.58, y: grassY - 118 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.74, y: grassY - 158 * s))
        mountains.addLine(to: CGPoint(x: size.width * 0.88, y: grassY - 96 * s))
        mountains.addLine(to: CGPoint(x: size.width, y: grassY - 132 * s))
        mountains.addLine(to: CGPoint(x: size.width, y: bottom))
        mountains.addLine(to: CGPoint(x: 0, y: bottom))
        mountains.closeSubpath()
        context.fill(mountains, with: .linearGradient(
            Gradient(colors: [Color(red: 0.42, green: 0.50, blue: 0.58),
                              Color(red: 0.28, green: 0.34, blue: 0.42)]),
            startPoint: CGPoint(x: 0, y: grassY - 186 * s),
            endPoint: CGPoint(x: 0, y: bottom)))

        for peak in [(0.14, 168, 0.10), (0.44, 186, 0.12), (0.74, 158, 0.10)] as [(CGFloat, CGFloat, CGFloat)] {
            var snow = Path()
            snow.move(to: CGPoint(x: size.width * peak.0, y: grassY - peak.1 * s))
            snow.addLine(to: CGPoint(x: size.width * (peak.0 - peak.2), y: grassY - peak.1 * s * 0.78))
            snow.addLine(to: CGPoint(x: size.width * (peak.0 + peak.2 * 0.7), y: grassY - peak.1 * s * 0.80))
            snow.closeSubpath()
            context.fill(snow, with: .color(Color.white.opacity(0.78)))
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 52 * s,
                             midX: 0.42, midY: grassY - 58 * s, midCX: 0.20, midCY: grassY - 76 * s,
                             endY: grassY - 48 * s, endCX: 0.78, endCY: grassY - 72 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        for tree in [(0.04, 62, 0.02), (0.11, 48, 0.08), (0.17, 56, 0.00),
                     (0.84, 52, 0.06), (0.91, 64, 0.00), (0.97, 46, 0.10)] as [(CGFloat, CGFloat, CGFloat)] {
            HabitatDraw.pine(context,
                             base: CGPoint(x: size.width * tree.0, y: grassY - 16 * s),
                             height: tree.1 * s, dusk: tree.2)
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 30 * s,
                             midX: 0.50, midY: grassY - 36 * s, midCX: 0.24, midCY: grassY - 50 * s,
                             endY: grassY - 26 * s, endCX: 0.80, endCY: grassY - 46 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.48, midY: grassY - 20 * s, midCX: 0.26, midCY: grassY - 32 * s,
                             endY: grassY - 14 * s, endCX: 0.82, endCY: grassY - 28 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.08, y: grassY - 12 * s),
                         radius: 12 * s, seed: 31,
                         fill: Color(red: 0.40, green: 0.36, blue: 0.34),
                         highlight: Color(red: 0.58, green: 0.54, blue: 0.50))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.90, y: grassY - 14 * s),
                         radius: 14 * s, seed: 32,
                         fill: Color(red: 0.38, green: 0.34, blue: 0.32),
                         highlight: Color(red: 0.56, green: 0.52, blue: 0.48))
        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.22, y: grassY - 10 * s),
                         height: 34 * s, dusk: 0.04)
        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.80, y: grassY - 10 * s),
                         height: 30 * s, dusk: 0.06)

        let shrub = HabitatWorld.ground(for: .bear).lushMid
        for index in 0..<6 {
            let x = size.width * (index < 3 ? 0.05 + CGFloat(index) * 0.07 : 0.82 + CGFloat(index - 3) * 0.06)
            context.fill(Path(ellipseIn: CGRect(x: x - 10 * s, y: grassY - 22 * s,
                                                width: 20 * s, height: 12 * s)),
                         with: .color(shrub.opacity(0.86)))
        }
    }

    static func drawBearProp(_ context: GraphicsContext, size: CGSize,
                             grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 48 * scale, y: grassY - 30 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.rock(layer, centre: CGPoint(x: 22 * scale, y: grassY - 12 * scale),
                         radius: 16 * scale, seed: 41,
                         fill: Color(red: 0.38, green: 0.34, blue: 0.32),
                         highlight: Color(red: 0.56, green: 0.52, blue: 0.48))
        HabitatDraw.pine(layer, base: CGPoint(x: 48 * scale, y: grassY - 8 * scale),
                         height: 58 * scale)
        HabitatDraw.pine(layer, base: CGPoint(x: 72 * scale, y: grassY - 8 * scale),
                         height: 42 * scale, dusk: 0.06)
        layer.fill(Path(ellipseIn: CGRect(x: 30 * scale, y: grassY - 18 * scale,
                                          width: 22 * scale, height: 12 * scale)),
                   with: .color(HabitatWorld.ground(for: .bear).lushMid.opacity(0.85)))
    }

    static func drawBearLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                            scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let rocks: [(CGFloat, CGFloat, Int)] = [
            (0.05, 9, 1), (0.12, 7, 2), (0.20, 8, 3),
            (0.62, 7, 4), (0.90, 9, 5), (0.97, 7, 6)
        ]
        for rock in rocks {
            let x = size.width * rock.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 4 * scale),
                             radius: rock.1 * scale, seed: 50 + rock.2,
                             fill: Color(red: 0.40, green: 0.36, blue: 0.32),
                             highlight: Color(red: 0.58, green: 0.54, blue: 0.48))
        }
        for index in [0, 1, 7] {
            let x = size.width * (index == 7 ? 0.86 : 0.07 + CGFloat(index) * 0.08)
            if hidden(x) { continue }
            HabitatDraw.blade(context, root: CGPoint(x: x, y: grassY - 2 * scale),
                              height: 12 * scale, lean: 3 * scale, halfWidth: 1.2 * scale,
                              color: HabitatWorld.ground(for: .bear).lushLight)
        }
    }

    // MARK: Fox — dense autumn forest

    static func drawFox(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .fox)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 78 * s,
                             midX: 0.46, midY: grassY - 92 * s, midCX: 0.20, midCY: grassY - 118 * s,
                             endY: grassY - 74 * s, endCX: 0.80, endCY: grassY - 112 * s,
                             colors: [ground.lushLight, ground.lushDeep])

        for tree in [(0.03, 70, 0.00), (0.10, 58, 0.08), (0.17, 66, 0.04),
                     (0.84, 60, 0.10), (0.92, 72, 0.00), (0.98, 54, 0.06)] as [(CGFloat, CGFloat, Double)] {
            HabitatDraw.autumnTree(context,
                                   base: CGPoint(x: size.width * tree.0, y: grassY - 18 * s),
                                   height: tree.1 * s, tint: tree.2)
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 40 * s,
                             midX: 0.50, midY: grassY - 48 * s, midCX: 0.24, midCY: grassY - 64 * s,
                             endY: grassY - 34 * s, endCX: 0.78, endCY: grassY - 60 * s,
                             colors: [ground.lushGlow, ground.lushMid])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 18 * s,
                             midX: 0.52, midY: grassY - 24 * s, midCX: 0.26, midCY: grassY - 36 * s,
                             endY: grassY - 15 * s, endCX: 0.82, endCY: grassY - 32 * s,
                             colors: [ground.lushLight, ground.lushDeep])

        HabitatDraw.autumnTree(context, base: CGPoint(x: size.width * 0.07, y: grassY - 10 * s),
                               height: 38 * s, tint: 0.12)
        HabitatDraw.autumnTree(context, base: CGPoint(x: size.width * 0.94, y: grassY - 10 * s),
                               height: 42 * s, tint: 0.02)

        let fernGreen = ground.lushMid
        HabitatDraw.fern(context, root: CGPoint(x: size.width * 0.12, y: grassY - 12 * s),
                         height: 22 * s, side: 1, color: fernGreen)
        HabitatDraw.fern(context, root: CGPoint(x: size.width * 0.20, y: grassY - 10 * s),
                         height: 18 * s, side: -1, color: fernGreen)
        HabitatDraw.fern(context, root: CGPoint(x: size.width * 0.86, y: grassY - 12 * s),
                         height: 20 * s, side: 1, color: fernGreen)
        HabitatDraw.fern(context, root: CGPoint(x: size.width * 0.93, y: grassY - 10 * s),
                         height: 16 * s, side: -1, color: fernGreen)

        HabitatDraw.driftwood(context,
                              origin: CGPoint(x: size.width * 0.78, y: grassY - 22 * s),
                              width: 54 * s, height: 12 * s)

        for index in 0..<8 {
            let x = size.width * (CGFloat(index) + 0.3) / 8
            if x > size.width * 0.28 && x < size.width * 0.72 { continue }
            context.fill(Path(ellipseIn: CGRect(
                x: x - 4 * s, y: grassY - (14 + HabitatDraw.noise(90 + index) * 10) * s,
                width: 8 * s, height: 5 * s)),
                         with: .color(Color(red: 0.86, green: 0.40, blue: 0.14).opacity(0.78)))
        }
    }

    static func drawFoxProp(_ context: GraphicsContext, size: CGSize,
                            grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 60 * scale, y: grassY - 16 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.driftwood(layer, origin: CGPoint(x: 6 * scale, y: grassY - 20 * scale),
                              width: 112 * scale, height: 18 * scale)
        HabitatDraw.fern(layer, root: CGPoint(x: 24 * scale, y: grassY - 8 * scale),
                         height: 24 * scale, side: 1,
                         color: HabitatWorld.ground(for: .fox).lushMid)
        HabitatDraw.fern(layer, root: CGPoint(x: 86 * scale, y: grassY - 8 * scale),
                         height: 20 * scale, side: -1,
                         color: HabitatWorld.ground(for: .fox).lushLight)
        HabitatDraw.rock(layer, centre: CGPoint(x: 48 * scale, y: grassY - 8 * scale),
                         radius: 8 * scale, seed: 61,
                         fill: Color(red: 0.42, green: 0.32, blue: 0.22),
                         highlight: Color(red: 0.60, green: 0.46, blue: 0.30))
    }

    static func drawFoxLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                           scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let fernGreen = HabitatWorld.ground(for: .fox).lushMid
        for item in [(0.06, 1.0), (0.14, -1.0), (0.24, 1.0), (0.62, -1.0), (0.90, 1.0), (0.97, -1.0)] as [(CGFloat, CGFloat)] {
            let x = size.width * item.0
            if hidden(x) { continue }
            HabitatDraw.fern(context, root: CGPoint(x: x, y: grassY - 1 * scale),
                             height: 16 * scale, side: item.1, color: fernGreen)
        }
        for index in 0..<5 {
            let x = size.width * (index < 3 ? 0.04 + CGFloat(index) * 0.08 : 0.88 + CGFloat(index - 3) * 0.05)
            if hidden(x) { continue }
            context.fill(Path(ellipseIn: CGRect(x: x - 3.5 * scale, y: grassY - 7 * scale,
                                                width: 7 * scale, height: 4.5 * scale)),
                         with: .color(Color(red: 0.84, green: 0.38, blue: 0.12).opacity(0.86)))
        }
    }

    // MARK: Frog — pond bank / marsh

    static func drawFrog(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .frog)

        var water = Path()
        water.move(to: CGPoint(x: 0, y: grassY - 64 * s))
        water.addQuadCurve(to: CGPoint(x: size.width, y: grassY - 58 * s),
                           control: CGPoint(x: size.width * 0.5, y: grassY - 72 * s))
        water.addLine(to: CGPoint(x: size.width, y: bottom))
        water.addLine(to: CGPoint(x: 0, y: bottom))
        water.closeSubpath()
        context.fill(water, with: .linearGradient(
            Gradient(colors: [Color(red: 0.22, green: 0.52, blue: 0.48),
                              Color(red: 0.12, green: 0.34, blue: 0.36)]),
            startPoint: CGPoint(x: 0, y: grassY - 72 * s),
            endPoint: CGPoint(x: 0, y: bottom)))

        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.10, y: grassY - 48 * s), radius: 11 * s)
        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.18, y: grassY - 40 * s), radius: 8 * s)
        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.84, y: grassY - 44 * s), radius: 10 * s)
        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.93, y: grassY - 38 * s), radius: 7 * s)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 42 * s,
                             midX: 0.36, midY: grassY - 50 * s, midCX: 0.14, midCY: grassY - 64 * s,
                             endY: grassY - 36 * s, endCX: 0.78, endCY: grassY - 58 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        let reedColor = ground.lushMid
        for index in 0..<12 {
            let left = index < 6
            let x = size.width * (left ? 0.02 + CGFloat(index) * 0.045 : 0.76 + CGFloat(index - 6) * 0.04)
            HabitatDraw.reed(context,
                             root: CGPoint(x: x, y: grassY - (14 + HabitatDraw.noise(110 + index) * 10) * s),
                             height: (28 + HabitatDraw.noise(120 + index) * 22) * s,
                             lean: (HabitatDraw.noise(130 + index) - 0.5) * 10 * s,
                             color: reedColor)
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 18 * s,
                             midX: 0.48, midY: grassY - 24 * s, midCX: 0.24, midCY: grassY - 36 * s,
                             endY: grassY - 14 * s, endCX: 0.82, endCY: grassY - 32 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.08, y: grassY - 10 * s),
                         radius: 10 * s, seed: 71,
                         fill: Color(red: 0.42, green: 0.40, blue: 0.36),
                         highlight: Color(red: 0.60, green: 0.58, blue: 0.52))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.90, y: grassY - 12 * s),
                         radius: 11 * s, seed: 72,
                         fill: Color(red: 0.40, green: 0.38, blue: 0.34),
                         highlight: Color(red: 0.58, green: 0.56, blue: 0.50))
        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.16, y: grassY - 22 * s), radius: 7 * s)
        HabitatDraw.lilyPad(context, at: CGPoint(x: size.width * 0.88, y: grassY - 20 * s), radius: 6 * s)
    }

    static func drawFrogProp(_ context: GraphicsContext, size: CGSize,
                             grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 46 * scale, y: grassY - 32 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        let reedColor = HabitatWorld.ground(for: .frog).lushMid
        for index in 0..<7 {
            HabitatDraw.reed(layer,
                             root: CGPoint(x: (12 + CGFloat(index) * 12) * scale, y: grassY - 6 * scale),
                             height: (32 + CGFloat(index % 4) * 10) * scale,
                             lean: CGFloat(index - 3) * 2.4 * scale,
                             color: reedColor)
        }
        HabitatDraw.rock(layer, centre: CGPoint(x: 28 * scale, y: grassY - 8 * scale),
                         radius: 10 * scale, seed: 81,
                         fill: Color(red: 0.40, green: 0.38, blue: 0.34),
                         highlight: Color(red: 0.58, green: 0.56, blue: 0.50))
        HabitatDraw.lilyPad(layer, at: CGPoint(x: 70 * scale, y: grassY - 14 * scale), radius: 9 * scale)
    }

    static func drawFrogLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                            scale: CGFloat, hidden: (CGFloat) -> Bool) {
        for item in [(0.05, 9), (0.12, 7), (0.22, 8), (0.62, 7), (0.90, 9), (0.97, 7)] as [(CGFloat, CGFloat)] {
            let x = size.width * item.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 3 * scale),
                             radius: item.1 * scale, seed: Int(item.0 * 80),
                             fill: Color(red: 0.40, green: 0.38, blue: 0.34),
                             highlight: Color(red: 0.58, green: 0.54, blue: 0.48))
        }
        for index in [0, 1, 8] {
            let x = size.width * (index == 8 ? 0.88 : 0.06 + CGFloat(index) * 0.08)
            if hidden(x) { continue }
            HabitatDraw.reed(context, root: CGPoint(x: x, y: grassY - 1 * scale),
                             height: 18 * scale, lean: index == 1 ? 4 * scale : -3 * scale,
                             color: HabitatWorld.ground(for: .frog).lushLight)
        }
    }

    // MARK: Penguin — polar ice

    static func drawPenguin(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .penguin)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 86 * s,
                             midX: 0.30, midY: grassY - 118 * s, midCX: 0.12, midCY: grassY - 148 * s,
                             endY: grassY - 78 * s, endCX: 0.72, endCY: grassY - 140 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        HabitatDraw.iceChunk(context, base: CGPoint(x: size.width * 0.12, y: grassY - 52 * s),
                             height: 54 * s, width: 48 * s)
        HabitatDraw.iceChunk(context, base: CGPoint(x: size.width * 0.28, y: grassY - 46 * s),
                             height: 38 * s, width: 36 * s)
        HabitatDraw.iceChunk(context, base: CGPoint(x: size.width * 0.84, y: grassY - 50 * s),
                             height: 46 * s, width: 42 * s)
        HabitatDraw.iceChunk(context, base: CGPoint(x: size.width * 0.96, y: grassY - 44 * s),
                             height: 34 * s, width: 32 * s)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 44 * s,
                             midX: 0.48, midY: grassY - 54 * s, midCX: 0.22, midCY: grassY - 70 * s,
                             endY: grassY - 38 * s, endCX: 0.80, endCY: grassY - 64 * s,
                             colors: [ground.lushGlow, ground.lushMid])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 18 * s,
                             midX: 0.52, midY: grassY - 24 * s, midCX: 0.26, midCY: grassY - 36 * s,
                             endY: grassY - 14 * s, endCX: 0.84, endCY: grassY - 30 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.08, y: grassY - 12 * s),
                         radius: 12 * s, seed: 91,
                         fill: Color(red: 0.42, green: 0.46, blue: 0.52),
                         highlight: Color(red: 0.62, green: 0.66, blue: 0.72))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.18, y: grassY - 10 * s),
                         radius: 8 * s, seed: 92,
                         fill: Color(red: 0.38, green: 0.42, blue: 0.48),
                         highlight: Color(red: 0.58, green: 0.62, blue: 0.68))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.88, y: grassY - 14 * s),
                         radius: 13 * s, seed: 93,
                         fill: Color(red: 0.40, green: 0.44, blue: 0.50),
                         highlight: Color(red: 0.60, green: 0.64, blue: 0.70))
        HabitatDraw.iceChunk(context, base: CGPoint(x: size.width * 0.78, y: grassY - 16 * s),
                             height: 22 * s, width: 20 * s)
    }

    static func drawPenguinProp(_ context: GraphicsContext, size: CGSize,
                                grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 50 * scale, y: grassY - 28 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.iceChunk(layer, base: CGPoint(x: 32 * scale, y: grassY - 8 * scale),
                             height: 48 * scale, width: 40 * scale)
        HabitatDraw.iceChunk(layer, base: CGPoint(x: 62 * scale, y: grassY - 8 * scale),
                             height: 34 * scale, width: 28 * scale)
        HabitatDraw.rock(layer, centre: CGPoint(x: 18 * scale, y: grassY - 10 * scale),
                         radius: 12 * scale, seed: 101,
                         fill: Color(red: 0.40, green: 0.44, blue: 0.50),
                         highlight: Color(red: 0.60, green: 0.64, blue: 0.70))
    }

    static func drawPenguinLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                               scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let bits: [(CGFloat, CGFloat, CGFloat)] = [
            (0.05, 14, 12), (0.14, 10, 9), (0.24, 12, 10),
            (0.62, 10, 9), (0.90, 13, 11), (0.97, 10, 8)
        ]
        for bit in bits {
            let x = size.width * bit.0
            if hidden(x) { continue }
            HabitatDraw.iceChunk(context, base: CGPoint(x: x, y: grassY - 2 * scale),
                                 height: bit.1 * scale, width: bit.2 * scale)
        }
        for rock in [(0.09, 7), (0.86, 8)] as [(CGFloat, CGFloat)] {
            let x = size.width * rock.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 3 * scale),
                             radius: rock.1 * scale, seed: 110,
                             fill: Color(red: 0.40, green: 0.44, blue: 0.50),
                             highlight: Color(red: 0.60, green: 0.64, blue: 0.70))
        }
    }

    // MARK: Dog — agility field

    static func drawDog(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .dog)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 52 * s,
                             midX: 0.44, midY: grassY - 46 * s, midCX: 0.20, midCY: grassY - 68 * s,
                             endY: grassY - 50 * s, endCX: 0.78, endCY: grassY - 66 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.parkTree(context, base: CGPoint(x: size.width * 0.05, y: grassY - 17 * s),
                             height: 46 * s, tint: 0.06)
        HabitatDraw.parkTree(context, base: CGPoint(x: size.width * 0.13, y: grassY - 16 * s),
                             height: 36 * s, tint: 0.12)
        HabitatDraw.parkTree(context, base: CGPoint(x: size.width * 0.90, y: grassY - 16 * s),
                             height: 38 * s, tint: 0.10)
        HabitatDraw.parkTree(context, base: CGPoint(x: size.width * 0.97, y: grassY - 17 * s),
                             height: 50 * s, tint: 0.04)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 32 * s,
                             midX: 0.48, midY: grassY - 38 * s, midCX: 0.22, midCY: grassY - 52 * s,
                             endY: grassY - 28 * s, endCX: 0.80, endCY: grassY - 48 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        // Distant course that stays after the blast.
        HabitatDraw.hurdle(context, origin: CGPoint(x: size.width * 0.78, y: grassY - 14 * s),
                           width: 36 * s, height: 28 * s)
        HabitatDraw.hurdle(context, origin: CGPoint(x: size.width * 0.18, y: grassY - 16 * s),
                           width: 32 * s, height: 24 * s)
        HabitatDraw.slalomPole(context, at: CGPoint(x: size.width * 0.88, y: grassY - 12 * s),
                               height: 30 * s, hue: Color(red: 0.18, green: 0.55, blue: 0.86))
        HabitatDraw.slalomPole(context, at: CGPoint(x: size.width * 0.93, y: grassY - 12 * s),
                               height: 32 * s, hue: Color(red: 0.94, green: 0.32, blue: 0.18))
        HabitatDraw.tunnel(context, origin: CGPoint(x: size.width * 0.04, y: grassY - 12 * s),
                           width: 48 * s, height: 32 * s)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.50, midY: grassY - 20 * s, midCX: 0.26, midCY: grassY - 32 * s,
                             endY: grassY - 14 * s, endCX: 0.82, endCY: grassY - 28 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.agilityCone(context, at: CGPoint(x: size.width * 0.20, y: grassY - 10 * s),
                                height: 16 * s)
        HabitatDraw.agilityCone(context, at: CGPoint(x: size.width * 0.82, y: grassY - 10 * s),
                                height: 15 * s)
    }

    static func drawDogProp(_ context: GraphicsContext, size: CGSize,
                            grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 64 * scale, y: grassY - 24 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.hurdle(layer, origin: CGPoint(x: 10 * scale, y: grassY - 8 * scale),
                           width: 48 * scale, height: 36 * scale)
        HabitatDraw.slalomPole(layer, at: CGPoint(x: 72 * scale, y: grassY - 8 * scale),
                               height: 40 * scale, hue: Color(red: 0.94, green: 0.32, blue: 0.18))
        HabitatDraw.slalomPole(layer, at: CGPoint(x: 88 * scale, y: grassY - 8 * scale),
                               height: 44 * scale, hue: Color(red: 0.18, green: 0.55, blue: 0.86))
        HabitatDraw.slalomPole(layer, at: CGPoint(x: 104 * scale, y: grassY - 8 * scale),
                               height: 38 * scale, hue: Color(red: 0.98, green: 0.78, blue: 0.16))
        HabitatDraw.agilityCone(layer, at: CGPoint(x: 40 * scale, y: grassY - 8 * scale),
                                height: 16 * scale)
    }

    static func drawDogLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                           scale: CGFloat, hidden: (CGFloat) -> Bool) {
        for item in [(0.05, 14), (0.12, 12), (0.88, 13), (0.94, 14), (0.98, 12)] as [(CGFloat, CGFloat)] {
            let x = size.width * item.0
            if hidden(x) { continue }
            HabitatDraw.agilityCone(context, at: CGPoint(x: x, y: grassY - 1 * scale),
                                    height: item.1 * scale)
        }
    }

    // MARK: Lion — savanna

    static func drawLion(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .lion)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 58 * s,
                             midX: 0.42, midY: grassY - 48 * s, midCX: 0.18, midCY: grassY - 72 * s,
                             endY: grassY - 54 * s, endCX: 0.76, endCY: grassY - 70 * s,
                             colors: [ground.lushGlow, ground.lushLight])

        var kopje = Path()
        kopje.move(to: CGPoint(x: size.width * 0.62, y: grassY - 54 * s))
        kopje.addQuadCurve(to: CGPoint(x: size.width * 0.78, y: grassY - 96 * s),
                           control: CGPoint(x: size.width * 0.66, y: grassY - 88 * s))
        kopje.addQuadCurve(to: CGPoint(x: size.width * 0.92, y: grassY - 52 * s),
                           control: CGPoint(x: size.width * 0.88, y: grassY - 90 * s))
        kopje.addLine(to: CGPoint(x: size.width * 0.62, y: grassY - 54 * s))
        kopje.closeSubpath()
        context.fill(kopje, with: .linearGradient(
            Gradient(colors: [Color(red: 0.62, green: 0.42, blue: 0.24),
                              Color(red: 0.46, green: 0.30, blue: 0.16)]),
            startPoint: CGPoint(x: 0, y: grassY - 96 * s),
            endPoint: CGPoint(x: 0, y: grassY - 50 * s)))

        HabitatDraw.acacia(context, base: CGPoint(x: size.width * 0.08, y: grassY - 18 * s),
                           height: 58 * s)
        HabitatDraw.acacia(context, base: CGPoint(x: size.width * 0.18, y: grassY - 16 * s),
                           height: 42 * s)
        HabitatDraw.acacia(context, base: CGPoint(x: size.width * 0.90, y: grassY - 16 * s),
                           height: 48 * s)
        HabitatDraw.acacia(context, base: CGPoint(x: size.width * 0.98, y: grassY - 18 * s),
                           height: 62 * s)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 34 * s,
                             midX: 0.50, midY: grassY - 40 * s, midCX: 0.24, midCY: grassY - 54 * s,
                             endY: grassY - 28 * s, endCX: 0.80, endCY: grassY - 50 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.48, midY: grassY - 22 * s, midCX: 0.26, midCY: grassY - 34 * s,
                             endY: grassY - 14 * s, endCX: 0.82, endCY: grassY - 30 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        let dry = ground.lushLight
        for index in 0..<16 {
            let x = size.width * (CGFloat(index) + 0.2) / 16
            if x > size.width * 0.30 && x < size.width * 0.70 { continue }
            HabitatDraw.blade(context,
                              root: CGPoint(x: x, y: grassY - (10 + HabitatDraw.noise(140 + index) * 12) * s),
                              height: (12 + HabitatDraw.noise(150 + index) * 14) * s,
                              lean: (HabitatDraw.noise(160 + index) - 0.35) * 12 * s,
                              halfWidth: 1.05 * s, color: dry)
        }

        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.10, y: grassY - 12 * s),
                         radius: 14 * s, seed: 121,
                         fill: Color(red: 0.56, green: 0.42, blue: 0.28),
                         highlight: Color(red: 0.74, green: 0.60, blue: 0.40))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.88, y: grassY - 14 * s),
                         radius: 16 * s, seed: 122,
                         fill: Color(red: 0.52, green: 0.40, blue: 0.26),
                         highlight: Color(red: 0.70, green: 0.56, blue: 0.38))
        HabitatDraw.acacia(context, base: CGPoint(x: size.width * 0.78, y: grassY - 10 * s),
                           height: 32 * s)
    }

    static func drawLionProp(_ context: GraphicsContext, size: CGSize,
                             grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 48 * scale, y: grassY - 22 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        HabitatDraw.rock(layer, centre: CGPoint(x: 24 * scale, y: grassY - 12 * scale),
                         radius: 18 * scale, seed: 131,
                         fill: Color(red: 0.54, green: 0.40, blue: 0.26),
                         highlight: Color(red: 0.72, green: 0.58, blue: 0.38))
        HabitatDraw.rock(layer, centre: CGPoint(x: 48 * scale, y: grassY - 22 * scale),
                         radius: 16 * scale, seed: 132,
                         fill: Color(red: 0.50, green: 0.38, blue: 0.24),
                         highlight: Color(red: 0.68, green: 0.54, blue: 0.36))
        HabitatDraw.rock(layer, centre: CGPoint(x: 68 * scale, y: grassY - 10 * scale),
                         radius: 12 * scale, seed: 133,
                         fill: Color(red: 0.58, green: 0.44, blue: 0.28),
                         highlight: Color(red: 0.76, green: 0.62, blue: 0.42))
        HabitatDraw.blade(layer, root: CGPoint(x: 36 * scale, y: grassY - 24 * scale),
                          height: 18 * scale, lean: 6 * scale, halfWidth: 1.2 * scale,
                          color: HabitatWorld.ground(for: .lion).lushLight)
    }

    static func drawLionLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                            scale: CGFloat, hidden: (CGFloat) -> Bool) {
        let dry = HabitatWorld.ground(for: .lion).lushLight
        for index in 0..<10 {
            let x = size.width * (index < 5 ? 0.04 + CGFloat(index) * 0.05 : 0.72 + CGFloat(index - 5) * 0.055)
            if hidden(x) { continue }
            HabitatDraw.blade(context, root: CGPoint(x: x, y: grassY - 2 * scale),
                              height: (11 + CGFloat(index % 3) * 4) * scale,
                              lean: (index.isMultiple(of: 2) ? 5 : -4) * scale,
                              halfWidth: 1.1 * scale, color: dry)
        }
        for rock in [(0.08, 8), (0.18, 6), (0.90, 8), (0.97, 6)] as [(CGFloat, CGFloat)] {
            let x = size.width * rock.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 3 * scale),
                             radius: rock.1 * scale, seed: Int(rock.0 * 40),
                             fill: Color(red: 0.54, green: 0.42, blue: 0.26),
                             highlight: Color(red: 0.72, green: 0.58, blue: 0.38))
        }
    }

    // MARK: Elephant — zoo enclosure

    static func drawElephant(_ context: GraphicsContext, size: CGSize, grassY: CGFloat) {
        let s = HabitatDraw.scale(for: size, grassY: grassY)
        let bottom = grassY + 10
        let ground = HabitatWorld.ground(for: .elephant)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 58 * s,
                             midX: 0.46, midY: grassY - 52 * s, midCX: 0.20, midCY: grassY - 74 * s,
                             endY: grassY - 54 * s, endCX: 0.78, endCY: grassY - 70 * s,
                             colors: [ground.lushLight, ground.lushMid])

        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.05, y: grassY - 18 * s),
                         height: 46 * s, dusk: 0.08,
                         ground: HabitatWorld.ground(for: .elephant))
        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.12, y: grassY - 16 * s),
                         height: 36 * s, dusk: 0.12,
                         ground: HabitatWorld.ground(for: .elephant))
        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.90, y: grassY - 16 * s),
                         height: 40 * s, dusk: 0.10,
                         ground: HabitatWorld.ground(for: .elephant))
        HabitatDraw.pine(context, base: CGPoint(x: size.width * 0.97, y: grassY - 18 * s),
                         height: 50 * s, dusk: 0.04,
                         ground: HabitatWorld.ground(for: .elephant))

        // Back enclosure rail that stays.
        let railY = grassY - 46 * s
        let metal = Color(red: 0.55, green: 0.52, blue: 0.48)
        let post = Color(red: 0.42, green: 0.40, blue: 0.36)
        context.fill(Path(CGRect(x: 0, y: railY, width: size.width, height: 3 * s)),
                     with: .color(metal))
        context.fill(Path(CGRect(x: 0, y: railY + 10 * s, width: size.width, height: 2.4 * s)),
                     with: .color(metal.opacity(0.85)))
        for index in 0..<9 {
            let x = size.width * CGFloat(index) / 8
            context.fill(Path(roundedRect: CGRect(x: x - 2 * s, y: railY - 6 * s,
                                                  width: 4 * s, height: 28 * s),
                              cornerRadius: 1),
                         with: .color(post))
        }

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 32 * s,
                             midX: 0.42, midY: grassY - 38 * s, midCX: 0.18, midCY: grassY - 52 * s,
                             endY: grassY - 28 * s, endCX: 0.80, endCY: grassY - 48 * s,
                             colors: [Color(red: 0.78, green: 0.64, blue: 0.40),
                                      Color(red: 0.62, green: 0.48, blue: 0.28)])

        // Watering hole, left-back — not in the playable centre.
        let pool = CGRect(x: size.width * 0.04, y: grassY - 36 * s,
                          width: size.width * 0.22, height: 18 * s)
        context.fill(Path(ellipseIn: pool), with: .radialGradient(
            Gradient(colors: [Color(red: 0.28, green: 0.58, blue: 0.68),
                              Color(red: 0.12, green: 0.34, blue: 0.46)]),
            center: CGPoint(x: pool.midX, y: pool.midY),
            startRadius: 4, endRadius: pool.width * 0.55))
        context.stroke(Path(ellipseIn: pool.insetBy(dx: -1.5 * s, dy: -1.5 * s)),
                       with: .color(Color(red: 0.40, green: 0.32, blue: 0.20).opacity(0.55)),
                       lineWidth: 2 * s)
        context.fill(Path(ellipseIn: CGRect(x: pool.minX + pool.width * 0.18,
                                            y: pool.minY + pool.height * 0.18,
                                            width: pool.width * 0.28, height: pool.height * 0.22)),
                     with: .color(Color.white.opacity(0.28)))

        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.28, y: grassY - 22 * s),
                         radius: 16 * s, seed: 141,
                         fill: Color(red: 0.52, green: 0.46, blue: 0.40),
                         highlight: Color(red: 0.70, green: 0.64, blue: 0.56))
        HabitatDraw.rock(context, centre: CGPoint(x: size.width * 0.86, y: grassY - 24 * s),
                         radius: 18 * s, seed: 142,
                         fill: Color(red: 0.50, green: 0.44, blue: 0.38),
                         highlight: Color(red: 0.68, green: 0.62, blue: 0.54))
        HabitatDraw.driftwood(context,
                              origin: CGPoint(x: size.width * 0.72, y: grassY - 20 * s),
                              width: 58 * s, height: 14 * s)

        HabitatDraw.fillBand(context, width: size.width, bottom: bottom,
                             startY: grassY - 16 * s,
                             midX: 0.50, midY: grassY - 20 * s, midCX: 0.26, midCY: grassY - 32 * s,
                             endY: grassY - 14 * s, endCX: 0.82, endCY: grassY - 28 * s,
                             colors: [ground.lushMid, ground.lushDeep])

        // Subtle visitor shelter, far left background.
        let roof = CGRect(x: size.width * 0.01, y: grassY - 78 * s, width: 44 * s, height: 8 * s)
        context.fill(Path(roundedRect: roof, cornerRadius: 2),
                     with: .color(Color(red: 0.55, green: 0.32, blue: 0.16)))
        context.fill(Path(CGRect(x: size.width * 0.03, y: grassY - 70 * s, width: 4 * s, height: 22 * s)),
                     with: .color(Color(red: 0.40, green: 0.28, blue: 0.16)))
        context.fill(Path(CGRect(x: size.width * 0.10, y: grassY - 70 * s, width: 4 * s, height: 22 * s)),
                     with: .color(Color(red: 0.40, green: 0.28, blue: 0.16)))
    }

    static func drawElephantProp(_ context: GraphicsContext, size: CGSize,
                                 grassY: CGFloat, scale: CGFloat, scatter: CGFloat) {
        let pivot = CGPoint(x: 56 * scale, y: grassY - 36 * scale)
        guard let layer = HabitatDraw.blown(context, pivot: pivot, direction: -1,
                                            scatter: scatter, size: size) else { return }
        let wood = Color(red: 0.62, green: 0.42, blue: 0.22)
        let woodDark = Color(red: 0.38, green: 0.22, blue: 0.10)
        let start: CGFloat = -10 * scale
        let width = min(size.width * 0.40, 148 * scale)
        let top = grassY - 72 * scale
        for railY in [top + 18 * scale, top + 38 * scale] {
            layer.fill(Path(roundedRect: CGRect(x: start, y: railY, width: width, height: 7 * scale),
                            cornerRadius: 2),
                       with: .color(wood))
            layer.stroke(Path(roundedRect: CGRect(x: start, y: railY, width: width, height: 7 * scale),
                              cornerRadius: 2),
                         with: .color(woodDark.opacity(0.55)), lineWidth: 1.1 * scale)
        }
        for fraction in [0.10, 0.38, 0.66, 0.94] as [CGFloat] {
            let x = start + width * fraction
            var post = Path()
            post.move(to: CGPoint(x: x - 6 * scale, y: grassY - 8 * scale))
            post.addLine(to: CGPoint(x: x - 6 * scale, y: top + 6 * scale))
            post.addLine(to: CGPoint(x: x, y: top))
            post.addLine(to: CGPoint(x: x + 6 * scale, y: top + 6 * scale))
            post.addLine(to: CGPoint(x: x + 6 * scale, y: grassY - 8 * scale))
            post.closeSubpath()
            layer.fill(post, with: .color(Color(red: 0.78, green: 0.56, blue: 0.30)))
            layer.stroke(post, with: .color(woodDark.opacity(0.6)), lineWidth: 1.2 * scale)
        }
        // Small visitor plaque, no readable copy.
        let plaque = CGRect(x: start + width * 0.28, y: top + 22 * scale,
                            width: 36 * scale, height: 12 * scale)
        layer.fill(Path(roundedRect: plaque, cornerRadius: 2),
                   with: .color(Color(red: 0.82, green: 0.78, blue: 0.62)))
        layer.stroke(Path(roundedRect: plaque, cornerRadius: 2),
                     with: .color(woodDark.opacity(0.45)), lineWidth: 0.8 * scale)
    }

    static func drawElephantLip(_ context: GraphicsContext, size: CGSize, grassY: CGFloat,
                                scale: CGFloat, hidden: (CGFloat) -> Bool) {
        for rock in [(0.05, 9), (0.13, 7), (0.22, 8), (0.62, 7), (0.90, 9), (0.97, 7)] as [(CGFloat, CGFloat)] {
            let x = size.width * rock.0
            if hidden(x) { continue }
            HabitatDraw.rock(context, centre: CGPoint(x: x, y: grassY - 4 * scale),
                             radius: rock.1 * scale, seed: Int(rock.0 * 90),
                             fill: Color(red: 0.50, green: 0.44, blue: 0.38),
                             highlight: Color(red: 0.68, green: 0.62, blue: 0.54))
        }
        for index in [0, 8] {
            let x = size.width * (index == 0 ? 0.08 : 0.86)
            if hidden(x) { continue }
            HabitatDraw.blade(context, root: CGPoint(x: x, y: grassY - 2 * scale),
                              height: 13 * scale, lean: 4 * scale, halfWidth: 1.2 * scale,
                              color: HabitatWorld.ground(for: .elephant).lushLight)
        }
    }
}
