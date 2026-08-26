//
//  Theme.swift
//  Elephant Challenge: Math Memory
//
//  Character catalog: 10 animals, each with a clearly different colour and a
//  matching visual theme for the whole app. Characters are earned by collecting
//  cards; the requirements live in `GameConfig.characterUnlockRequirements`.
//

import SwiftUI

/// The game's currency. What a player collects is whatever their character
/// eats, so the counter matches that animal: the bunny banks carrots, the frog
/// spiders, the penguin fish. The artwork is looked up by character ID so the
/// catalog order here (bunny first) cannot hand an animal the wrong food.
enum Currency {
    /// The bunny's carrot. Also the icon wherever the currency is spoken of in
    /// general rather than in one character's world — the Premium screen sells
    /// the whole cast, so it counts in carrots for all of them.
    static let icon = "currency_1"

    static func icon(for characterID: String) -> String {
        FoodCatalog.food(for: characterID).currencyIconName
    }

    /// The source files deliberately keep transparent breathing room, but a
    /// square SwiftUI frame would make the visible silhouettes feel much
    /// smaller than the text beside them. These measurements normalize the
    /// opaque bounds to the same optical size and centre them without changing
    /// the layout footprint used by menus and reward animations.
    static func opticalMetrics(for iconName: String) -> (scale: CGFloat, x: CGFloat, y: CGFloat) {
        switch iconName {
        case "currency_1":  return (1.082,  0.003,  0.000)
        case "currency_2":  return (1.184,  0.009, -0.003)
        case "currency_3":  return (1.309,  0.026, -0.036)
        case "currency_4":  return (1.368, -0.031,  0.003)
        case "currency_5":  return (1.239,  0.029, -0.005)
        case "currency_6":  return (1.309,  0.000, -0.160)
        case "currency_7":  return (1.594, -0.040, -0.004)
        case "currency_8":  return (1.215,  0.078, -0.031)
        case "currency_9":  return (1.203, -0.002, -0.013)
        case "currency_10": return (1.171,  0.003,  0.003)
        default:             return (1.000,  0.000,  0.000)
        }
    }
}

private struct CurrencyIconKey: EnvironmentKey {
    static let defaultValue = Currency.icon
}

extension EnvironmentValues {
    /// Which currency artwork every `CurrencyIcon` below this point draws.
    /// Carried in the environment rather than passed down: the counters sit
    /// deep inside level cards, HUD chips and celebration swarms, and all of
    /// them belong to whichever character owns the screen they are on.
    var currencyIcon: String {
        get { self[CurrencyIconKey.self] }
        set { self[CurrencyIconKey.self] = newValue }
    }
}

extension View {
    /// Hands this screen the character's own food to count in.
    func currencyIcon(for character: AnimalCharacter) -> some View {
        environment(\.currencyIcon, Currency.icon(for: character.id))
    }

    /// Pins a screen back to the carrot, whatever character is selected.
    func carrotCurrencyIcon() -> some View {
        environment(\.currencyIcon, Currency.icon)
    }
}

/// The artwork used anywhere a currency count is shown. It is rendered as a
/// template so existing character-theme colors continue to apply.
struct CurrencyIcon: View {
    let size: CGFloat

    @Environment(\.currencyIcon) private var iconName

    var body: some View {
        let optical = Currency.opticalMetrics(for: iconName)
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(optical.scale)
            .offset(x: size * optical.x, y: size * optical.y)
            // Preserve the requested layout footprint: the level-card flight
            // anchors and compact badges rely on this exact square on both
            // iPhone and iPad, while the artwork may draw slightly outside it.
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Kept for the old King-Krab finale specks, which still draw a scallop.
struct ShellShape: Shape {
    private static let scallops = 5

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        func point(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: rect.minX + w * x, y: rect.minY + h * y)
        }

        let hinge = point(0.5, 0.97)
        let rim: [CGPoint] = (0...Self.scallops).map { index in
            let t = Double(index) / Double(Self.scallops)
            return point(0.05 + 0.90 * t, 0.44 - 0.36 * sin(.pi * t))
        }

        var path = Path()
        path.move(to: hinge)
        path.addQuadCurve(to: rim[0], control: point(0.10, 0.82))
        for index in 1...Self.scallops {
            let previous = rim[index - 1]
            let next = rim[index]
            let mid = CGPoint(x: (previous.x + next.x) / 2, y: (previous.y + next.y) / 2)
            let dx = mid.x - hinge.x
            let dy = mid.y - hinge.y
            let length = max(0.001, (dx * dx + dy * dy).squareRoot())
            path.addQuadCurve(to: next,
                              control: CGPoint(x: mid.x + dx / length * w * 0.09,
                                               y: mid.y + dy / length * h * 0.09))
        }
        path.addQuadCurve(to: hinge, control: point(0.90, 0.82))
        path.closeSubpath()

        for index in 1..<Self.scallops {
            let tip = rim[index]
            let dx = tip.x - hinge.x
            let dy = tip.y - hinge.y
            let length = max(0.001, (dx * dx + dy * dy).squareRoot())
            let normalX = -dy / length
            let normalY = dx / length
            let width = w * 0.028
            func along(_ amount: CGFloat, _ spread: CGFloat) -> CGPoint {
                CGPoint(x: hinge.x + dx * amount + normalX * width * spread,
                        y: hinge.y + dy * amount + normalY * width * spread)
            }
            path.move(to: along(0.14, 1))
            path.addLine(to: along(0.90, 0.45))
            path.addLine(to: along(0.90, -0.45))
            path.addLine(to: along(0.14, -1))
            path.closeSubpath()
        }
        return path
    }
}

