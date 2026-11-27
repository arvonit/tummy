//
//  User.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Foundation

nonisolated struct User: Identifiable, Hashable {
    let id: UUID
    let name: String
    let handle: String
    let memberSince: Date

    /// "Maya Chen" → "MC"
    var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

/// One-way: `followerID` sees `followeeID`'s activity
nonisolated struct Follow: Hashable {
    let followerID: User.ID
    let followeeID: User.ID
}
