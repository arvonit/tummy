//
//  SearchMapView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import MapKit
import SwiftUI

/// The Search tab: a full-screen map of food places with a search bar pinned to the bottom.
/// Selecting a pin swaps the search bar for a card about that place.
struct SearchMapView: View {
    let placeStore: PlaceStore
    let rankingStore: RankingStore
    let locationManager: CLLocationManager
    let onOpen: (PlaceSummary) -> Void
    let onRank: (PlaceSummary) -> Void

    @State private var position = MapCameraPosition.region(.lowerManhattan)
    @State private var region = MKCoordinateRegion.lowerManhattan
    @State private var nearbyPlaces: [Place] = []
    /// Places matching the last search, or nil while browsing
    @State private var searchResults: [Place]?
    @State private var rankedPlaces: [Place] = []
    @State private var rankingsByPlaceID: [Place.ID: ScoredRanking] = [:]
    @State private var selectedID: Place.ID?
    @State private var query = ""

    var body: some View {
        Map(position: $position, selection: $selectedID) {
            UserAnnotation()

            ForEach(pins) { summary in
                let place = summary.place
                Annotation(place.name, coordinate: place.coordinate, anchor: .bottom) {
                    PlacePinView(summary: summary, isSelected: summary.id == selectedID)
                }
                .tag(summary.id)
                .annotationTitles(.hidden)
            }
        }
        // Our pins replace Apple's own place labels
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            region = context.region
            Task { await loadNearbyPlaces() }
        }
        .safeAreaInset(edge: .bottom) {
            bottomPanel
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .animation(.spring(duration: 0.3), value: selectedID)
        .onChange(of: query) {
            if query.isEmpty {
                searchResults = nil
                Task { await loadNearbyPlaces() }
            }
        }
        .task {
            locationManager.requestWhenInUseAuthorization()
            // Start on your neighborhood. The system's user-location camera zooms out too far
            // for Apple to return nearby places.
            if let location = locationManager.location {
                region = .neighborhood(around: location.coordinate)
                position = .region(region)
            }
            await loadRankings()
            // Setting the first camera doesn't count as a camera change, so load the first places
            await loadNearbyPlaces()
        }
    }

    /// Search results, or else nearby places plus your ranked places, which Apple's results can
    /// leave out since it returns at most about 50 places
    private var pins: [PlaceSummary] {
        let places = searchResults ?? {
            let nearbyIDs = Set(nearbyPlaces.map(\.id))
            return nearbyPlaces + rankedPlaces.filter { !nearbyIDs.contains($0.id) }
        }()
        return places.map { PlaceSummary(place: $0, ranking: rankingsByPlaceID[$0.id]) }
    }

    private var selectedSummary: PlaceSummary? {
        pins.first { $0.id == selectedID }
    }

    @ViewBuilder
    private var bottomPanel: some View {
        if let summary = selectedSummary {
            PlaceCardView(
                summary: summary,
                userLocation: locationManager.location,
                onOpen: { onOpen(summary) },
                onRank: { onRank(summary) }
            )
            .id(summary.id)
            // Swiping the card down brings back the search bar, since tapping empty map doesn't
            // clear the selection when the pins are custom annotations
            .gesture(DragGesture().onEnded { drag in
                if drag.translation.height > 40 { selectedID = nil }
            })
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            SearchBarView(query: $query) { Task { await search() } }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func loadRankings() async {
        let scored = ScoreCurve.scored((try? await rankingStore.rankings()) ?? [])
        rankedPlaces = scored.map { Place($0.ranking) }
        rankingsByPlaceID = Dictionary(
            scored.map { ($0.restaurant.mapItemID, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    private func loadNearbyPlaces() async {
        // Zoomed far out, Apple's handful of results would look random, so keep the last ones
        guard searchResults == nil, region.span.latitudeDelta < 0.08 else { return }
        if let places = try? await placeStore.places(in: region) {
            nearbyPlaces = places
        }
    }

    private func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }

        let results = (try? await placeStore.search(trimmedQuery, in: region)) ?? []
        searchResults = results
        selectedID = nil
        guard !results.isEmpty else { return }

        // Fit the map to the results, with some room around the edges
        let bounds = results.reduce(MKMapRect.null) { bounds, place in
            bounds.union(MKMapRect(origin: MKMapPoint(place.coordinate), size: MKMapSize()))
        }
        let margin = max(bounds.width, bounds.height) * 0.2 + 500
        withAnimation {
            position = .rect(bounds.insetBy(dx: -margin, dy: -margin))
        }
    }
}

extension MKCoordinateRegion {

    /// Where the map starts when your location is unknown, around the sample places
    static let lowerManhattan = neighborhood(
        around: CLLocationCoordinate2D(latitude: 40.7255, longitude: -73.9905)
    )

    static func neighborhood(around center: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: center, latitudinalMeters: 2_500, longitudinalMeters: 2_500)
    }

}

#Preview {
    SearchMapView(
        placeStore: MapKitPlaceStore(),
        rankingStore: SampleRankingStore(),
        locationManager: CLLocationManager(),
        onOpen: { _ in },
        onRank: { _ in }
    )
}
