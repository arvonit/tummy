//
//  Visit.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

import Foundation

/// One trip to a ranked place. A ranking keeps every visit, and the first one is when it was
/// ranked.
nonisolated struct Visit: Identifiable, Hashable {
    let id: UUID
    var rankingID: Ranking.ID
    /// The day you went, which you can backdate
    let date: Date
    /// When it was logged, to order visits on the same day
    let createdAt: Date
    var notes = ""
    var dishes: [String] = []
    /// Downscaled JPEGs
    var photos: [Data] = []

    /// Today, Yesterday, a weekday within the last week, or "November 8"
    var dayText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        if let days = calendar.dateComponents([.day], from: date, to: .now).day, days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.month(.wide).day())
    }

    static func isOlder(_ first: Visit, _ second: Visit) -> Bool {
        (first.date, first.createdAt) < (second.date, second.createdAt)
    }
}
