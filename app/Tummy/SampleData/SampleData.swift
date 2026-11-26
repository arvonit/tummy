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

    private nonisolated struct Entry: Decodable {
        let name: String
        let cuisine: String
        let neighborhood: String
        let category: PlaceCategory
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
                            name: entry.name,
                            cuisine: entry.cuisine,
                            neighborhood: entry.neighborhood
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
