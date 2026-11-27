//
//  AvatarView.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import SwiftUI

/// A colored circle with the user's initials, until profiles have photos
struct AvatarView: View {
    let user: User
    var diameter: CGFloat = 48

    private static let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .teal, .indigo]

    /// Hashed from the handle, so each person keeps the same color
    private var color: Color {
        Self.colors[Int(user.handle.stableHash % UInt64(Self.colors.count))]
    }

    var body: some View {
        Text(user.initials)
            .font(.system(size: diameter * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background(color.gradient, in: .circle)
            .accessibilityLabel(user.name)
    }
}

#Preview {
    HStack {
        ForEach(SampleData.users.all) { AvatarView(user: $0) }
    }
}
