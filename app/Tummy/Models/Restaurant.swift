//
//  Restaurant.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import CoreLocation
import Foundation

nonisolated struct Restaurant: Identifiable, Hashable {
    let id: UUID
    /// Apple's map item identifier, used to match this restaurant to places on the map
    let mapItemID: String
    let name: String
    /// nil for places added from Apple Maps, which doesn't know the cuisine
    let cuisine: String?
    let neighborhood: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// "Pizza · Carroll Gardens", leaving out whatever is unknown
    var details: String {
        [cuisine, neighborhood].compactMap(\.self).filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
