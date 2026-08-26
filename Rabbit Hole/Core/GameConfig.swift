//
//  GameConfig.swift
//  Elephant Challenge: Math Memory
//
//  The single source of truth for every tunable gameplay number. Nothing in the
//  game may hardcode a life count, a probability, a duration or an unlock
//  requirement — it is declared here and read from here.
//

import Foundation

// MARK: - Central configuration

nonisolated public enum GameConfig {

    // MARK: Answers

    /// How many answers a question offers. One fixed number for every topic and
    /// every combination: one crab walks in from each of the four corners, so a
    /// wave is always one right answer and three wrong ones. It used to be a
    /// choice between two, three and four, which made every level three
    /// separate scoreboards aiming at three different targets — see
    /// `migrateToFixedAnswerCount` for how those were merged back into one.
    public static let answerBubbleCount = 4

    /// Wrong answers a question must supply: every bubble but the right one.
    public static var distractorCount: Int { answerBubbleCount - 1 }

    // MARK: Lives

    /// Lives a session starts with. Lives are tracked internally in half units.
    public static let startingLives = 3.0
    /// Smashing the crab that carries the right answer costs one whole life.
    public static let wrongAnswerCost = 1.0

    /// Internal granularity: lives are stored as an integer number of halves,
    /// so no floating point rounding can ever strand the player on 0.4999
    /// lives.
    public static let lifeGranularity = 2
    public static var startingLifeHalves: Int { Int(startingLives * Double(lifeGranularity)) }
    public static var wrongAnswerCostHalves: Int { Int(wrongAnswerCost * Double(lifeGranularity)) }

    // MARK: King Crab

    // MARK: Rabbit Hole

    /// A floor has between four and seven carrots, plus one dynamite stick.
    /// Seven is the physical maximum: the eighth pocket belongs to the bomb.
    public static let rabbitHoleMinimumCarrotCount = 4
    public static let rabbitHoleCarrotCount = 7
    /// Two extra carrots are the complete correction budget for wrong carrots
    /// and premature bomb explosions. Unused extras disappear on the final floor.
    public static let rabbitHoleCorrectionCarrots = 2
    /// Fuse on every floor. Hitting zero blows the floor open.
    public static let rabbitHoleDynamiteSeconds = 60.0
    /// Floor counts are deliberately not a single points-per-floor formula.
    /// Together with a shuffled carrot distribution this keeps the descent
    /// from becoming predictable while retaining the requested campaign size.
    public static func rabbitHoleFloorCount(maximum: Int) -> Int {
        switch maximum {
        case orderLevelMaximum: return 4
        case randomLevelMaximum: return 6
        case mixedLevelMaximum: return 7
        case supermixLevelMaximum: return 8
        default:
            return max(1, Int((Double(maximum + rabbitHoleCorrectionCarrots) / 6.0).rounded(.up)))
        }
    }
    /// Full left–right–left cycle of the crane hook. Slow enough that a
    /// tighter grab window is still hittable.
    public static let rabbitHoleSwingPeriod = 6.2
    /// Peak swing, in radians.
    public static let rabbitHoleSwingAmplitude = 0.92
    /// Share of the peak swing that item lanes may use, so the outer carrots
    /// are not hanging on the last degree of the arc.
    public static let rabbitHoleLaneFill = 0.86
    /// Placement fan as a share of peak swing. Wide enough that some carrots
    /// sit near the sides; the hook still overshoots them.
    public static let rabbitHolePlaceFill = 0.86
    /// Carrots plus the dynamite stick: one swing lane each.
    public static var rabbitHoleLaneCount: Int { rabbitHoleCarrotCount + 1 }
    public static var rabbitHoleLaneSpan: Double { rabbitHoleSwingAmplitude * rabbitHoleLaneFill }
    /// Equal angle between neighbouring lanes across the usable swing.
    public static var rabbitHoleLaneGap: Double {
        (2 * rabbitHoleLaneSpan) / Double(max(1, rabbitHoleLaneCount - 1))
    }
    /// A carrot owns almost its complete half-lane on either side. A tiny dead
    /// zone at the midpoint keeps an exactly ambiguous tap from stealing a
    /// neighbour, while still leaving every carrot a generous catch window.
    public static var rabbitHoleGrabAngle: Double { rabbitHoleLaneGap * 0.55 }
    /// Dynamite deliberately has a smaller intentional catch window. Its body
    /// can still be touched by a genuinely off-target claw, but it should not
    /// claim the edge of a neighbouring carrot's lane.
    public static var rabbitHoleDynamiteGrabAngle: Double { rabbitHoleLaneGap * 0.32 }
    /// Where the dirt begins, as a share of the screen height. The grass sits
    /// on that lip; the rabbit stands on the grass.
    public static let rabbitHoleGrassShare = 0.50
    /// On-screen size of a carrot (and the dynamite bundle). iPad needs a
    /// stronger step than the old phone-like scaling: its playfield grows far
    /// more than 22 points, especially in landscape.
    public static func rabbitHoleCarrotSize(isPad: Bool) -> CGFloat { isPad ? 122 : 77 }
    /// The illustrated floor items leave a little more dirt visible between
    /// lanes than the original drawn placeholders did.
    public static let rabbitHoleItemDisplayScale: CGFloat = 0.90
    /// Full drawn height of a carrot, leaves included.
    public static func rabbitHoleCarrotLength(isPad: Bool) -> CGFloat {
        rabbitHoleCarrotSize(isPad: isPad) * 1.35
    }
    public static func rabbitHoleDisplayedItemLength(isPad: Bool) -> CGFloat {
        rabbitHoleCarrotLength(isPad: isPad) * rabbitHoleItemDisplayScale
    }
    /// Rest-centre offset so the leafy top sits a quarter carrot-length under the grass.
    public static let rabbitHoleBurialFactor: CGFloat = 0.80
    /// Closest two pocket centres may sit, as a share of carrot length.
    public static let rabbitHoleMinSeparationFactor: CGFloat = 1.18
    /// Half-width used to keep neighbouring swing rays clear of a carrot body.
    public static func rabbitHoleItemRadius(isPad: Bool) -> CGFloat {
        rabbitHoleCarrotSize(isPad: isPad) * 0.42
    }
    public static let rabbitHoleDropDuration = 0.18
    public static let rabbitHoleWriggleDuration = 0.30
    public static let rabbitHoleRaiseDuration = 0.22
    public static let rabbitHoleCorrectTossDuration = 0.62
    public static let rabbitHoleWrongTossDuration = 0.36
    public static let rabbitHoleExplosionDuration = 0.80
    public static let rabbitHoleFallDuration = 1.00
    public static let rabbitHoleEntranceDuration = 0.90
    /// Finale flight (1.18 s) followed by an unhurried 0.8-second drive-off.
    public static let rabbitHoleYayDuration = 1.98

    /// How long a crab needs from its corner to the King. The whole round is
    /// read, judged and acted on inside this window, so it is the single most
    /// important number of the game.
    public static let crabWalkDuration = 6.0

    /// A crab carrying a wrong answer that reaches the King costs half a life.
    /// The round itself carries on: the right answer is still out there.
    public static let breachCostHalves = 1

    // MARK: Life crab

    /// The comeback crab appears at most once a game, and only from the moment
    /// the player first drops to this many half-lives (one life) or fewer.
    public static let lifeCrabCriticalHalves = 2
    /// Correct answers required after that drop before it may set off, so the
    /// reward follows recovered play rather than the damage itself.
    public static let lifeCrabCorrectAnswers = 2
    /// It never appears once the board is this far along — a comeback near the
    /// finish line is no comeback at all.
    public static let lifeCrabMaximumProgress = 0.9
    /// Reaching the King hands back one whole life.
    public static let lifeCrabRecoveryHalves = 2

    // MARK: Session

    /// A session ends when the board's own target is reached (`LevelBoard
    /// .maximum`) or the lives run out — never on a flat round count, which is
    /// what used to stop a 50-bubble board at around 24.
    ///
    /// Every round pays at least one bubble, so a board can always be filled
    /// within `maximum` rounds. This is the ceiling across every board, used
    /// only to sanity-check a stored session.
    public static var maximumRoundCeiling: Int { supermixLevelMaximum }

    /// Cards awarded for a correct answer on a normal card.
    public static let normalCardReward = 1

    // MARK: Bonuses

    /// Retired King Crab leftovers. Rabbit Hole has no streak speed boost,
    /// no 2× crab, and no double points on a streak: the crane keeps one
    /// swing pace, and every correct carrot pays `normalCardReward`.
    public static let streakThreshold = 5
    public static let streakMultiplier = 1
    public static let streakSpeedMultiplier = 1.0
    public static let streakWrongAnswerCostHalves = 1
    public static let bonusFishCount = 0...0
    public static let bonusFishMultiplier = 1

    // MARK: Timing (seconds)
    //
    // The brief is explicit: the next round must be able to start within
    // roughly 300–600 ms. These are the only durations gameplay may use.

    /// Card flip animation.
    public static let cardFlipDuration = 0.28
    /// Answer cards fading/scaling in once the question is visible.
    public static let answerRevealDuration = 0.18
    /// How long correct/wrong feedback stays on screen before the next round.
    public static let correctFeedbackDuration = 0.32
    public static let wrongFeedbackDuration = 0.55
    /// Gap between feedback ending and the next round's closed cards appearing.
    public static let roundTransitionDuration = 0.12

    /// Total time from answering to the next round being interactive.
    public static var nextRoundDelay: (correct: Double, wrong: Double) {
        (correctFeedbackDuration + roundTransitionDuration,
         wrongFeedbackDuration + roundTransitionDuration)
    }

    // MARK: Levels

    /// Levels available without Premium.
    public static let freeLevelCount = 12
    /// Highest level Premium unlocks.
    public static let maximumLevel = 99

    /// How strongly question selection leans toward the highest available
    /// sub-level. Weight of sub-level i (1-based) is `i ^ levelWeightExponent`,
    /// so lower levels stay in the mix but the top of the range dominates.
    public static let levelWeightExponent = 1.0
    /// The selected level itself is guaranteed at least this share of rounds,
    /// so "the highest available difficulty appears regularly" is not left to
    /// chance on a level-40 run.
    public static let topLevelMinimumShare = 0.35

    // MARK: Characters

    /// Total earned cards required to unlock each character, in catalog order.
    /// Index 0 is the starter character and is therefore always 0.
    ///
    /// The second half of the catalog is Premium-exclusive: `nil` means the
    /// character cannot be earned with cards at all, no matter the total.
    public static let characterUnlockRequirements: [Int?] = [
        0,          // bunny — from the start
        500,        // dog
        1_500,      // lion
        3_000,      // octopus
        5_000,      // crab
        nil, nil, nil, nil, nil   // elephant, bear, fox, frog, penguin — Premium
    ]

    // MARK: Level progress

    /// What a full score is worth depends on the chosen exercise. Supermix is
    /// intentionally the only route that goes all the way to 50 bubbles.
    public static let orderLevelMaximum = 20
    public static let randomLevelMaximum = 30
    public static let mixedLevelMaximum = 40
    public static let supermixLevelMaximum = 50

    /// Default used by views before they receive their concrete board.
    public static let levelMaximum = mixedLevelMaximum

    /// Ceiling on the "reached the maximum ×N" tally, so a long-lived save
    /// cannot grow the badge without bound.
    public static let maximumCompletionCount = 100

    /// The three progress dots fill at these shares of `levelCompletionCards`,
    /// so the card art follows the economy instead of hardcoded scores.
    public static let levelTierShares = [0.01, 0.4, 0.75]

    // MARK: Storage

    /// Bumped whenever the persisted shape changes; drives migration.
    public static let storageVersion = 4
}
