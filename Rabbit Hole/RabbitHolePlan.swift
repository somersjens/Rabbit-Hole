//
//  RabbitHolePlan.swift
//  Rabbit Hole
//
//  Builds one underground floor from the remaining sums: four to seven carrots
//  and one dynamite stick. Lanes are spaced across the hook's usable swing so
//  each pocket has its own grab angle. Leaf tops hang a quarter carrot-length
//  below the grass; inner lanes take the pit floor, outer lanes stay shallower,
//  and a minimum gap keeps neighbours from overlapping.
//

import Foundation
import CoreGraphics

/// One pocket on the current floor.
struct RabbitHoleSlot: Identifiable, Equatable {
    enum Kind: Equatable {
        case carrot(text: String)
        case dynamite(isFinal: Bool)
        case empty
    }

    let id: UUID
    let kind: Kind
    /// 0...7 along the fan, left to right.
    let index: Int

    var text: String? {
        if case .carrot(let text) = kind { return text }
        return nil
    }

    var isDynamite: Bool {
        if case .dynamite = kind { return true }
        return false
    }

    var isFinalDynamite: Bool {
        if case .dynamite(let isFinal) = kind { return isFinal }
        return false
    }

    var isEmpty: Bool {
        if case .empty = kind { return true }
        return false
    }
}

/// Pocket centres for one floor, in unit field coordinates (0...1).
struct RabbitHoleLayout: Equatable {
    var units: [CGPoint]
    var dynamiteIndex: Int

    static let pocketCount = 8

    func point(index: Int, in field: CGRect) -> CGPoint {
        guard !units.isEmpty else {
            return CGPoint(x: field.midX, y: field.midY)
        }
        let unit = units[max(0, min(units.count - 1, index))]
        return CGPoint(x: field.minX + field.width * unit.x,
                       y: field.minY + field.height * unit.y)
    }

    func points(in field: CGRect) -> [CGPoint] {
        (0..<units.count).map { point(index: $0, in: field) }
    }

    func highestPoint(in field: CGRect) -> CGPoint {
        points(in: field).min { $0.y < $1.y } ?? point(index: 0, in: field)
    }

    func lowestPoint(in field: CGRect) -> CGPoint {
        points(in: field).max { $0.y < $1.y } ?? point(index: dynamiteIndex, in: field)
    }
}

enum RabbitHolePlanner {
    static let pocketCount = RabbitHoleLayout.pocketCount

    static func makeFloor(
        remaining: [MathQuestion],
        carrotCount: Int,
        isLast: Bool,
        floorIndex: Int = 0,
        field: CGRect,
        pivot: CGPoint,
        itemRadius: CGFloat,
        carrotLength: CGFloat,
        random: RandomSource = RandomSource()
    ) -> (slots: [RabbitHoleSlot], layout: RabbitHoleLayout) {
        let layout = makeLayout(floorIndex: floorIndex,
                                field: field,
                                pivot: pivot,
                                itemRadius: itemRadius,
                                carrotLength: carrotLength,
                                random: random)
        // Every carrot is the answer to one concrete remaining question. If it
        // is taken early, that exact future question can therefore be removed
        // from the queue instead of ever appearing without its answer.
        let target = min(GameConfig.rabbitHoleCarrotCount, max(0, carrotCount))
        let carrotTexts = random.shuffled(
            Array(remaining.prefix(target).map(\.correctAnswer))
        )
        let carrotIndices = Array(random.shuffled(
            (0..<pocketCount).filter { $0 != layout.dynamiteIndex }
        ).prefix(carrotTexts.count))
        let textByIndex = Dictionary(uniqueKeysWithValues: zip(carrotIndices, carrotTexts))

        let slots: [RabbitHoleSlot] = (0..<pocketCount).map { index in
            if index == layout.dynamiteIndex {
                return RabbitHoleSlot(id: UUID(),
                                      kind: .dynamite(isFinal: isLast),
                                      index: index)
            }
            guard let text = textByIndex[index] else {
                return RabbitHoleSlot(id: UUID(), kind: .empty, index: index)
            }
            return RabbitHoleSlot(id: UUID(), kind: .carrot(text: text), index: index)
        }
        return (slots, layout)
    }

