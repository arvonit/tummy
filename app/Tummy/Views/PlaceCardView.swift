//
//  PlaceCardView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import CoreLocation
import SwiftUI

/// The card that slides up when a pin is selected. Tapping it opens the Place screen.
struct PlaceCardView: View {
    let summary: PlaceSummary
    let userLocation: CLLocation?
    let onOpen: () -> Void
    let onRank: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.place.name)
                    .font(.title3.bold())
                Text(summary.kind)
                Text(summary.areaAndDistance(from: userLocation))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                ScoreBadgeView(score: summary.score, bucket: summary.bucket)
                Button("Rank", systemImage: "plus.circle", action: onRank)
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .tint(.primary)
            }
        }
        .padding(20)
        .contentShape(.rect)
        .onTapGesture(perform: onOpen)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
    }
}

#Preview {
    VStack {
        Spacer()
        PlaceCardView(
            summary: PlaceSummary.samples[2],
            userLocation: CLLocation(latitude: 40.7265, longitude: -73.9866),
            onOpen: {},
            onRank: {}
        )
        PlaceCardView(
            summary: PlaceSummary(place: PlaceSummary.samples[5].place, ranking: nil),
            userLocation: nil,
            onOpen: {},
            onRank: {}
        )
    }
    .padding()
    .background(.green.opacity(0.3))
}
