//
//  RateResultView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// The last step: the place's new score and where it landed in its list
struct RateResultView: View {
    let model: RateFlowModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text(model.place.name)
                .font(.largeTitle.bold())
                .fontDesign(.serif)
                .multilineTextAlignment(.center)

            if let result = model.result {
                ScoreBadgeView(
                    score: result.ranking.score,
                    bucket: result.ranking.bucket,
                    isLarge: true
                )
                Text("#\(result.rank) of \(result.count) in \(model.category.title)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
        }
        .padding()
        .navigationBarBackButtonHidden()
    }
}
