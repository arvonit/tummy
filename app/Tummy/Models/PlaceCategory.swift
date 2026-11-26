//
//  PlaceCategory.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

/// Each category is its own ranked list, so places are only compared within a category
nonisolated enum PlaceCategory: String, CaseIterable, Decodable {
    case restaurant
    case bar
    case bakery
    case cafe
    case dessert

    var title: String {
        switch self {
        case .restaurant: "Restaurants"
        case .bar: "Bars"
        case .bakery: "Bakeries"
        case .cafe: "Cafes"
        case .dessert: "Dessert"
        }
    }
}
