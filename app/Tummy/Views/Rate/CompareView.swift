//
//  CompareView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// "Which did you like more?" between the new place and one already in the list
struct CompareView: View {
    let model: RateFlowModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Which did you like more?")
                .font(.title2.bold())
                .padding(.vertical)

            card(
                name: model.place.name,
                details: model.existing?.restaurant.details ?? model.place.city
            ) { answer(newIsBetter: true) }

            Text("or")
                .foregroundStyle(.secondary)

            if let other = model.comparisonPlace {
                card(name: other.restaurant.name, details: other.restaurant.details) {
                    answer(newIsBetter: false)
                }
                .id(other.id)
                .transition(.push(from: .trailing))
            }

            Spacer()
        }
        .padding()
        .animation(.default, value: model.insertion.midpoint)
        .navigationTitle(model.category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Undo", systemImage: "arrow.uturn.backward") {
                model.undo()
            }
            .disabled(!model.insertion.canUndo)

            Button("Skip") {
                Task { await model.skip() }
            }
        }
    }

    private func card(name: String, details: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: model.category.symbolName)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.title3.bold())
                    .fontDesign(.serif)
                    .multilineTextAlignment(.center)
                Text(details)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28))
    }

    private func answer(newIsBetter: Bool) {
        Task { await model.answer(newIsBetter: newIsBetter) }
    }
}
