//
//  ExcavatorKit.swift
//  Rabbit Hole
//
//  Each catalog character's excavator is the same 1552×1531 canvas: body
//  without the operator arm, then poke, then arm, with shared `top_part`
//  and `claw` on the original hub.
//
//  Pre and after art are both kept. Rest draws pre untransformed; a full
//  grab draws after untransformed so placement matches the authored thrown
//  pose. In between, the poke hinges clockwise around its foot (SwiftUI
//  positive is clockwise) and the arm slides.
//

import SwiftUI

/// Layered excavator parts for one catalog character, plus the arm slide and
/// poke hinge measured off that character's rest and thrown artwork.
struct ExcavatorKit {
    let body: String
    let pokePre: String
    let pokeAfter: String
    let armPre: String
    let armAfter: String
    /// Canvas-pixel slide of the operator arm from rest → thrown.
    let armSlide: CGSize
    /// Foot of the poke stick on the shared canvas, as a unit point.
    let pokePivot: UnitPoint
    /// SwiftUI degrees taking the rest poke onto the thrown pose.
    /// Positive is clockwise, which throws the knob to the right.
    let pokeThrowDegrees: Double
    /// Underside of the rear crawler's back rounding, in canvas pixels.
    /// Underground placement sits this point on the pit lip so machines of
    /// slightly different track silhouettes share one visual contact.
    let canvasRearContact: CGPoint

    static func kit(for characterID: String) -> ExcavatorKit {
        kits[characterID] ?? kits["bunny"]!
    }

    private static let canvas = RabbitHoleCraneLayout.canvasSize

    private static func pivot(_ x: CGFloat, _ y: CGFloat) -> UnitPoint {
        UnitPoint(x: x / canvas.width, y: y / canvas.height)
    }

    /// Source PNG prefix on the shared canvas, matching catalog order:
    /// bunny 1, dog 2, lion 3, octopus 4, crab 5, elephant 6, bear 7, fox 8,
    /// frog 9, penguin 10.
    private static let kits: [String: ExcavatorKit] = [
        "bunny": ExcavatorKit(
            body: "1_no_arm",
            pokePre: "1_poke_pre", pokeAfter: "1_poke_after",
            armPre: "1_arm_pre", armAfter: "1_arm_after",
            armSlide: CGSize(width: 10, height: 0),
            pokePivot: pivot(509.90, 933.81),
            pokeThrowDegrees: 17.00,
            canvasRearContact: CGPoint(x: 112, y: 1402)),
        "dog": ExcavatorKit(
            body: "2_no_arm",
            pokePre: "2_poke_pre", pokeAfter: "2_poke_after",
            armPre: "2_arm_pre", armAfter: "2_arm_after",
            armSlide: CGSize(width: 13, height: 4),
            pokePivot: pivot(513.34, 935.01),
            pokeThrowDegrees: 12.75,
            canvasRearContact: CGPoint(x: 111, y: 1401)),
        "lion": ExcavatorKit(
            body: "3_no_arm",
            pokePre: "3_poke_pre", pokeAfter: "3_poke_after",
            armPre: "3_arm_pre", armAfter: "3_arm_after",
            armSlide: CGSize(width: 6, height: 5),
            pokePivot: pivot(511.61, 935.15),
            pokeThrowDegrees: 11.00,
            canvasRearContact: CGPoint(x: 117, y: 1402)),
        "octopus": ExcavatorKit(
            body: "4_no_arm",
            pokePre: "4_poke_pre", pokeAfter: "4_poke_after",
            armPre: "4_arm_pre", armAfter: "4_arm_after",
            armSlide: CGSize(width: 16, height: 0),
            pokePivot: pivot(512.21, 936.61),
            pokeThrowDegrees: 11.50,
            canvasRearContact: CGPoint(x: 118, y: 1402)),
        "crab": ExcavatorKit(
            body: "5_no_arm",
            pokePre: "5_poke_pre", pokeAfter: "5_poke_after",
            armPre: "5_arm_pre", armAfter: "5_arm_after",
            armSlide: CGSize(width: 10, height: 3),
            pokePivot: pivot(510.55, 941.50),
            pokeThrowDegrees: 17.00,
            canvasRearContact: CGPoint(x: 112, y: 1402)),
        "elephant": ExcavatorKit(
            body: "6_no_arm",
            pokePre: "6_poke_pre", pokeAfter: "6_poke_after",
            armPre: "6_arm_pre", armAfter: "6_arm_after",
            armSlide: CGSize(width: 16, height: 4),
            pokePivot: pivot(517.53, 931.55),
            pokeThrowDegrees: 22.50,
            canvasRearContact: CGPoint(x: 115, y: 1403)),
        "bear": ExcavatorKit(
            body: "7_no_arm",
            pokePre: "7_poke_pre", pokeAfter: "7_poke_after",
            armPre: "7_arm_pre", armAfter: "7_arm_after",
            armSlide: CGSize(width: 17, height: -2),
            pokePivot: pivot(512.46, 937.24),
            pokeThrowDegrees: 17.00,
            canvasRearContact: CGPoint(x: 112, y: 1401)),
        "fox": ExcavatorKit(
            body: "8_no_arm",
            pokePre: "8_poke_pre", pokeAfter: "8_poke_after",
            armPre: "8_arm_pre", armAfter: "8_arm_after",
            armSlide: CGSize(width: 15, height: -2),
            pokePivot: pivot(511.52, 933.30),
            pokeThrowDegrees: 17.00,
            canvasRearContact: CGPoint(x: 117, y: 1400)),
        "frog": ExcavatorKit(
            body: "9_no_arm",
            pokePre: "9_poke_pre", pokeAfter: "9_poke_after",
            armPre: "9_arm_pre", armAfter: "9_arm_after",
            armSlide: CGSize(width: 15, height: 2),
            pokePivot: pivot(514.81, 942.87),
            pokeThrowDegrees: 17.50,
            canvasRearContact: CGPoint(x: 112, y: 1401)),
        "penguin": ExcavatorKit(
            body: "10_no_arm",
            pokePre: "10_poke_pre", pokeAfter: "10_poke_after",
            armPre: "10_arm_pre", armAfter: "10_arm_after",
            armSlide: CGSize(width: 15, height: 0),
            pokePivot: pivot(512.56, 932.28),
            pokeThrowDegrees: 19.00,
            canvasRearContact: CGPoint(x: 114, y: 1402))
    ]
}

extension AnimalCharacter {
    var excavatorKit: ExcavatorKit { ExcavatorKit.kit(for: id) }
}
