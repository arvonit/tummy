//
//  AppContext.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import CoreLocation

/// The stores every screen shares, so a change made in one tab shows up in the others
struct AppContext {
    var rankingStore: RankingStore = SampleRankingStore()
    var userStore: UserStore = SampleUserStore()
    var placeStore: PlaceStore = MapKitPlaceStore()
    var locationManager = CLLocationManager()

    var currentUserID: User.ID { userStore.currentUser.id }

    /// Your rankings, scored and best first
    var myScoredRankings: [ScoredRanking] {
        ScoreCurve.scored(rankingStore.rankings.filter { $0.userID == currentUserID })
    }

    /// Visits by `userIDs`, newest first
    func feedItems(showing userIDs: Set<User.ID>) -> [FeedItem] {
        FeedItem.items(
            rankings: rankingStore.rankings,
            visits: rankingStore.visits,
            users: userStore.users,
            showing: userIDs
        )
    }

    /// A place with your current ranking of it, if you have one
    func summary(for place: Place) -> PlaceSummary {
        let mine = myScoredRankings.first { $0.restaurant.mapItemID == place.id }
        return PlaceSummary(place: place, ranking: mine)
    }

    /// The place behind anyone's ranking, with your own ranking of it
    func summary(for ranking: Ranking) -> PlaceSummary {
        summary(for: Place(ranking))
    }
}
