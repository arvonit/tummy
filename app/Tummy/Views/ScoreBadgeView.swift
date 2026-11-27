//
//  ScoreBadgeView.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI

struct ScoreBadgeView: View {
    let score: Double
    let bucket: Bucket
    /// The big version on the rate flow's result step
    var isLarge = false

    // Grows the circle along with the user's text size
    @ScaledMetric private var diameter: CGFloat = 44
    @ScaledMetric private var largeDiameter: CGFloat = 120

    private var side: CGFloat { isLarge ? largeDiameter : diameter }

    var body: some View {
        Text(score, format: .number
            .precision(.fractionLength(1))
            .rounded(rule: .toNearestOrAwayFromZero))
            .font(isLarge ? .largeTitle.bold() : .subheadline.bold())
            .monospacedDigit()
            .foregroundStyle(bucket.color)
            .frame(width: side, height: side)
            .background(Color(.systemGray6), in: .circle)
    }
}

#Preview {
    HStack {
        ScoreBadgeView(score: 9.54, bucket: .like)
        ScoreBadgeView(score: 5.25, bucket: .fine)
        ScoreBadgeView(score: 2.0, bucket: .dislike)
        ScoreBadgeView(score: 8.25, bucket: .like, isLarge: true)
    }
}
