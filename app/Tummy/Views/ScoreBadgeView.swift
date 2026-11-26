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

    // Grows the circle along with the user's text size
    @ScaledMetric private var diameter: CGFloat = 44

    var body: some View {
        Text(score, format: .number
            .precision(.fractionLength(1))
            .rounded(rule: .toNearestOrAwayFromZero))
            .font(.subheadline.bold())
            .monospacedDigit()
            .foregroundStyle(bucket.color)
            .frame(width: diameter, height: diameter)
            .background(Color(.systemGray6), in: .circle)
    }
}

#Preview {
    HStack {
        ScoreBadgeView(score: 9.54, bucket: .like)
        ScoreBadgeView(score: 5.25, bucket: .fine)
        ScoreBadgeView(score: 2.0, bucket: .dislike)
    }
}
