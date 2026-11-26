//
//  Restaurant.swift
//  Tummy
//
//  Created by Arvind on 11/25/26.
//

import Foundation

nonisolated struct Restaurant: Identifiable, Hashable {
    let id: UUID
    let name: String
    let cuisine: String
    let neighborhood: String
}
