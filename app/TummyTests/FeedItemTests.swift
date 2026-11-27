//
//  FeedItemTests.swift
//  TummyTests
//
//  Created by Arvind on 11/26/26.
//

import Foundation
import Testing
@testable import Tummy

struct FeedItemTests {

    let me = User(id: UUID(), name: "Me", handle: "me", memberSince: .now)
    let friend = User(id: UUID(), name: "Friend", handle: "friend", memberSince: .now)
    let stranger = User(id: UUID(), name: "Stranger", handle: "stranger", memberSince: .now)

    private func makeRanking(for user: User) -> Ranking {
        Ranking(
            id: UUID(),
            userID: user.id,
            restaurant: Restaurant(
                id: UUID(),
                mapItemID: user.handle,
                name: "\(user.name)'s place",
                cuisine: nil,
                neighborhood: "",
                latitude: 0,
                longitude: 0
            ),
            category: .restaurant,
            bucket: .like,
            position: 0
        )
    }

    private func makeVisit(_ ranking: Ranking, daysAgo: Int) -> Visit {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        return Visit(id: UUID(), rankingID: ranking.id, date: date, createdAt: date)
    }

    @Test func showsOnlyChosenUsersNewestFirst() {
        let mine = makeRanking(for: me)
        let friends = makeRanking(for: friend)
        let strangers = makeRanking(for: stranger)
        let visits = [
            makeVisit(mine, daysAgo: 3),
            makeVisit(friends, daysAgo: 1),
            makeVisit(strangers, daysAgo: 0),
        ]

        let items = FeedItem.items(
            rankings: [mine, friends, strangers],
            visits: visits,
            users: [me, friend, stranger],
            showing: [me.id, friend.id]
        )

        #expect(items.map(\.user.handle) == ["friend", "me"])
    }

    @Test func firstVisitIsRankedAndLaterOnesAreRevisits() {
        let ranking = makeRanking(for: me)
        let first = makeVisit(ranking, daysAgo: 5)
        let second = makeVisit(ranking, daysAgo: 1)

        let items = FeedItem.items(
            rankings: [ranking],
            visits: [second, first],
            users: [me],
            showing: [me.id]
        )

        #expect(items.map(\.verb) == ["revisited", "ranked"])
    }

}
