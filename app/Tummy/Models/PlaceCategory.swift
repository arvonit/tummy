//
//  PlaceCategory.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import MapKit

/// Each category is its own ranked list, so places are only compared within a category
nonisolated enum PlaceCategory: String, CaseIterable, Decodable {
    case restaurant
    case bar
    case bakery
    case cafe
    case dessert

    /// Apple Maps has no dessert category, so dessert shops only show as Dessert once ranked
    init?(_ category: MKPointOfInterestCategory) {
        switch category {
        case .restaurant: self = .restaurant
        case .nightlife, .brewery, .winery, .distillery: self = .bar
        case .bakery: self = .bakery
        case .cafe: self = .cafe
        default: return nil
        }
    }

    /// The Apple Maps categories that map to a `PlaceCategory`
    static var mapFilter: MKPointOfInterestFilter {
        MKPointOfInterestFilter(including: [
            .restaurant, .nightlife, .brewery, .winery, .distillery, .bakery, .cafe,
        ])
    }

    var title: String {
        switch self {
        case .restaurant: "Restaurants"
        case .bar: "Bars"
        case .bakery: "Bakeries"
        case .cafe: "Cafes"
        case .dessert: "Dessert"
        }
    }

    var singularTitle: String {
        switch self {
        case .restaurant: "Restaurant"
        case .bar: "Bar"
        case .bakery: "Bakery"
        case .cafe: "Cafe"
        case .dessert: "Dessert"
        }
    }

    var symbolName: String {
        switch self {
        case .restaurant: "fork.knife"
        case .bar: "wineglass.fill"
        case .bakery: "basket.fill"
        case .cafe: "cup.and.saucer.fill"
        case .dessert: "birthday.cake.fill"
        }
    }
}
