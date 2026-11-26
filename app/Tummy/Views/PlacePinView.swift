//
//  PlacePinView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// A map pin: the category symbol in a bucket-colored circle, then the score. Places you've
/// ranked get a checkmark.
struct PlacePinView: View {
    let summary: PlaceSummary
    var isSelected = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: summary.category.symbolName)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(summary.bucket.color, in: .circle)

            Text(summary.score, format: .number.precision(.fractionLength(1)))
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(.black)
        }
        .padding(3)
        .padding(.trailing, 6)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.2), radius: 3, y: 1)
        .overlay(alignment: .bottomTrailing) {
            if summary.isRanked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white, .tint)
                    .offset(x: 4, y: 4)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1, anchor: .bottom)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(PlaceSummary.samples.prefix(4)) { PlacePinView(summary: $0) }
        PlacePinView(summary: PlaceSummary.samples[0], isSelected: true)
        if let unranked = PlaceSummary.samples.last {
            PlacePinView(summary: PlaceSummary(place: unranked.place, ranking: nil))
        }
    }
    .padding()
    .background(.green.opacity(0.2))
}
