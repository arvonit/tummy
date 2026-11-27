//
//  RateFlowView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// The rate sheet: details, then comparisons, then the result, in one navigation stack
struct RateFlowView: View {
    @Bindable var model: RateFlowModel
    let onClose: () -> Void

    var body: some View {
        NavigationStack(path: $model.path) {
            RateDetailsView(model: model, onClose: onClose)
                .navigationDestination(for: RateFlowModel.Step.self) { step in
                    switch step {
                    case .compare: CompareView(model: model)
                    case .result: RateResultView(model: model, onDone: onClose)
                    }
                }
        }
    }
}

#Preview {
    RateFlowView(
        model: RateFlowModel(summary: PlaceSummary.samples[3], context: AppContext()),
        onClose: {}
    )
}
