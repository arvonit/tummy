//
//  FeedItem.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Foundation

/// A visit as the Feed and Profile show it. Feed items aren't stored: they're built from
/// visits, so scores are always current.
nonisolated struct FeedItem: Identifiable, Hashable {
    let user: User
    let ranking: ScoredRanking
    let visit: Visit
    let isFirstVisit: Bool

    var id: Visit.ID { visit.id }
    var verb: String { isFirstVisit ? "ranked" : "revisited" }

    /// Visits by `userIDs`, newest first
    static func items(
        rankings: [Ranking],
        visits: [Visit],
        users: [User],
        showing userIDs: Set<User.ID>
    ) -> [FeedItem] {
        let usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        let rankingsByID = Dictionary(
            uniqueKeysWithValues: ScoreCurve.scored(rankings).map { ($0.id, $0) }
        )
        let firstVisitIDs = Set(
            Dictionary(grouping: visits, by: \.rankingID).values
                .compactMap { $0.min(by: Visit.isOlder)?.id }
        )

        return visits.sorted(by: Visit.isOlder).reversed().compactMap { visit in
            guard let ranking = rankingsByID[visit.rankingID],
                  userIDs.contains(ranking.ranking.userID),
                  let user = usersByID[ranking.ranking.userID] else { return nil }
            return FeedItem(
                user: user,
                ranking: ranking,
                visit: visit,
                isFirstVisit: firstVisitIDs.contains(visit.id)
            )
        }
    }
}
