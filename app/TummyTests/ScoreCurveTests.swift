//
//  ScoreCurveTests.swift
//  TummyTests
//
//  Created by Arvind on 11/25/26.
//

import Foundation
import Testing
@testable import Tummy

struct ScoreCurveTests {

    @Test func inverseCDFMatchesKnownQuantiles() {
        #expect(abs(ScoreCurve.inverseNormalCDF(0.5)) < 1e-9)
        #expect(abs(ScoreCurve.inverseNormalCDF(0.975) - 1.959964) < 1e-5)
        #expect(abs(ScoreCurve.inverseNormalCDF(0.025) + 1.959964) < 1e-5)
    }

    @Test(arguments: [0.001, 0.01, 0.2, 0.5, 0.8, 0.99, 0.999])
    func inverseCDFRoundTrips(p: Double) {
        let roundTripped = ScoreCurve.normalCDF(ScoreCurve.inverseNormalCDF(p))
        #expect(abs(roundTripped - p) < 1e-8)
    }

    @Test(arguments: Bucket.allCases)
    func singlePlaceScoresAtMean(bucket: Bucket) {
        let score = ScoreCurve.score(position: 0, count: 1, bucket: bucket)
        #expect(abs(score - ScoreCurve.parameters(for: bucket).mean) < 1e-9)
    }

    @Test(arguments: Bucket.allCases)
    func scoresStayInBoundsAndIncrease(bucket: Bucket) {
        let curve = ScoreCurve.parameters(for: bucket)
        let scores = bucketScores(count: 50, bucket: bucket)

        #expect(scores.allSatisfy { $0 >= curve.lowerBound && $0 < curve.upperBound })
        #expect(zip(scores, scores.dropFirst()).allSatisfy { $0 < $1 })
    }

    @Test(arguments: Bucket.allCases)
    func scoresAreSymmetricAroundMean(bucket: Bucket) {
        let mean = ScoreCurve.parameters(for: bucket).mean
        let scores = bucketScores(count: 11, bucket: bucket)

        for (low, high) in zip(scores, scores.reversed()) {
            #expect(abs((mean - low) - (high - mean)) < 1e-9)
        }
    }

    @Test func likeBucketWorkedExample() {
        // Matches the table in docs/rating-system.md
        let scores = bucketScores(count: 10, bucket: .like)
        #expect(roundedToTenth(scores[9]) == 9.5)
        #expect(roundedToTenth(scores[5]) == 8.4)
        #expect(roundedToTenth(scores[0]) == 7.0)
    }

    @Test func mostScoresClusterNearTheMean() {
        let curve = ScoreCurve.parameters(for: .like)
        let scores = bucketScores(count: 100, bucket: .like)
        let nearMean = scores.filter { abs($0 - curve.mean) <= curve.standardDeviation }

        // A normal truncated at ±2σ puts about 72% of its mass within ±1σ
        #expect(nearMean.count >= 65)
    }

    @Test func scoredSortsBestFirst() {
        let rankings = [
            makeRanking("Okay Diner", .fine, position: 0),
            makeRanking("Great Bistro", .like, position: 1),
            makeRanking("Bad Buffet", .dislike, position: 0),
            makeRanking("Good Cafe", .like, position: 0),
        ]

        let names = ScoreCurve.scored(rankings).map(\.restaurant.name)

        #expect(names == ["Great Bistro", "Good Cafe", "Okay Diner", "Bad Buffet"])
    }

    @Test func categoriesAreScoredAsSeparateLists() {
        // Alone in its list, the bakery sits at the bucket's center no matter how many
        // restaurants share its bucket
        let rankings = [
            makeRanking("Bakery", .like, position: 0, category: .bakery),
            makeRanking("Restaurant A", .like, position: 0),
            makeRanking("Restaurant B", .like, position: 1),
            makeRanking("Restaurant C", .like, position: 2),
        ]

        let bakery = ScoreCurve.scored(rankings).first { $0.category == .bakery }
        let mean = ScoreCurve.parameters(for: .like).mean

        #expect(abs((bakery?.score ?? 0) - mean) < 1e-9)
    }

    @Test func equalScoresAreOrderedByName() {
        // Same position in same-sized lists gives identical scores across categories
        let rankings = [
            makeRanking("Zucchini Bakery", .like, position: 0, category: .bakery),
            makeRanking("Apple Cafe", .like, position: 0, category: .cafe),
        ]

        let names = ScoreCurve.scored(rankings).map(\.restaurant.name)

        #expect(names == ["Apple Cafe", "Zucchini Bakery"])
    }

    private func bucketScores(count: Int, bucket: Bucket) -> [Double] {
        (0..<count).map { ScoreCurve.score(position: $0, count: count, bucket: bucket) }
    }

    private func roundedToTenth(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private func makeRanking(
        _ name: String,
        _ bucket: Bucket,
        position: Int,
        category: PlaceCategory = .restaurant
    ) -> Ranking {
        let restaurant = Restaurant(id: UUID(), name: name, cuisine: "", neighborhood: "")
        return Ranking(
            id: UUID(),
            restaurant: restaurant,
            category: category,
            bucket: bucket,
            position: position
        )
    }

}
