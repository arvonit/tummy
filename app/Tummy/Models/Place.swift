//
//  Place.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import MapKit

/// A food place on the map, from Apple Maps
struct Place: Identifiable {
    /// Apple's map item identifier
    let id: String
    let name: String
    let category: PlaceCategory
    let coordinate: CLLocationCoordinate2D
    let city: String
    let communityScore: Double

    init?(_ mapItem: MKMapItem) {
        guard let id = mapItem.identifier?.rawValue,
              let poiCategory = mapItem.pointOfInterestCategory,
              let category = PlaceCategory(poiCategory) else { return nil }

        self.id = id
        name = mapItem.name ?? "Unnamed place"
        self.category = category
        coordinate = mapItem.location.coordinate
        city = mapItem.addressRepresentations?.cityName ?? ""
        communityScore = SampleData.communityScore(for: id)
    }

    init(_ ranking: Ranking) {
        let restaurant = ranking.restaurant
        id = restaurant.mapItemID
        name = restaurant.name
        category = ranking.category
        coordinate = restaurant.coordinate
        city = restaurant.neighborhood
        communityScore = SampleData.communityScore(for: restaurant.mapItemID)
    }
}

/// What the pin, card, and Place screen show: a place plus your ranking of it, if any
struct PlaceSummary: Identifiable {
    let place: Place
    let ranking: ScoredRanking?

    var id: Place.ID { place.id }
    var isRanked: Bool { ranking != nil }

    /// Your score if you've ranked the place, otherwise the community's
    var score: Double { ranking?.score ?? place.communityScore }
    var bucket: Bucket { ranking?.bucket ?? ScoreCurve.bucket(for: score) }
    /// Your ranking's category wins, since Apple Maps can't tell a dessert shop from a restaurant
    var category: PlaceCategory { ranking?.category ?? place.category }

    /// "Restaurant · Thai", or just "Restaurant" when the cuisine isn't known
    var kind: String {
        [category.singularTitle, ranking?.restaurant.cuisine]
            .compactMap(\.self)
            .joined(separator: " · ")
    }

    /// The neighborhood you saved, otherwise Apple's city
    var area: String { ranking?.restaurant.neighborhood ?? place.city }

    /// "Lower East Side · 0.4 mi", leaving out the distance when your location is unknown
    func areaAndDistance(from location: CLLocation?) -> String {
        guard let location else { return area }
        let placeLocation = CLLocation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
        let meters = location.distance(from: placeLocation)
        let distance = Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .road,
                numberFormatStyle: .number.precision(.fractionLength(0...1))
            ))
        return [area, distance].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

extension PlaceSummary {

    /// Ranked sample places, for previews
    static let samples = ScoreCurve.scored(SampleData.rankings)
        .map { PlaceSummary(place: Place($0.ranking), ranking: $0) }

}

extension Restaurant {

    /// A restaurant for a place you're ranking for the first time. Apple Maps has no cuisine, and
    /// its city stands in for the neighborhood.
    init(_ place: Place) {
        self.init(
            id: UUID(),
            mapItemID: place.id,
            name: place.name,
            cuisine: nil,
            neighborhood: place.city,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        )
    }

}
