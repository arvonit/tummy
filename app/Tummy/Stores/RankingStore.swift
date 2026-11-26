//
//  RankingStore.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

/// Where screens get rankings from. Screens only see this protocol, so the sample store can be
/// swapped for a Supabase or API-backed one without touching UI code.
protocol RankingStore {
    func rankings() async throws -> [Ranking]
    func delete(_ id: Ranking.ID) async throws
}

/// Keeps rankings in memory, seeded from the bundled sample data
class SampleRankingStore: RankingStore {
    private var allRankings: [Ranking]

    init(rankings: [Ranking] = SampleData.rankings) {
        allRankings = rankings
    }

    func rankings() async throws -> [Ranking] {
        allRankings
    }

    func delete(_ id: Ranking.ID) async throws {
        guard let removed = allRankings.first(where: { $0.id == id }) else { return }
        allRankings.removeAll { $0.id == id }

        // Close the gap so positions in that category's bucket stay 0..<count
        for index in allRankings.indices
        where allRankings[index].category == removed.category
            && allRankings[index].bucket == removed.bucket
            && allRankings[index].position > removed.position {
            allRankings[index].position -= 1
        }
    }
}
