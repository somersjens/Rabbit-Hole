//
//  KingCrabRig.swift
//  King Krab
//
//  Every character, drawn from their own limbs rather than from one flat
//  picture.
//
//  The parts of a character are exported on a single square canvas and are
//  registered to each other pixel for pixel, so stacking them at the same frame
//  — limbs down first, body last — rebuilds the character exactly as drawn.
//  Nothing here scales or nudges a part: the artwork's own placement *is* the
//  rest pose.
//
//  Each limb tapers into a connector that runs on past the joint and disappears
//  behind the shell. That buried tail is what buys the movement: a limb turns
//  around the far end of its own connector, so the end itself never moves and
//  the shaft still emerges from behind the body however far the limb has swung.
//
//  The two sides of a limb are the same drawing, so all but the King's own legs
//  ship once and the other side is that picture mirrored. `nudge` is the only
//  thing separating the two: the shift that puts the mirrored copy back where
//  its own export sat, which is how a deliberately lopsided pose survives being
//  drawn from half the artwork.
//
//  Every number below is measured off the exported alpha as a share of the
//  square, by Tools/build_rigs.py: each joint is the deep end of that limb's
//  connector, the tips are the pincers, and the ground line is the lowest foot.
//  The parts are also moved as a set until the assembled animal sits in the
//  middle of its square, so all ten stand in the same place inside their frame.
//
//  A run of legs may also be rebuilt out of copies of a single leg cut from it,
//  so that the legs step one at a time instead of the whole run swinging as a
//  board — see `LegRun` in CrabLegWalk.swift, and Tools/build_crab_leg.py for
//  the cut. The life crab walks that way. The ten characters are seen from the
//  far end of the arena and keep the plain swing; so does the 2x crab, whose
//  three legs are three bands of a rainbow and so cannot be one another.
//

import SwiftUI

// MARK: - The parts

/// One limb: its image, the joint it turns around, and how it is laid down.
struct CharacterRigLimb {
    let imageName: String
    /// The joint, in the artwork square's own coordinates. Measured from the
    /// asset: the far end of the connector, where it is deepest under the shell.
    let joint: UnitPoint
    /// True when this side reuses the other side's drawing, mirrored across the
    /// middle of the square.
    var flipped: Bool = false
    /// Where that mirrored copy has to land, as a share of the square. It is
    /// zero whenever the artwork is symmetrical about the exact middle.
    var nudge: CGSize = .zero

    var image: Image { Image(imageName) }
}

/// A character cut into a body and four limbs.
struct CharacterRig {
    let body: String
    let leftClaw: CharacterRigLimb
    let rightClaw: CharacterRigLimb
    let leftLegs: CharacterRigLimb
    let rightLegs: CharacterRigLimb
    /// Where each pincer sits at rest, in the same square. The thrown sand
    /// leaves from here, so it comes out of the claw rather than out of the
    /// middle of the animal.
    let leftClawTip: UnitPoint
    let rightClawTip: UnitPoint
    /// Where the feet come down, as a fraction of the square from its top. The
    /// legs hang past the bottom of the artwork once they are seated, so this
    /// — not the frame's own edge — is the line he stands on: his shadow, his
    /// lean and his squash all work from it.
    let groundLine: CGFloat
    /// How much of a claw stays buried when that claw is also drawn in front.
    ///
    /// Everyone but the King holds his arms *across* himself rather than behind
    /// himself: two of them are drawn that way at rest, and the rest need it the
    /// moment they raise a claw, or the cheer puts both pincers behind their own
    /// head. Those claws are laid down twice — once under the body, which is
    /// what buries the connector, and again over it with this much cut away
    /// around the joint. The cut is a circle centred on the joint, so it does
    /// not move when the claw swings, and it is kept inside the body's own
    /// outline, so the seam is never on screen. Zero leaves the claw behind the
    /// shell, which is where the King's own pincers read best.
    let clawFrontRadius: CGFloat
    /// Where something carried over the head rides, on the same square: between
    /// the two pincers and clear of the crown. Only the two helper crabs carry
    /// anything, and only they are drawn with something here.
    var hold: UnitPoint = UnitPoint(x: 0.5, y: 0.2)
    /// The legs a rebuilt run is laid out of, for a character whose legs walk
    /// one at a time rather than swinging as a set. See `LegRun`.
    ///
    /// The helper crabs cross the near lane in full view of the player, which
    /// is where a run turning as one board shows. Only the life crab can have
    /// it: the 2x crab's three legs are three bands of a rainbow, so a leg of
    /// its own copied into the other two places would repaint the animal. The
    /// ten characters the player unlocks are seen at the far end of the arena,
    /// and keep the plain swing they have always had.
    var legRun: LegRun? = nil