struct AnimalCharacter: Identifiable, Equatable {
    let id: String
    let name: String
    let emoji: String
    // Colour components (0–1).
    let primaryRGB: (Double, Double, Double)
    let deepRGB: (Double, Double, Double)
    let skyRGB: (Double, Double, Double)
    let tintRGB: (Double, Double, Double)

    static func == (lhs: AnimalCharacter, rhs: AnimalCharacter) -> Bool {
        lhs.id == rhs.id
    }

    var color: Color { Color(red: primaryRGB.0, green: primaryRGB.1, blue: primaryRGB.2) }
    var deepColor: Color { Color(red: deepRGB.0, green: deepRGB.1, blue: deepRGB.2) }
    var skyColor: Color { Color(red: skyRGB.0, green: skyRGB.1, blue: skyRGB.2) }
    var tintColor: Color { Color(red: tintRGB.0, green: tintRGB.1, blue: tintRGB.2) }

    /// Position in the catalog, 1-based.
    var catalogOrder: Int {
        (CharacterUnlocks.orderedCharacterIDs.firstIndex(of: id) ?? 0) + 1
    }

    /// Excavator PNG prefix. Matches catalog order, so bunny is 1, dog is 2,
    /// and so on through penguin at 10.
    var artNumber: Int { catalogOrder }

    /// Rest-pose in the excavator. Used anywhere a character portrait is drawn
    /// outside the layered in-game rig.
    var imageName: String { menuPortraitName }
    var artwork: Image { menuPortrait }

    /// Rest-pose in the excavator for the welcome screen and the shop hero:
    /// body, poke, arm, then the centre `top_part` and `claw` with no
    /// extension. Every catalog character is assembled onto the same canvas.
    var menuPortraitName: String { "\(artNumber)_full" }
    var menuPortrait: Image { Image(menuPortraitName) }

    /// Tight cab crop of the same rest-pose, framed like the home character
    /// button. All ten share the bunny's zoom so the animal fills that slot.
    var menuIconName: String { "\(artNumber)_icon" }
    var menuIcon: Image { Image(menuIconName) }

    /// Shop-grid size of the excavator portrait. Same framing as `menuPortrait`,
    /// small enough that five-across cells do not unpack a 1024-pixel image.
    var menuThumbName: String { "\(artNumber)_thumb" }
    var menuThumb: Image { Image(menuThumbName) }

    /// Stamp-size excavator portrait for the next-character line and talking
    /// heads. Same framing as `menuThumb`.
    var thumbImageName: String { menuThumbName }
    var thumbArtwork: Image { menuThumb }

    /// Limb rig, when this character is still cut into parts. Catalog animals
    /// are drawn from the excavator portrait instead.
    var rig: CharacterRig? { CharacterRig.rig(for: id) }

    /// Localized display name, resolved per language from the string catalog
    /// ("character.fox", "character.frog", …).
    var localizedName: String {
        L(key: "character.\(id)")
    }
}

enum CharacterCatalog {
    /// The character available from the very first card.
    static let freeCharacterID = CharacterUnlocks.starterCharacterID

    /// The localized fallback used when the player leaves their name empty.
    /// Resolve it through the character catalog so it can never drift from the
    /// name shown for the starter character in the active language.
    static var defaultPlayerName: String {
        character(id: freeCharacterID).localizedName
    }

