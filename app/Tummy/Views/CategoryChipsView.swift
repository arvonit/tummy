//
//  CategoryChipsView.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI

/// A horizontally scrolling row of capsule buttons: "All" followed by each category
struct CategoryChipsView: View {
    /// Called with the new selection, where nil means "All"
    let onSelectionChange: (PlaceCategory?) -> Void

    @State private var selectedCategory: PlaceCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Lets neighboring glass chips render and animate together as one surface
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    chip(title: "All", category: nil)
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        chip(title: category.title, category: category)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    func chip(title: String, category: PlaceCategory?) -> some View {
        let isSelected = category == selectedCategory

        return Button {
            selectedCategory = category
            onSelectionChange(category)
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .glassEffect(
                    // A see-through tint keeps the selected chip glassy instead of solid blue
                    isSelected
                        ? .regular.tint(.accentColor.opacity(0.5)).interactive()
                        : .regular.interactive(),
                    in: .capsule
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    // Glass needs something behind it to show off
    ZStack(alignment: .top) {
        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
            .ignoresSafeArea()
        CategoryChipsView { _ in }
    }
}
