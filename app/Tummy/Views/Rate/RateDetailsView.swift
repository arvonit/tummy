//
//  RateDetailsView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import PhotosUI
import SwiftUI

/// The first step of the rate flow: which list, how it was, and the visit's details
struct RateDetailsView: View {
    @Bindable var model: RateFlowModel
    let onClose: () -> Void

    @State private var newDish = ""
    @State private var photoItems: [PhotosPickerItem] = []

    var body: some View {
        Form {
            Section {
                Picker("Add to my list of", selection: $model.category) {
                    ForEach(PlaceCategory.allCases, id: \.self) { category in
                        Label(category.title, systemImage: category.symbolName)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("How was it?") {
                bucketPicker
                if model.existing != nil && model.isSameList {
                    Toggle("Re-rank", isOn: $model.reRank)
                }
            }

            Section {
                notesRow
                dishesRow
                photosRow
                dateRow
            }
        }
        .navigationTitle(model.place.name)
        .navigationSubtitle(model.category.singularTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(role: .close, action: onClose)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                Task { await model.confirmDetails() }
            } label: {
                Text("Rank")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .disabled(model.bucket == nil)
            .padding()
        }
        .onChange(of: photoItems) {
            Task { await model.loadPhotos(from: photoItems) }
        }
    }

    private var bucketPicker: some View {
        HStack {
            ForEach(Bucket.allCases, id: \.self) { bucket in
                let isSelected = model.bucket == bucket
                Button {
                    model.bucket = bucket
                } label: {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(bucket.color.opacity(isSelected ? 1 : 0.35))
                            .frame(width: 64, height: 64)
                            .overlay {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                        Text(bucket.title)
                            .font(.subheadline)
                            .foregroundStyle(isSelected ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(duration: 0.25), value: model.bucket)
    }

    private var notesRow: some View {
        Label {
            TextField("Add notes", text: $model.notes, axis: .vertical)
        } icon: {
            Image(systemName: "square.and.pencil")
        }
    }

    private var dishesRow: some View {
        Label {
            VStack(alignment: .leading) {
                TextField("Add favorite dishes", text: $newDish)
                    .submitLabel(.done)
                    .onSubmit(addDish)
                if !model.dishes.isEmpty {
                    chips(model.dishes) { dish in
                        model.dishes.removeAll { $0 == dish }
                    }
                }
            }
        } icon: {
            Image(systemName: "fork.knife")
        }
    }

    private var photosRow: some View {
        Label {
            VStack(alignment: .leading) {
                PhotosPicker(
                    model.photos.isEmpty ? "Add photos" : "Change photos",
                    selection: $photoItems,
                    maxSelectionCount: 5,
                    matching: .images
                )
                if !model.photos.isEmpty {
                    PhotoStripView(photos: model.photos, side: 64)
                }
            }
        } icon: {
            Image(systemName: "camera")
        }
    }

    private var dateRow: some View {
        Label {
            VStack(alignment: .leading) {
                DatePicker(
                    "Visit date",
                    selection: $model.visitDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                HStack {
                    ForEach(0..<3) { daysAgo in
                        dateChip(daysAgo: daysAgo)
                    }
                }
            }
        } icon: {
            Image(systemName: "calendar")
        }
    }

    private func dateChip(daysAgo: Int) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
        let title = ["Today", "Yesterday", "2 days ago"][daysAgo]
        let isSelected = calendar.isDate(model.visitDate, inSameDayAs: date)

        return Button(title) { model.visitDate = date }
            .buttonStyle(.bordered)
            .tint(isSelected ? .accentColor : .secondary)
            .font(.subheadline)
    }

    /// Removable capsules, scrolling sideways when there are many
    private func chips(_ titles: [String], onRemove: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(titles, id: \.self) { title in
                    Button { onRemove(title) } label: {
                        Label(title, systemImage: "xmark")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                    .buttonStyle(.bordered)
                    .font(.subheadline)
                }
            }
        }
    }

    private func addDish() {
        let dish = newDish.trimmingCharacters(in: .whitespaces)
        if !dish.isEmpty && !model.dishes.contains(dish) {
            model.dishes.append(dish)
        }
        newDish = ""
    }
}

/// "Title ✕" instead of "✕ Title"
private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}

#Preview {
    NavigationStack {
        RateDetailsView(
            model: RateFlowModel(summary: PlaceSummary.samples[3], context: AppContext()),
            onClose: {}
        )
    }
}
