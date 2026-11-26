//
//  SearchBarView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var query: String
    let onSubmit: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search restaurants", text: $query)
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !query.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") { query = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

#Preview {
    @Previewable @State var query = ""

    VStack(spacing: 20) {
        SearchBarView(query: $query) {}
        SearchBarView(query: .constant("pizza")) {}
    }
    .padding()
    .background(.green.opacity(0.3))
}
