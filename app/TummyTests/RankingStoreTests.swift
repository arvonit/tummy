//
//  RankingStoreTests.swift
//  TummyTests
//
//  Created by Arvind on 11/26/26.
//

import Foundation
import Testing
@testable import Tummy

@MainActor
struct RankingStoreTests {

    let me = UUID()

    private func makeRestaurant(_ name: String) -> Restaurant {
        Restaurant(
            id: UUID(),
            mapItemID: name,
            name: name,
            cuisine: nil,
            neighborhood: "",
            latitude: 0,
            longitude: 0
        )
    }

    private func makeVisit() -> Visit {
        Visit(id: UUID(), rankingID: UUID(), date: .now, createdAt: .now)
    }

    /// A store with `names` in my liked restaurants, worst first
    private func makeStore(_ names: [String]) async throws -> SampleRankingStore {
        let store = SampleRankingStore(rankings: [], visits: [])
        for (position, name) in names.enumerated() {
            try await store.rank(
                makeRestaurant(name),
                category: .restaurant,
                bucket: .like,
                at: position,
                by: me,
                visit: makeVisit()
            )
        }
        return store
    }

    private func namesWorstFirst(_ store: SampleRankingStore, bucket: Bucket = .like) -> [String] {
        store.rankings
            .filter { $0.bucket == bucket }
            .sorted { $0.position < $1.position }
            .map(\.restaurant.name)
    }

    @Test func insertShiftsPlacesAbove() async throws {
        let store = try await makeStore(["A", "B", "C"])

        try await store.rank(
            makeRestaurant("New"),
            category: .restaurant,
            bucket: .like,
            at: 1,
            by: me,
            visit: makeVisit()
        )

        #expect(namesWorstFirst(store) == ["A", "New", "B", "C"])
    }

    @Test func reRankKeepsTheIDAndVisits() async throws {
        let store = try await makeStore(["A", "B", "C"])
        let original = store.rankings.first { $0.restaurant.name == "A" }!

        let moved = try await store.rank(
            original.restaurant,
            category: .restaurant,
            bucket: .like,
            at: 2,
            by: me,
            visit: makeVisit()
        )

        #expect(moved.id == original.id)
        #expect(namesWorstFirst(store) == ["B", "C", "A"])
        #expect(store.visits.count { $0.rankingID == original.id } == 2)
    }

    @Test func reRankIntoAnotherBucketClosesTheGap() async throws {
        let store = try await makeStore(["A", "B", "C"])
        let original = store.rankings.first { $0.restaurant.name == "B" }!

        try await store.rank(
            original.restaurant,
            category: .restaurant,
            bucket: .fine,
            at: 0,
            by: me,
            visit: makeVisit()
        )

        #expect(namesWorstFirst(store) == ["A", "C"])
        #expect(store.rankings.filter { $0.bucket == .like }.map(\.position).sorted() == [0, 1])
        #expect(namesWorstFirst(store, bucket: .fine) == ["B"])
    }

    @Test func deleteClosesTheGapAndDropsVisits() async throws {
        let store = try await makeStore(["A", "B", "C"])
        let removed = store.rankings.first { $0.restaurant.name == "A" }!

        try await store.delete(removed.id)

        #expect(namesWorstFirst(store) == ["B", "C"])
        #expect(store.rankings.map(\.position).sorted() == [0, 1])
        #expect(!store.visits.contains { $0.rankingID == removed.id })
    }

    @Test func otherUsersListsAreUntouched() async throws {
        let store = try await makeStore(["A"])
        try await store.rank(
            makeRestaurant("A"),
            category: .restaurant,
            bucket: .like,
            at: 0,
            by: UUID(),
            visit: makeVisit()
        )

        #expect(store.rankings.count == 2)
        #expect(store.rankings.allSatisfy { $0.position == 0 })
    }

}
