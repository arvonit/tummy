//
//  SampleData.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

enum SampleData {

    static let users = loadUsers()
    /// Rankings and visits decoded from sample_rankings.json. The JSON lists places best first
    /// within each user's category and bucket, so positions are assigned in reverse (0 = worst).
    static var rankings: [Ranking] { loaded.rankings }
    static var visits: [Visit] { loaded.visits }
    private static let loaded = loadRankings()

    /// A made-up average score from all users, until the backend has real ones. It's hashed from
    /// the Apple ID so it stays the same across launches, and spread on a bell curve around 7.3.
    static func communityScore(for mapItemID: String) -> Double {
        let percentile = (Double(mapItemID.stableHash % 10_000) + 0.5) / 10_000
        let score = 7.3 + 1.1 * ScoreCurve.inverseNormalCDF(percentile)
        return (min(max(score, 2), 9.8) * 10).rounded() / 10
    }

    struct Users {
        let currentUser: User
        let all: [User]
        let follows: [Follow]
    }

    private nonisolated struct UsersFile: Decodable {
        struct Entry: Decodable {
            let name: String
            let handle: String
            let memberSince: Date
        }

        let currentUser: String
        let users: [Entry]
        /// [follower handle, followee handle] pairs
        let follows: [[String]]
    }

    private nonisolated struct RankingEntry: Decodable {
        struct VisitEntry: Decodable {
            let daysAgo: Int
            let notes: String?
            let dishes: [String]?
        }

        let user: String
        let name: String
        let cuisine: String
        let neighborhood: String
        let category: PlaceCategory
        let mapItemID: String
        let latitude: Double
        let longitude: Double
        let bucket: Bucket
        let visits: [VisitEntry]?
    }

    private static func decode<T: Decodable>(_ type: T.Type, from resource: String) -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? decoder.decode(type, from: data) else {
            fatalError("\(resource).json is missing or malformed")
        }
        return decoded
    }

    private static func loadUsers() -> Users {
        let file = decode(UsersFile.self, from: "sample_users")
        let users = file.users.map {
            User(id: UUID(), name: $0.name, handle: $0.handle, memberSince: $0.memberSince)
        }
        let idsByHandle = Dictionary(uniqueKeysWithValues: users.map { ($0.handle, $0.id) })

        return Users(
            currentUser: users.first { $0.handle == file.currentUser }!,
            all: users,
            follows: file.follows.compactMap { pair in
                guard let follower = idsByHandle[pair[0]], let followee = idsByHandle[pair[1]]
                else { return nil }
                return Follow(followerID: follower, followeeID: followee)
            }
        )
    }

    private static func loadRankings() -> (rankings: [Ranking], visits: [Visit]) {
        let entries = decode([RankingEntry].self, from: "sample_rankings")
        let userIDsByHandle = Dictionary(uniqueKeysWithValues: users.all.map { ($0.handle, $0.id) })
        // Every user's ranking of a place shares one restaurant, like the backend's table
        var restaurantIDs: [String: UUID] = [:]
        var rankings: [Ranking] = []
        var visits: [Visit] = []

        for (index, entry) in entries.enumerated() {
            let listEntries = entries.filter {
                $0.user == entry.user && $0.category == entry.category && $0.bucket == entry.bucket
            }
            let indexInList = listEntries.firstIndex { $0.mapItemID == entry.mapItemID }!
            let restaurantID = restaurantIDs[entry.mapItemID, default: UUID()]
            restaurantIDs[entry.mapItemID] = restaurantID

            let ranking = Ranking(
                id: UUID(),
                userID: userIDsByHandle[entry.user]!,
                restaurant: Restaurant(
                    id: restaurantID,
                    mapItemID: entry.mapItemID,
                    name: entry.name,
                    cuisine: entry.cuisine,
                    neighborhood: entry.neighborhood,
                    latitude: entry.latitude,
                    longitude: entry.longitude
                ),
                category: entry.category,
                bucket: entry.bucket,
                position: listEntries.count - 1 - indexInList
            )
            rankings.append(ranking)

            // Entries without visits get one, spread over the past 6 weeks. 11 shares no factor
            // with 42, so neighboring entries land on different days.
            let visitEntries = entry.visits
                ?? [.init(daysAgo: index * 11 % 42 + 3, notes: nil, dishes: nil)]
            visits += visitEntries.map { visitEntry in
                let date = Calendar.current.date(
                    byAdding: .day,
                    value: -visitEntry.daysAgo,
                    to: Calendar.current.startOfDay(for: .now)
                )!
                return Visit(
                    id: UUID(),
                    rankingID: ranking.id,
                    date: date,
                    createdAt: date,
                    notes: visitEntry.notes ?? "",
                    dishes: visitEntry.dishes ?? []
                )
            }
        }

        return (rankings, visits)
    }

}
