//
//  FeedCellView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// One visit in the Feed or a Profile's Activity: who went where, the score, and what they said
struct FeedCellView: View {
    let item: FeedItem
    let onOpenUser: () -> Void
    let onRank: () -> Void

    private var restaurant: Restaurant { item.ranking.restaurant }
    private var visit: Visit { item.visit }
    private var symbolName: String { item.ranking.category.symbolName }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onOpenUser) {
                    AvatarView(user: item.user)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        "\(Text(item.user.name).bold()) \(item.verb) \(Text(restaurant.name).bold())"
                    )
                    Text("\(Image(systemName: symbolName)) · \(restaurant.neighborhood)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                ScoreBadgeView(score: item.ranking.score, bucket: item.ranking.bucket)
            }

            if !visit.photos.isEmpty {
                PhotoStripView(photos: visit.photos)
            }
            if !visit.notes.isEmpty {
                Text("\(Text("Notes:").bold()) \(visit.notes)")
            }
            if !visit.dishes.isEmpty {
                Text("\(Text("Dishes:").bold()) \(visit.dishes.joined(separator: ", "))")
            }

            HStack {
                Text(visit.dayText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Rank", systemImage: "plus.circle", action: onRank)
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .tint(.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let users = SampleData.users
    let items = FeedItem.items(
        rankings: SampleData.rankings,
        visits: SampleData.visits,
        users: users.all,
        showing: Set(users.all.map(\.id))
    )
    List(items.prefix(8)) { item in
        FeedCellView(item: item, onOpenUser: {}, onRank: {})
    }
    .listStyle(.plain)
}