    /// Even swing lanes across the hook's usable arc. Leaf tops hang a quarter
    /// carrot-length below the grass. Depths zigzag across the fan so some
    /// pockets sit near the sides, some in the middle, and a couple on the floor.
    static func makeLayout(floorIndex: Int,
                           field: CGRect,
                           pivot: CGPoint,
                           itemRadius: CGFloat,
                           carrotLength: CGFloat,
                           random: RandomSource) -> RabbitHoleLayout {
        let n = pocketCount
        let usable = field.width > 10 && field.height > 10
            ? field
            : CGRect(x: 0, y: 0, width: 390, height: 560)
        let origin = (field.width > 10)
            ? pivot
            : CGPoint(x: usable.midX, y: usable.minY - 40)

        let pad = max(itemRadius * 0.95, usable.width * 0.07)
        // Rest is the carrot centre; leaves sit ~0.55 lengths above it, so this
        // keeps the leafy top a quarter carrot-length under the grass lip.
        let burial = carrotLength * GameConfig.rabbitHoleBurialFactor
        let minSep = carrotLength * GameConfig.rabbitHoleMinSeparationFactor
        let dirt = usable.insetBy(dx: pad, dy: 0)
        let lip = usable.minY + max(12, carrotLength * 0.12)
        let pitBottom = usable.maxY - pad
        let dirtBox = CGRect(x: dirt.minX,
                             y: lip,
                             width: dirt.width,
                             height: max(48, pitBottom - lip))

        var span = CGFloat(GameConfig.rabbitHoleSwingAmplitude * GameConfig.rabbitHolePlaceFill)
        for _ in 0..<8 {
            if rayRange(origin: origin, angle: span, rect: dirtBox) != nil { break }
            span *= 0.94
        }

        let gap = (2 * span) / CGFloat(max(1, n - 1))
        // Keep just enough irregularity for an organic floor without giving
        // one pocket a visibly narrower aiming interval than its neighbours.
        let jitterCap = gap * 0.035
        var angles: [CGFloat] = (0..<n).map { i in
            var angle = -span + CGFloat(i) * gap
            if i > 0, i < n - 1 {
                angle += CGFloat(random.double(in: Double(-jitterCap)..<Double(jitterCap)))
            }
            return angle
        }
        angles.sort()

        // Zigzag depths left → right: outer lanes get enough depth to reach
        // the sides, inner lanes mix high and low so the middle is not a stack.
        var mixes: [CGFloat] = floorIndex.isMultiple(of: 2)
            ? [0.72, 0.16, 0.90, 0.38, 0.58, 0.96, 0.22, 0.70]
            : [0.64, 0.28, 0.50, 0.94, 0.34, 0.80, 0.14, 0.76]
        if floorIndex % 3 == 1 { mixes.reverse() }
        if floorIndex % 5 == 2 { mixes.swapAt(2, 5) }
        var depthForLane = [CGFloat](repeating: 0.5, count: n)
        for i in 0..<n {
            let jitter = CGFloat(random.double(in: -0.05..<0.05))
            depthForLane[i] = min(1, max(0.06, mixes[i] + jitter))
        }

        var points: [CGPoint] = []
        points.reserveCapacity(n)
        for i in 0..<n {
            points.append(pointOnRay(origin: origin,
                                     angle: angles[i],
                                     depth: depthForLane[i],
                                     box: dirtBox,
                                     grassY: usable.minY,
                                     burial: burial))
        }

        separateAlongRays(points: &points,
                          angles: angles,
                          origin: origin,
                          box: dirtBox,
                          grassY: usable.minY,
                          burial: burial,
                          minSep: minSep)
        staggerDeepPockets(points: &points,
                           angles: angles,
                           origin: origin,
                           box: dirtBox,
                           grassY: usable.minY,
                           burial: burial,
                           carrotLength: carrotLength)

        let units = points.map { point in
            CGPoint(x: (point.x - usable.minX) / max(1, usable.width),
                    y: (point.y - usable.minY) / max(1, usable.height))
        }

        let dynamiteIndex = chooseDynamiteIndex(points: points,
                                                in: usable,
                                                random: random)
        return RabbitHoleLayout(units: units, dynamiteIndex: dynamiteIndex)
    }

