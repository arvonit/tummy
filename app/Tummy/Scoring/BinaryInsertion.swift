//
//  BinaryInsertion.swift
//  Tummy
//
//  Created by Arvind on 11/26/26.
//

/// Finds where a new place goes in a bucket by asking "Which did you like more?" against the
/// middle of a shrinking window. Positions count from the worst place (0), like `Ranking`.
nonisolated struct BinaryInsertion {
    /// The new place goes somewhere in `low...high`
    private(set) var low = 0
    private(set) var high: Int
    private var history: [(low: Int, high: Int)] = []

    init(count: Int) {
        high = count
    }

    var isDone: Bool { low == high }
    /// The position of the place to compare against next
    var midpoint: Int { (low + high) / 2 }
    /// Where to insert, once `isDone`
    var position: Int { low }
    var canUndo: Bool { !history.isEmpty }

    mutating func answer(newIsBetter: Bool) {
        history.append((low, high))
        if newIsBetter {
            low = midpoint + 1
        } else {
            high = midpoint
        }
    }

    /// Stops asking and puts the new place just below the current comparison, as if they tied
    mutating func skip() {
        high = midpoint
        low = high
    }

    mutating func undo() {
        if let previous = history.popLast() {
            (low, high) = previous
        }
    }
}
