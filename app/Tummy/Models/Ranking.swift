//
//  Ranking.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

/// A restaurant's place in a user's list. `position` 0 is the worst place in its category's
/// bucket.
nonisolated struct Ranking: Identifiable, Hashable {
    let id: UUID
    let restaurant: Restaurant
    let category: PlaceCategory
    let bucket: Bucket
    var position: Int
}

/// A ranking plus the score derived from where it sits in its list
nonisolated struct ScoredRanking: Identifiable, Hashable {
    let ranking: Ranking
    let score: Double

    var id: UUID { ranking.id }
    var restaurant: Restaurant { ranking.restaurant }
    var category: PlaceCategory { ranking.category }
    var bucket: Bucket { ranking.bucket }
}