    /// Prefer the lower-middle of the floor without pinning the bomb to the
    /// bottom on every round. This keeps it out of the busier shallow grab
    /// corridors most of the time, while retaining occasional mid/deep variety.
    private static func chooseDynamiteIndex(points: [CGPoint],
                                            in field: CGRect,
                                            random: RandomSource) -> Int {
        guard !points.isEmpty else { return 0 }
        let roll = random.double(in: 0..<1)
        let targetDepth: CGFloat
        switch roll {
        case ..<0.20:
            targetDepth = CGFloat(random.double(in: 0.46..<0.62))
        case ..<0.92:
            targetDepth = CGFloat(random.double(in: 0.62..<0.79))
        default:
            targetDepth = CGFloat(random.double(in: 0.79..<0.89))
        }

        return points.indices.min { lhs, rhs in
            let leftDepth = (points[lhs].y - field.minY) / max(1, field.height)
            let rightDepth = (points[rhs].y - field.minY) / max(1, field.height)
            // Slightly discourage the two extreme swing lanes: their rotated
            // artwork otherwise spends more time against the wall.
            let leftEdgePenalty: CGFloat = (lhs == 0 || lhs == points.count - 1) ? 0.025 : 0
            let rightEdgePenalty: CGFloat = (rhs == 0 || rhs == points.count - 1) ? 0.025 : 0
            return abs(leftDepth - targetDepth) + leftEdgePenalty
                < abs(rightDepth - targetDepth) + rightEdgePenalty
        } ?? 0
    }

    /// Rest point on a boom ray at `depth` (0 = just buried, 1 = pit floor),
    /// clamped to the dirt box so outer lanes stop at the wall.
    private static func pointOnRay(origin: CGPoint,
                                   angle: CGFloat,
                                   depth: CGFloat,
                                   box: CGRect,
                                   grassY: CGFloat,
                                   burial: CGFloat) -> CGPoint {
        let range = rayRange(origin: origin, angle: angle, rect: box)
        let rBury = burialAlongRay(origin: origin, angle: angle, grassY: grassY, burial: burial)
        let spanMin = range?.min ?? rBury
        let spanMax = range?.max ?? (spanMin + carrotFallback)
        // Stay on the ray inside the pit. If burial would go through a wall,
        // sit as deep as that ray still allows instead of leaving the field.
        let rMin = min(spanMax - 16, max(spanMin, rBury))
        let rMax = max(rMin + 16, spanMax)
        let radius = rMin + min(1, max(0, depth)) * (rMax - rMin)
        return CGPoint(x: origin.x + sin(angle) * radius,
                       y: origin.y + cos(angle) * radius)
    }

    private static let carrotFallback: CGFloat = 80

    /// Push overlapping pockets along their own swing rays until they clear
    /// `minSep`, or until neither ray can improve the gap.
    private static func separateAlongRays(points: inout [CGPoint],
                                          angles: [CGFloat],
                                          origin: CGPoint,
                                          box: CGRect,
                                          grassY: CGFloat,
                                          burial: CGFloat,
                                          minSep: CGFloat) {
        let n = points.count
        for _ in 0..<10 {
            var moved = false
            for a in 0..<n {
                for b in (a + 1)..<n {
                    let dist = hypot(points[a].x - points[b].x, points[a].y - points[b].y)
                    guard dist < minSep else { continue }

                    let push = (minSep - dist) * 0.65 + 10
                    let options: [(Int, Int)] = [(a, b), (b, a)]
                    var best: (index: Int, point: CGPoint, dist: CGFloat)?
                    for (move, other) in options {
                        for delta in [push, -push] {
                            let candidate = nudgedOnRay(origin: origin,
                                                        angle: angles[move],
                                                        from: points[move],
                                                        by: delta,
                                                        box: box,
                                                        grassY: grassY,
                                                        burial: burial)
                            let next = hypot(candidate.x - points[other].x,
                                             candidate.y - points[other].y)
                            if next > dist + 1.5, next > (best?.dist ?? dist) {
                                best = (move, candidate, next)
                            }
                        }
                    }
                    if let best {
                        points[best.index] = best.point
                        moved = true
                    }
                }
            }
            if !moved { break }
        }
    }

