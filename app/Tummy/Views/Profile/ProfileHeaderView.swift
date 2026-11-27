//
//  ProfileHeaderView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// The top of a Profile: avatar, handle, counts, and, on your own profile, a Been row
struct ProfileHeaderView: View {
    let user: User
    let followerCount: Int
    let followingCount: Int
    let rankedCount: Int
    /// Only set on your own profile, where it opens My Lists
    var onOpenBeen: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            AvatarView(user: user, diameter: 96)

            VStack(spacing: 2) {
                Text("@\(user.handle)")
                    .font(.headline)
                Text("Member since \(user.memberSince.formatted(.dateTime.month(.wide).year()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                count(followerCount, "Followers")
                count(followingCount, "Following")
                count(rankedCount, "Ranked")
            }
            .padding(.vertical, 4)

            if let onOpenBeen {
                Button(action: onOpenBeen) {
                    HStack {
                        Label("Been", systemImage: "checkmark.circle")
                            .font(.headline)
                        Spacer()
                        Text("\(rankedCount)")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func count(_ value: Int, _ title: String) -> some View {
        VStack {
            Text("\(value)")
                .font(.headline)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
