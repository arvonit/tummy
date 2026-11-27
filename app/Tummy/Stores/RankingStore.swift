//
//  RankingStore.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation
import Observation

/// Where screens get rankings and visits from. Screens only see this protocol, so the sample
/// store can be swapped for a Supabase or API-backed one without touching UI code. It's
/// `Observable`, so screens that read `rankings` or `visits` redraw when they change.
protocol RankingStore: AnyObject, Observable {
    /// Every user's rankings. Filter by `userID` for one person's lists.
    var rankings: [Ranking] { get }
    var visits: [Visit] { get }

    /// Puts `restaurant` at `position` in the user's list, moving it there if it's already
    /// ranked, and logs `visit` against it
    @discardableResult
    func rank(
        _ restaurant: Restaurant,
        category: PlaceCategory,
        bucket: Bucket,
        at position: Int,
        by userID: User.ID,
        visit: Visit
    ) async throws -> Ranking

    func addVisit(_ visit: Visit) async throws
    func delete(_ id: Ranking.ID) async throws
}

/// Keeps rankings in memory, seeded from the bundled sample data
@Observable
class SampleRankingStore: RankingStore {
    private(set) var rankings: [Ranking]
    private(set) var visits: [Visit]

    init(rankings: [Ranking] = SampleData.rankings, visits: [Visit] = SampleData.visits) {
        self.rankings = rankings
        self.visits = visits
    }

    func rank(
        _ restaurant: Restaurant,
        category: PlaceCategory,
        bucket: Bucket,
        at position: Int,
        by userID: User.ID,
        visit: Visit
    ) async throws -> Ranking {
        let existing = rankings.first {
            $0.userID == userID && $0.restaurant.mapItemID == restaurant.mapItemID
        }
        if let existing { removeFromList(existing) }

        // Make room: everything at or above the new position moves up one
        for index in rankings.indices
        where rankings[index].userID == userID
            && rankings[index].category == category
            && rankings[index].bucket == bucket
            && rankings[index].position >= position {
            rankings[index].position += 1
        }

        // Keeping the ID keeps earlier visits attached when re-ranking
        let ranking = Ranking(
            id: existing?.id ?? UUID(),
            userID: userID,
            restaurant: restaurant,
            category: category,
            bucket: bucket,
            position: position
        )
        rankings.append(ranking)

        var visit = visit
        visit.rankingID = ranking.id
        visits.append(visit)
        return ranking
    }

    func addVisit(_ visit: Visit) async throws {
        visits.append(visit)
    }

    func delete(_ id: Ranking.ID) async throws {
        guard let removed = rankings.first(where: { $0.id == id }) else { return }
        removeFromList(removed)
        visits.removeAll { $0.rankingID == id }
    }

    /// Removes a ranking and closes the gap, so positions in its list stay 0..<count
    private func removeFromList(_ removed: Ranking) {
        rankings.removeAll { $0.id == removed.id }
        for index in rankings.indices
        where rankings[index].userID == removed.userID
            && rankings[index].category == removed.category
            && rankings[index].bucket == removed.bucket
            && rankings[index].position > removed.position {
            rankings[index].position -= 1
        }
    }
}
