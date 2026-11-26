//
//  RankingCellView.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI

/// What a row in My Lists shows. The rank depends on the active filter, so it's passed in.
struct RankingRow: Hashable {
    let rank: Int
    let ranking: ScoredRanking
}

struct RankingCellView: View {
    let row: RankingRow

    @ScaledMetric private var rankWidth: CGFloat = 22

    var body: some View {
        HStack(spacing: 12) {
            Text("\(row.rank)")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                // Hug the leading edge, but leave room for two digits so names stay aligned
                .frame(minWidth: rankWidth, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.ranking.restaurant.name)
                    .font(.body.bold())
                Text("\(row.ranking.restaurant.cuisine) · \(row.ranking.restaurant.neighborhood)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            ScoreBadgeView(score: row.ranking.score, bucket: row.ranking.bucket)
        }
    }
}

#Preview("Sample rows") {
    let rankings = ScoreCurve.scored(SampleData.rankings)
    return List(Array(rankings.enumerated()), id: \.element.id) { index, ranking in
        RankingCellView(row: RankingRow(rank: index + 1, ranking: ranking))
    }
    .listStyle(.plain)
}

#Preview("Long name, XXL text") {
    let restaurant = Restaurant(
        id: UUID(),
        mapItemID: "",
        name: "The Extremely Long Named Neighborhood Trattoria and Wine Bar",
        cuisine: "Italian",
        neighborhood: "Carroll Gardens",
        latitude: 0,
        longitude: 0
    )
    let ranking = Ranking(
        id: UUID(),
        restaurant: restaurant,
        category: .restaurant,
        bucket: .like,
        position: 0
    )
    let scored = ScoreCurve.scored([ranking])[0]

    return List {
        RankingCellView(row: RankingRow(rank: 1, ranking: scored))
    }
    .listStyle(.plain)
    .dynamicTypeSize(.accessibility2)
}