    private static func nudgedOnRay(origin: CGPoint,
                                    angle: CGFloat,
                                    from: CGPoint,
                                    by: CGFloat,
                                    box: CGRect,
                                    grassY: CGFloat,
                                    burial: CGFloat) -> CGPoint {
        let current = hypot(from.x - origin.x, from.y - origin.y)
        let floor = pointOnRay(origin: origin, angle: angle, depth: 1,
                               box: box, grassY: grassY, burial: burial)
        let buried = pointOnRay(origin: origin, angle: angle, depth: 0,
                                box: box, grassY: grassY, burial: burial)
        let maxR = hypot(floor.x - origin.x, floor.y - origin.y)
        let minR = hypot(buried.x - origin.x, buried.y - origin.y)
        let radius = min(maxR, max(minR, current + by))
        return CGPoint(x: origin.x + sin(angle) * radius,
                       y: origin.y + cos(angle) * radius)
    }

    /// Keep at most two pockets on the pit floor; lift extras along their
    /// own rays so the bottom row is not a flat line.
    private static func staggerDeepPockets(points: inout [CGPoint],
                                           angles: [CGFloat],
                                           origin: CGPoint,
                                           box: CGRect,
                                           grassY: CGFloat,
                                           burial: CGFloat,
                                           carrotLength: CGFloat) {
        let band = carrotLength * 0.90
        var deep = (0..<points.count).filter { points[$0].y > box.maxY - band }
        guard deep.count > 2 else { return }
        deep.sort { points[$0].y > points[$1].y }
        let lifts: [CGFloat] = [0.56, 0.68, 0.46, 0.38]
        for (i, index) in deep.dropFirst(2).enumerated() {
            points[index] = pointOnRay(origin: origin,
                                       angle: angles[index],
                                       depth: lifts[min(i, lifts.count - 1)],
                                       box: box,
                                       grassY: grassY,
                                       burial: burial)
        }
    }

    /// Distance along the boom ray where the rest sits so the leafy top is
    /// a quarter carrot-length below the grass.
    private static func burialAlongRay(origin: CGPoint,
                                       angle: CGFloat,
                                       grassY: CGFloat,
                                       burial: CGFloat) -> CGFloat {
        let uy = max(0.20, cos(angle))
        return max(0, (grassY + burial - origin.y) / uy)
    }

    /// Distances along a boom ray where it first enters and then leaves `rect`.
    private static func rayRange(origin: CGPoint, angle: CGFloat, rect: CGRect) -> (min: CGFloat, max: CGFloat)? {
        let dir = CGPoint(x: sin(angle), y: cos(angle))
        var tMin: CGFloat = 0
        var tMax: CGFloat = .greatestFiniteMagnitude

        func slab(_ originC: CGFloat, _ dirC: CGFloat, _ minC: CGFloat, _ maxC: CGFloat) -> Bool {
            if abs(dirC) < 0.0008 {
                return originC >= minC && originC <= maxC
            }
            var t1 = (minC - originC) / dirC
            var t2 = (maxC - originC) / dirC
            if t1 > t2 { swap(&t1, &t2) }
            tMin = max(tMin, t1)
            tMax = min(tMax, t2)
            return tMin <= tMax
        }

        guard slab(origin.x, dir.x, rect.minX, rect.maxX) else { return nil }
        guard slab(origin.y, dir.y, rect.minY, rect.maxY) else { return nil }
        tMin = max(tMin, 0)
        guard tMax > tMin else { return nil }
        return (tMin, tMax)
    }

}
