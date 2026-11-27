//
//  PlaceView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import MapKit
import SwiftUI

/// The Place screen: a map header, the name and score, details, and quick actions
struct PlaceView: View {
    let place: Place
    let context: AppContext
    let onRank: (PlaceSummary) -> Void

    /// Apple's full details, for the phone number, website, and directions
    @State private var mapItem: MKMapItem?
    @Environment(\.openURL) private var openURL

    /// Recomputed from the store, so the score updates after ranking
    private var summary: PlaceSummary { context.summary(for: place) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 16) {
                    Text(summary.place.name)
                        .font(.largeTitle.bold())
                        .fontDesign(.serif)

                    HStack {
                        ScoreBadgeView(score: summary.score, bucket: summary.bucket)
                        Text(summary.isRanked ? "Your score" : "Community score")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Rank", systemImage: "plus.circle") { onRank(summary) }
                            .labelStyle(.iconOnly)
                            .font(.largeTitle)
                            .tint(.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.kind)
                        Text(summary.areaAndDistance(from: context.locationManager.location))
                            .foregroundStyle(.secondary)
                    }

                    actions
                }
                .padding(.horizontal)
            }
        }
        // The map header runs up behind the navigation bar, like Apple Maps
        .ignoresSafeArea(edges: .top)
        .task {
            mapItem = try? await context.placeStore.mapItem(for: summary.id)
        }
    }

    private var header: some View {
        Map(
            initialPosition: .region(MKCoordinateRegion(
                center: summary.place.coordinate,
                latitudinalMeters: 600,
                longitudinalMeters: 600
            )),
            interactionModes: []
        ) {
            Marker(
                summary.place.name,
                systemImage: summary.category.symbolName,
                coordinate: summary.place.coordinate
            )
            .tint(summary.bucket.color)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .frame(height: 280)
    }

    /// Call and Website only show when Apple has a phone number or website for the place
    private var actions: some View {
        HStack {
            Button("Directions", systemImage: "arrow.triangle.turn.up.right.diamond") {
                mapItem?.openInMaps(launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
                ])
            }
            .disabled(mapItem == nil)

            if let phoneNumber = mapItem?.phoneNumber,
               let url = URL(string: "tel:\(phoneNumber.filter { $0.isNumber || $0 == "+" })") {
                Button("Call", systemImage: "phone") { openURL(url) }
            }

            if let website = mapItem?.url {
                Button("Website", systemImage: "globe") { openURL(website) }
            }
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    NavigationStack {
        PlaceView(
            place: PlaceSummary.samples[2].place,
            context: AppContext(),
            onRank: { _ in }
        )
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back", systemImage: "chevron.backward") {}
            }
        }
    }
}
