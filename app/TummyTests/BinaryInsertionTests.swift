//
//  BinaryInsertionTests.swift
//  TummyTests
//
//  Created by Arvind on 11/26/26.
//

import Foundation
import Testing
@testable import Tummy

struct BinaryInsertionTests {

    /// Answers every question as if the new place belonged at `target` (0 = worst)
    private func insert(at target: Int, count: Int) -> (position: Int, questions: Int) {
        var insertion = BinaryInsertion(count: count)
        var questions = 0
        while !insertion.isDone {
            insertion.answer(newIsBetter: target > insertion.midpoint)
            questions += 1
        }
        return (insertion.position, questions)
    }

    @Test func emptyListNeedsNoQuestions() {
        #expect(BinaryInsertion(count: 0).isDone)
    }

    @Test(arguments: [1, 2, 5, 13, 50])
    func everyTargetIsFound(count: Int) {
        let maxQuestions = Int(ceil(log2(Double(count + 1))))
        for target in 0...count {
            let result = insert(at: target, count: count)
            #expect(result.position == target)
            #expect(result.questions <= maxQuestions)
        }
    }

    @Test func skipInsertsAtTheCurrentComparison() {
        var insertion = BinaryInsertion(count: 10)
        insertion.answer(newIsBetter: true)
        let midpoint = insertion.midpoint

        insertion.skip()

        #expect(insertion.isDone)
        #expect(insertion.position == midpoint)
    }

    @Test func undoRestoresThePreviousWindow() {
        var insertion = BinaryInsertion(count: 10)
        insertion.answer(newIsBetter: true)
        let afterFirst = (insertion.low, insertion.high)
        insertion.answer(newIsBetter: false)

        insertion.undo()
        #expect((insertion.low, insertion.high) == afterFirst)

        insertion.undo()
        #expect((insertion.low, insertion.high) == (0, 10))
        #expect(!insertion.canUndo)
    }

}
