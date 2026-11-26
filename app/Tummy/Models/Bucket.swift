//
//  Bucket.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import SwiftUI

nonisolated enum Bucket: String, CaseIterable, Decodable {
    case like
    case fine
    case dislike

    var title: String {
        switch self {
        case .like: "Liked it"
        case .fine: "It was fine"
        case .dislike: "Didn't like it"
        }
    }

    var color: Color {
        switch self {
        case .like: .green
        case .fine: .orange
        case .dislike: .red
        }
    }
}