    var bodyImage: Image { Image(body) }

    /// How far out of his middle a pincer sits, averaged over the two claws.
    /// The arena throws sand from here, so the handful leaves the claw that
    /// swung rather than the middle of the animal.
    var clawReach: CGSize {
        CGSize(width: (abs(leftClawTip.x - 0.5) + abs(rightClawTip.x - 0.5)) / 2,
               height: ((leftClawTip.y - 0.5) + (rightClawTip.y - 0.5)) / 2)
    }

    /// Player characters no longer ship a limb rig; the excavator portrait is
    /// drawn instead. Helper crabs keep their own rigs below.
    static func rig(for characterID: String) -> CharacterRig? { nil }

    /// The 2x crab, who carries a doubling coin over his head.
    ///
    /// The helper crabs are cut and measured exactly like the ten characters —
    /// see Tools/build_helper_crabs.py — and are rigs for the same reason: they
    /// walk the near lane in full view of the player, where a flat picture
    /// sliding along the sand would be the one thing in the arena not alive.
    /// Both carry their claws up over their heads, which is where what they are
    /// bringing rides.
    static let bonusHelper = CharacterRig(
        body: "2x_body",
        leftClaw: CharacterRigLimb(imageName: "2x_left_claw",
                                   joint: UnitPoint(x: 0.274, y: 0.5575)),
        rightClaw: CharacterRigLimb(imageName: "2x_left_claw",
                                    joint: UnitPoint(x: 0.7168, y: 0.5587),
                                    flipped: true,
                                    nudge: CGSize(width: -0.0144, height: 0.0016)),
        leftLegs: CharacterRigLimb(imageName: "2x_left_leg",
                                   joint: UnitPoint(x: 0.2904, y: 0.6109)),
        rightLegs: CharacterRigLimb(imageName: "2x_left_leg",
                                    joint: UnitPoint(x: 0.7125, y: 0.6036),
                                    flipped: true,
                                    nudge: CGSize(width: -0.0056, height: -0.0088)),
        leftClawTip: UnitPoint(x: 0.1907, y: 0.1317),
        rightClawTip: UnitPoint(x: 0.7976, y: 0.1312),
        groundLine: 0.8923,
        clawFrontRadius: 0.0386,
        hold: UnitPoint(x: 0.5, y: 0.175))

    /// The comeback crab, who carries a life.
    static let lifeHelper = CharacterRig(
        body: "life_body",
        leftClaw: CharacterRigLimb(imageName: "life_left_claw",
                                   joint: UnitPoint(x: 0.2864, y: 0.5715)),
        rightClaw: CharacterRigLimb(imageName: "life_left_claw",
                                    joint: UnitPoint(x: 0.7151, y: 0.5714),
                                    flipped: true,
                                    nudge: CGSize(width: -0.0072, height: 0.0)),
        leftLegs: CharacterRigLimb(imageName: "life_left_leg",
                                   joint: UnitPoint(x: 0.287, y: 0.6105)),
        rightLegs: CharacterRigLimb(imageName: "life_left_leg",
                                    joint: UnitPoint(x: 0.7164, y: 0.6036),
                                    flipped: true,
                                    nudge: CGSize(width: -0.0088, height: -0.0088)),
        leftClawTip: UnitPoint(x: 0.2042, y: 0.1305),
        rightClawTip: UnitPoint(x: 0.7959, y: 0.1295),
        groundLine: 0.8923,
        clawFrontRadius: 0.0517,
        hold: UnitPoint(x: 0.5, y: 0.175),
        legRun: LegRun(legs: ["life_leg1", "life_leg2", "life_leg3"]))
}

// MARK: - The pose

