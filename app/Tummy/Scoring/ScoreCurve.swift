//
//  ScoreCurve.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//
//  Turns a place's rank within its bucket into a score on a bell curve.
//  See docs/rating-system.md for the math and the reasoning behind it.
//

import Foundation

nonisolated enum ScoreCurve {

    struct Parameters {
        let lowerBound: Double
        let upperBound: Double

        var mean: Double { (lowerBound + upperBound) / 2 }
        // range / 4 puts the bucket edges at ±2σ
        var standardDeviation: Double { (upperBound - lowerBound) / 4 }
    }

    static func parameters(for bucket: Bucket) -> Parameters {
        switch bucket {
        case .like: Parameters(lowerBound: 6.5, upperBound: 10)
        case .fine: Parameters(lowerBound: 4, upperBound: 6.5)
        case .dislike: Parameters(lowerBound: 0, upperBound: 4)
        }
    }

    /// Score for the place at `position` (0 = worst) in a bucket holding `count` places
    static func score(position: Int, count: Int, bucket: Bucket) -> Double {
        let curve = parameters(for: bucket)
        // Hazen plotting position keeps the percentile strictly between 0 and 1
        let percentile = (Double(position) + 0.5) / Double(count)

        // Truncated normal: map the percentile into the slice of the normal CDF that lies
        // inside the bucket's bounds, then invert it back to a score
        let lowerCDF = normalCDF((curve.lowerBound - curve.mean) / curve.standardDeviation)
        let upperCDF = normalCDF((curve.upperBound - curve.mean) / curve.standardDeviation)
        let target = lowerCDF + percentile * (upperCDF - lowerCDF)

        return curve.mean + curve.standardDeviation * inverseNormalCDF(target)
    }

    /// Scores every ranking and sorts them best first, breaking ties by name. Each bucket in each
    /// category is scored as its own list.
    static func scored(_ rankings: [Ranking]) -> [ScoredRanking] {
        let counts = Dictionary(grouping: rankings, by: ListKey.init).mapValues(\.count)

        return rankings
            .map { ranking in
                ScoredRanking(
                    ranking: ranking,
                    score: score(
                        position: ranking.position,
                        count: counts[ListKey(ranking), default: 1],
                        bucket: ranking.bucket
                    )
                )
            }
            .sorted {
                $0.score == $1.score
                    ? $0.restaurant.name < $1.restaurant.name
                    : $0.score > $1.score
            }
    }

    private nonisolated struct ListKey: Hashable {
        let category: PlaceCategory
        let bucket: Bucket

        init(_ ranking: Ranking) {
            category = ranking.category
            bucket = ranking.bucket
        }
    }

    static func normalCDF(_ x: Double) -> Double {
        0.5 * erfc(-x / 2.squareRoot())
    }

    /// Inverse of the standard normal CDF using Peter Acklam's rational approximation, which
    /// has a relative error under 1.2e-9
    static func inverseNormalCDF(_ p: Double) -> Double {
        precondition(p > 0 && p < 1, "p must be in (0, 1)")

        let a = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
                 1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
        let b = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
                 6.680131188771972e+01, -1.328068155288572e+01]
        let c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
                 -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
        let d = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
                 3.754408661907416e+00]

        // The approximation uses one formula for the central region and another for the tails
        let tailCutoff = 0.02425

        func tail(_ q: Double) -> Double {
            (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
                / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
        }

        if p < tailCutoff {
            return tail((-2 * log(p)).squareRoot())
        } else if p > 1 - tailCutoff {
            return -tail((-2 * log(1 - p)).squareRoot())
        } else {
            let q = p - 0.5
            let r = q * q
            return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q
                / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
        }
    }

}
