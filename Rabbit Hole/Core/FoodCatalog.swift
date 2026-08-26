//
//  FoodCatalog.swift
//  Rabbit Hole
//
//  What each character collects. Looked up by character ID rather than catalog
//  index: Rabbit Hole's roster starts at the bunny, Hungry Frog's at the frog,
//  and the same animal must keep the same food in both games. This catalog
//  names the food and points at both its HUD glyph and its in-game pickup art.
//

import Foundation

enum FoodNumberContrast: Equatable, Sendable {
    case light
    case cocoa
    case plum
    case violet
}

struct FoodPickupStyle: Equatable, Sendable {
    let assetName: String
    let canvasAspectRatio: Double
    /// Centre-to-grip distance as a share of the artwork height. Every pickup
    /// rotates this point toward the boom, so the claw meets opaque artwork.
    let gripLiftFraction: Double
    let numberYOffsetFraction: Double
    let numberWidthFraction: Double
    let numberContrast: FoodNumberContrast

    static let carrot = FoodPickupStyle(
        assetName: "carrot_new",
        canvasAspectRatio: 656.0 / 650.0,
        gripLiftFraction: 0.468,
        numberYOffsetFraction: 0,
        numberWidthFraction: 0.50,
        numberContrast: .light
    )
}

public struct FoodItem: Identifiable, Equatable, Sendable {
    /// Short identifier used to key the localized lines
    /// ("levelIntro.cardsBullet.<id> %lld", "game.end.completionSubtitle.<id>").
    public let id: String
    /// Asset catalog name of the HUD glyph. Its number matches the character's
    /// position in the roster (`currency_1` through `currency_10`).
    public let currencyIconName: String
    let pickupStyle: FoodPickupStyle

    public init(id: String, currencyIconName: String) {
        self.id = id
        self.currencyIconName = currencyIconName
        self.pickupStyle = .carrot
    }

    init(id: String, currencyIconName: String, pickupStyle: FoodPickupStyle) {
        self.id = id
        self.currencyIconName = currencyIconName
        self.pickupStyle = pickupStyle
    }
}

public enum FoodCatalog {
    /// Currency artwork mapped onto Rabbit Hole's animals. Most entries reuse
    /// Hungry Frog's food; crab, frog and fox use their replacement items.
    private static let itemsByCharacterID: [String: FoodItem] = [
        "bunny": FoodItem(
            id: "carrot", currencyIconName: "currency_1", pickupStyle: .carrot
        ),
        "dog": FoodItem(
            id: "kibble", currencyIconName: "currency_2",
            pickupStyle: FoodPickupStyle(
                assetName: "2", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.132, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .cocoa
            )
        ),
        "lion": FoodItem(
            id: "meat", currencyIconName: "currency_3",
            pickupStyle: FoodPickupStyle(
                assetName: "3", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.162, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .light
            )
        ),
        "octopus": FoodItem(
            id: "pearl", currencyIconName: "currency_4",
            pickupStyle: FoodPickupStyle(
                assetName: "4", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.378, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .violet
            )
        ),
        "crab": FoodItem(
            id: "worm", currencyIconName: "currency_5",
            pickupStyle: FoodPickupStyle(
                assetName: "5", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.221, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .plum
            )
        ),
        "elephant": FoodItem(
            id: "peanut", currencyIconName: "currency_6",
            pickupStyle: FoodPickupStyle(
                assetName: "6", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.219, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .cocoa
            )
        ),
        "bear": FoodItem(
            id: "honey", currencyIconName: "currency_7",
            pickupStyle: FoodPickupStyle(
                assetName: "7", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.316, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .cocoa
            )
        ),
        "fox": FoodItem(
            id: "egg", currencyIconName: "currency_8",
            pickupStyle: FoodPickupStyle(
                assetName: "8", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.298, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .cocoa
            )
        ),
        "frog": FoodItem(
            id: "spider", currencyIconName: "currency_9",
            pickupStyle: FoodPickupStyle(
                assetName: "9", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.301, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .light
            )
        ),
        "penguin": FoodItem(
            id: "fish", currencyIconName: "currency_10",
            pickupStyle: FoodPickupStyle(
                assetName: "10", canvasAspectRatio: 656.0 / 650.0,
                gripLiftFraction: 0.335, numberYOffsetFraction: 0,
                numberWidthFraction: 0.50, numberContrast: .light
            )
        )
    ]

    /// The food a character collects, falling back to the starter's (the
    /// carrot) for an unrecognized ID rather than crashing.
    public static func food(for characterID: String) -> FoodItem {
        itemsByCharacterID[characterID]
            ?? itemsByCharacterID[CharacterUnlocks.starterCharacterID]
            ?? itemsByCharacterID["bunny"]!
    }

    /// "You can collect up to 12 carrots in this level." — one whole sentence
    /// per food, so every language can decline, reorder or reword it freely.
    public static func collectionLine(for characterID: String, count: Int) -> String {
        L(key: "levelIntro.cardsBullet.\(food(for: characterID).id) %lld", count: count)
    }

    /// "You collected all the carrots." — the line under the character on the
    /// result card when the board was filled, named after what this character
    /// was actually collecting rather than after the bunny's carrots.
    ///
    /// One whole sentence per food again, for the same reason: the noun sits
    /// in a different case, position and article in every language. Languages
    /// without a translation use the English food-specific sentence.
    public static func completionLine(for characterID: String) -> String {
        L(key: "game.end.completionSubtitle.\(food(for: characterID).id)")
    }
}