/// What the rig is doing this frame. Everything the King can do — breathing,
/// scuttling on, throwing sand, hopping, running off — is expressed as one of
/// these, so the view itself holds no state and no animation of its own.
struct KingRigPose {
    /// Whole-body tilt, degrees clockwise.
    var lean: Double = 0
    /// Vertical bob, as a share of the King's own size.
    var rise: CGFloat = 0
    /// Above 1 he is stretched tall, below 1 squashed wide. Volume is kept.
    var stretch: CGFloat = 1
    var leftClaw: Double = 0
    var rightClaw: Double = 0
    var leftLegs: Double = 0
    var rightLegs: Double = 0
    /// The walk cycle itself, in radians. The two angles above are the whole
    /// run swinging as one; a character whose run is cut into its own legs —
    /// see `CharacterRig.legRun` — needs the cycle rather than the angle, so
    /// each leg can take its turn in it.
    var stride: Double = 0

    /// The resting pose: a slow breath and legs that shift their weight.
    /// `effort` lifts the same gait into a scuttle without ever changing its
    /// rate mid-stride, which is what keeps a walk-on from snapping.
    static func idle(clock: Double, stride: Double, effort: Double) -> KingRigPose {
        let swing = sin(stride)
        let amount = 2.8 + 13 * effort
        return KingRigPose(
            lean: sin(clock * 1.4) * 1.6 + swing * 4.5 * effort,
            rise: CGFloat(abs(sin(stride))) * CGFloat(0.034 * effort),
            stretch: 1 + CGFloat(sin(clock * 1.9)) * 0.012,
            // The claws ride the body rather than hanging off it, so they lag
            // the stride a quarter turn.
            leftClaw: sin(clock * 1.1) * 3.2 + sin(stride - 0.8) * 7 * effort,
            rightClaw: -sin(clock * 1.1 + 0.9) * 3.2 - sin(stride - 0.8) * 7 * effort,
            // Opposite sides carry the weight in turn: that alternation is the
            // whole of what makes a row of legs read as walking.
            leftLegs: swing * amount,
            rightLegs: -swing * amount,
            stride: stride
        )
    }

    /// The walk of a crab carrying something over its head in both claws.
    ///
    /// The claws are all but still on purpose. What they are holding is drawn
    /// where the artwork holds it, so an arm that swings carries the load out
    /// of its own pincers; everything that says "walking" here is in the legs
    /// and in the body riding over them.
    static func carrying(clock: Double, stride: Double) -> KingRigPose {
        let swing = sin(stride)
        return KingRigPose(
            lean: sin(clock * 1.7) * 1.3 + swing * 2.4,
            rise: CGFloat(abs(sin(stride))) * 0.026,
            stretch: 1 + CGFloat(sin(clock * 2.2)) * 0.014,
            leftClaw: sin(clock * 1.3) * 1.2,
            rightClaw: -sin(clock * 1.3) * 1.2,
            leftLegs: swing * 15,
            rightLegs: -swing * 15,
            stride: stride
        )
    }
}

// MARK: - The view

/// Draws a rigged character. Limbs go down first and the body last, so every
/// joint is covered by the shell however far its limb has turned. A character
/// who carries his arms in front of himself gets those two claws a second time
/// on top, with the joint itself cut back out of that copy.
///
/// Anything the character is carrying is laid in between those two passes: over
/// the body, under the front copy of the claws — so the pincers close on it
/// rather than the load being pasted across them.
struct RiggedCharacterView<Carried: View>: View {
    let rig: CharacterRig
    let pose: KingRigPose
    let size: CGFloat
    @ViewBuilder let carried: () -> Carried

    /// How much wider than the artwork square the flattened layer is. Claws at
    /// rest already reach the square's edge; a throw or cheer swings them past
    /// it, and `drawingGroup` would shear them off without this margin.
    static var canvasScale: CGFloat { 1.85 }

