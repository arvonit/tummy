//
//  PlaceStore.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import MapKit

/// Where screens get places on the map from
protocol PlaceStore {
    /// Food places inside `region`, for browsing the map
    func places(in region: MKCoordinateRegion) async throws -> [Place]
    func search(_ query: String, in region: MKCoordinateRegion) async throws -> [Place]
    /// Apple's full details for a place, such as its phone number and website
    func mapItem(for id: Place.ID) async throws -> MKMapItem
}

/// Gets places straight from Apple Maps
class MapKitPlaceStore: PlaceStore {

    func places(in region: MKCoordinateRegion) async throws -> [Place] {
        let request = MKLocalPointsOfInterestRequest(coordinateRegion: region)
        request.pointOfInterestFilter = PlaceCategory.mapFilter
        return try await MKLocalSearch(request: request).start().mapItems.compactMap { Place($0) }
    }

    func search(_ query: String, in region: MKCoordinateRegion) async throws -> [Place] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = PlaceCategory.mapFilter
        return try await MKLocalSearch(request: request).start().mapItems.compactMap { Place($0) }
    }

    func mapItem(for id: Place.ID) async throws -> MKMapItem {
        guard let identifier = MKMapItem.Identifier(rawValue: id) else {
            throw MKError(.placemarkNotFound)
        }
        return try await MKMapItemRequest(mapItemIdentifier: identifier).mapItem
    }

}