    /// Order must match `CharacterUnlocks.orderedCharacterIDs`; a test asserts it.
    ///
    /// Every palette is sampled from that character's own artwork, so the reef,
    /// the menu and the motion trail behind a portrait all carry the colours
    /// the player is actually looking at.
    static let all: [AnimalCharacter] = [
        AnimalCharacter(id: "bunny", name: "Bunny", emoji: "🐰",
                        primaryRGB: (0.94, 0.45, 0.62), deepRGB: (0.72, 0.22, 0.40),
                        skyRGB: (1.00, 0.90, 0.93), tintRGB: (0.99, 0.78, 0.84)),
        AnimalCharacter(id: "dog", name: "Dog", emoji: "🐶",
                        primaryRGB: (0.20, 0.66, 0.69), deepRGB: (0.06, 0.42, 0.46),
                        skyRGB: (0.89, 0.97, 0.98), tintRGB: (0.81, 0.95, 0.96)),
        AnimalCharacter(id: "lion", name: "Lion", emoji: "🦁",
                        primaryRGB: (0.95, 0.74, 0.20), deepRGB: (0.68, 0.45, 0.08),
                        skyRGB: (1.00, 0.96, 0.87), tintRGB: (1.00, 0.94, 0.77)),
        AnimalCharacter(id: "octopus", name: "Octopus", emoji: "🐙",
                        primaryRGB: (0.62, 0.40, 0.87), deepRGB: (0.35, 0.18, 0.60),
                        skyRGB: (0.93, 0.88, 0.99), tintRGB: (0.88, 0.79, 0.98)),
        AnimalCharacter(id: "crab", name: "Crab", emoji: "🦀",
                        primaryRGB: (0.90, 0.27, 0.10), deepRGB: (0.62, 0.13, 0.03),
                        skyRGB: (1.00, 0.90, 0.87), tintRGB: (1.00, 0.82, 0.77)),
        AnimalCharacter(id: "elephant", name: "Elephant", emoji: "🐘",
                        primaryRGB: (0.36, 0.58, 0.78), deepRGB: (0.19, 0.38, 0.58),
                        skyRGB: (0.90, 0.94, 0.97), tintRGB: (0.81, 0.89, 0.96)),
        AnimalCharacter(id: "bear", name: "Bear", emoji: "🐻",
                        primaryRGB: (0.72, 0.44, 0.16), deepRGB: (0.42, 0.20, 0.06),
                        skyRGB: (0.99, 0.94, 0.88), tintRGB: (0.98, 0.89, 0.79)),
        AnimalCharacter(id: "fox", name: "Fox", emoji: "🦊",
                        primaryRGB: (0.94, 0.60, 0.26), deepRGB: (0.68, 0.30, 0.07),
                        skyRGB: (1.00, 0.94, 0.87), tintRGB: (1.00, 0.89, 0.77)),
        AnimalCharacter(id: "frog", name: "Frog", emoji: "🐸",
                        primaryRGB: (0.45, 0.76, 0.18), deepRGB: (0.12, 0.47, 0.15),
                        skyRGB: (0.93, 0.99, 0.88), tintRGB: (0.88, 0.97, 0.80)),
        AnimalCharacter(id: "penguin", name: "Penguin", emoji: "🐧",
                        primaryRGB: (0.22, 0.36, 0.68), deepRGB: (0.08, 0.16, 0.38),
                        skyRGB: (0.89, 0.92, 0.98), tintRGB: (0.81, 0.86, 0.96))
    ]

    static func character(id: String) -> AnimalCharacter {
        all.first { $0.id == id } ?? all[0]
    }

    /// The first half of the catalog: earned purely by collecting cards.
    static var cardCharacters: [AnimalCharacter] {
        all.filter { !CharacterUnlocks.premiumCharacterIDs.contains($0.id) }
    }

    /// The second half: still earnable with cards, but Premium grants them at once.
    static var premiumCharacters: [AnimalCharacter] {
        all.filter { CharacterUnlocks.premiumCharacterIDs.contains($0.id) }
    }

    /// The selected character, falling back to the starter when the selected
    /// one is not available (yet).
    static func current(isPremium: Bool) -> AnimalCharacter {
        let selected = character(id: GameSettings.characterID)
        if !CharacterUnlockStore.canUse(characterID: selected.id, isPremium: isPremium) {
            return character(id: freeCharacterID)
        }
        return selected
    }
}

/// Character access, derived from the player's card total so an unlock can
/// never be lost through a missed animation. Only the one-time celebration
/// receipt is stored separately.
enum CharacterUnlockStore {
    static var totalCards: Int {
        get { Progress.store.totalCards }
        set { Progress.store.totalCards = newValue }
    }

    /// Cards required for a character, or nil when it is not card-unlockable.
    static func requirement(for characterID: String) -> Int? {
        CharacterUnlocks.cardsRequired(for: characterID)
    }

    static func canUse(characterID: String, isPremium: Bool) -> Bool {
        CharacterUnlocks.isUnlocked(characterID: characterID,
                                    totalCards: totalCards,
                                    isPremium: isPremium)
    }

    /// The next animal still to be earned, for the home screen and reminders.
    static func nextMilestone() -> (character: AnimalCharacter, remaining: Int)? {
        guard let next = CharacterUnlocks.nextMilestone(totalCards: totalCards) else { return nil }
        return (CharacterCatalog.character(id: next.characterID), next.remaining)
    }

    /// Characters that crossed their requirement but have not been celebrated.
    static func unannouncedUnlocks(at total: Int) -> [AnimalCharacter] {
        let announced = Progress.store.announcedUnlocks
        return CharacterUnlocks.unlockedCharacterIDs(totalCards: total)
            .filter { $0 != CharacterCatalog.freeCharacterID && !announced.contains($0) }
            .map { CharacterCatalog.character(id: $0) }
    }

    static func markAnnounced(_ characterID: String) {
        var announced = Progress.store.announcedUnlocks
        announced.insert(characterID)
        Progress.store.announcedUnlocks = announced
    }
}
