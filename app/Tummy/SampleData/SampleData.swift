//
//  SampleData.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

enum SampleData {

    /// Rankings decoded from sample_rankings.json. The JSON lists places best first within each
    /// category's bucket, so positions are assigned in reverse (0 = worst).
    static let rankings = loadRankings()

    /// A made-up average score from all users, until the backend has real ones. It's hashed from
    /// the Apple ID so it stays the same across launches, and spread on a bell curve around 7.3.
    static func communityScore(for mapItemID: String) -> Double {
        // FNV-1a, because Swift's `hashValue` changes on every launch
        let hash = mapItemID.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        let percentile = (Double(hash % 10_000) + 0.5) / 10_000
        let score = 7.3 + 1.1 * ScoreCurve.inverseNormalCDF(percentile)
        return (min(max(score, 2), 9.8) * 10).rounded() / 10
    }

    private nonisolated struct Entry: Decodable {
        let name: String
        let cuisine: String
        let neighborhood: String
        let category: PlaceCategory
        let mapItemID: String
        let latitude: Double
        let longitude: Double
        let bucket: Bucket
    }

    private static func loadRankings() -> [Ranking] {
        guard let url = Bundle.main.url(forResource: "sample_rankings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            fatalError("sample_rankings.json is missing or malformed")
        }

        return PlaceCategory.allCases.flatMap { category in
            Bucket.allCases.flatMap { bucket in
                let listEntries = entries.filter { $0.category == category && $0.bucket == bucket }

                return listEntries.enumerated().map { index, entry in
                    Ranking(
                        id: UUID(),
                        restaurant: Restaurant(
                            id: UUID(),
                            mapItemID: entry.mapItemID,
                            name: entry.name,
                            cuisine: entry.cuisine,
                            neighborhood: entry.neighborhood,
                            latitude: entry.latitude,
                            longitude: entry.longitude
                        ),
                        category: category,
                        bucket: bucket,
                        position: listEntries.count - 1 - index
                    )
                }
            }
        }
    }

}