    var body: some View {
        // Artwork lives on a `size` square; the canvas is wider so a swung claw
        // is not clipped by `drawingGroup` (which always clips to its frame).
        let canvas = size * Self.canvasScale
        ZStack {
            legs(rig.leftLegs, side: 1, degrees: pose.leftLegs)
            legs(rig.rightLegs, side: -1, degrees: pose.rightLegs)
            limb(rig.leftClaw, degrees: pose.leftClaw)
            limb(rig.rightClaw, degrees: pose.rightClaw)
            rig.bodyImage
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            carried()
                .offset(x: (rig.hold.x - 0.5) * size, y: (rig.hold.y - 0.5) * size)
            if rig.clawFrontRadius > 0 {
                limb(rig.leftClaw, degrees: pose.leftClaw, cutAtJoint: true)
                limb(rig.rightClaw, degrees: pose.rightClaw, cutAtJoint: true)
            }
        }
        .frame(width: canvas, height: canvas)
        // Squashing and stretching around the feet rather than the middle is
        // what makes a landing land: he compresses onto the sand, not into it.
        .scaleEffect(x: 1 / pose.stretch, y: pose.stretch, anchor: ground)
        .rotationEffect(.degrees(pose.lean), anchor: ground)
        .offset(y: -size * pose.rise)
        // One Metal layer for the whole rig — claw cutouts and stepped legs
        // otherwise re-composite as separate Images every display frame.
        .drawingGroup(opaque: false)
    }

    /// The line his feet come down on, which is what all of him pivots around.
    /// Mapped from the artwork square into the wider canvas so stretch and lean
    /// still hinge on the feet rather than on empty padding below them.
    private var ground: UnitPoint {
        let scale = Self.canvasScale
        let top = 0.5 * (1 - 1 / scale)
        return UnitPoint(x: 0.5, y: top + rig.groundLine / scale)
    }

    /// A run of legs. Where one has been cut out of the artwork, the run is
    /// laid out of copies of it and each takes its own turn in the stride — see
    /// `LegRun` — with a little of the whole run's swing left under them, which
    /// is the hip itself rocking with the body. A character without that cut
    /// swings its run as one, as before.
    @ViewBuilder
    private func legs(_ limb: CharacterRigLimb, side: CGFloat, degrees: Double) -> some View {
        if let run = rig.legRun {
            // Back of the run first, which is the order the artwork lays the
            // legs over each other in. Indices only — no per-frame Array copy.
            ForEach(0..<run.legs.count, id: \.self) { reverseIndex in
                let index = run.legs.count - 1 - reverseIndex
                self.limb(limb,
                          degrees: degrees * LegRun.hipShare
                              + run.degrees(leg: index,
                                            stride: pose.stride, side: side),
                          drawing: run.legs[index])
            }
        } else {
            self.limb(limb, degrees: degrees)
        }
    }

    @ViewBuilder
    private func limb(_ limb: CharacterRigLimb,
                      degrees: Double,
                      cutAtJoint: Bool = false,
                      drawing: String? = nil) -> some View {
        // A run of legs is laid down one leg at a time — the drawing to use is
        // the run's, not the limb's own. Mirroring and nudging leave the layout
        // square alone, so the joint below still means the same point on screen
        // for a limb drawn from its own artwork and for one drawn from the
        // other side's.
        let laid = Image(drawing ?? limb.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(x: limb.flipped ? -1 : 1, y: 1)
            .offset(x: size * limb.nudge.width, y: size * limb.nudge.height)

        Group {
            if cutAtJoint {
                laid.mask {
                    JointCutout(joint: limb.joint, radius: rig.clawFrontRadius)
                        .fill(style: FillStyle(eoFill: true))
                }
            } else {
                laid
            }
        }
        .rotationEffect(.degrees(degrees), anchor: limb.joint)
    }
}

/// A character carrying nothing, which is every one of the ten the player can
/// unlock. Only the helper crabs bring something with them.
extension RiggedCharacterView where Carried == EmptyView {
    init(rig: CharacterRig, pose: KingRigPose, size: CGFloat) {
        self.init(rig: rig, pose: pose, size: size) { EmptyView() }
    }
}

/// The square with a hole punched in it at a limb's joint. Filled even-odd, it
/// masks away everything the shell is meant to be hiding.
private struct JointCutout: Shape {
    let joint: UnitPoint
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        let centre = CGPoint(x: rect.minX + joint.x * rect.width,
                             y: rect.minY + joint.y * rect.height)
        let r = radius * rect.width
        path.addEllipse(in: CGRect(x: centre.x - r, y: centre.y - r,
                                   width: r * 2, height: r * 2))
        return path
    }
}
