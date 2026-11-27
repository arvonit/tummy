//
//  ProfileStatsView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Charts
import SwiftUI

/// How a person's scores spread across the curve, and how many places they've ranked in each
/// category
struct ProfileStatsView: View {
    let rankings: [ScoredRanking]

    private struct Bin: Identifiable {
        let start: Double
        let count: Int
        var id: Double { start }
    }

    private static let binWidth = 0.5

    /// Half-point bins from 0 to 10. The bucket edges (4 and 6.5) fall on bin edges, so each
    /// bar is one bucket's color.
    private var bins: [Bin] {
        stride(from: 0, to: 10, by: Self.binWidth).map { start in
            Bin(
                start: start,
                count: rankings.count { $0.score >= start && $0.score < start + Self.binWidth }
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score distribution")
                .font(.headline)

            Chart(bins) { bin in
                // A small gap between bars
                RectangleMark(
                    xStart: .value("Score", bin.start + 0.03),
                    xEnd: .value("Score", bin.start + Self.binWidth - 0.03),
                    yStart: .value("Places", 0),
                    yEnd: .value("Places", bin.count)
                )
                .foregroundStyle(ScoreCurve.bucket(for: bin.start).color)
            }
            .chartXScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1))
            }
            .frame(height: 160)

            HStack {
                ForEach(PlaceCategory.allCases, id: \.self) { category in
                    VStack(spacing: 4) {
                        Image(systemName: category.symbolName)
                            .foregroundStyle(.secondary)
                        Text("\(rankings.count { $0.category == category })")
                            .font(.headline)
                        Text(category.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            Text("Activity")
                .font(.headline)
                .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProfileStatsView(rankings: ScoreCurve.scored(SampleData.rankings))
        .padding()
}
