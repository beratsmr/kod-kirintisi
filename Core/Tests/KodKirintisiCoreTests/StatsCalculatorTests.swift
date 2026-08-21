import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Statistics")
struct StatsCalculatorTests {
    private let referenceDate = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01T00:00:00Z

    private func record(
        _ puzzleID: String,
        isCorrect: Bool,
        offset: TimeInterval = 0
    ) -> AnswerRecord {
        AnswerRecord(
            puzzleID: puzzleID,
            selectedIndex: isCorrect ? 0 : 1,
            isCorrect: isCorrect,
            answeredAt: referenceDate.addingTimeInterval(offset)
        )
    }

    @Test("An empty history reports zeroes rather than dividing by zero")
    func emptyHistory() {
        let summary = StatsCalculator.overall(records: [AnswerRecord]())

        #expect(summary.answered == 0)
        #expect(summary.correct == 0)
        #expect(summary.accuracy == 0)
    }

    @Test("Totals count answers and correct answers")
    func countsTotals() {
        let summary = StatsCalculator.overall(records: [
            record("a", isCorrect: true),
            record("b", isCorrect: false),
            record("c", isCorrect: true),
            record("d", isCorrect: true)
        ])

        #expect(summary.answered == 4)
        #expect(summary.correct == 3)
        #expect(abs(summary.accuracy - 0.75) < 0.000_001)
    }

    @Test("A perfect history is fully accurate")
    func perfectAccuracy() {
        let summary = StatsCalculator.overall(records: [
            record("a", isCorrect: true),
            record("b", isCorrect: true)
        ])

        #expect(summary.accuracy == 1)
    }

    @Test("A history of only wrong answers is zero accurate")
    func zeroAccuracy() {
        let summary = StatsCalculator.overall(records: [
            record("a", isCorrect: false),
            record("b", isCorrect: false)
        ])

        #expect(summary.answered == 2)
        #expect(summary.accuracy == 0)
    }

    @Test("Answers are grouped by their puzzle's category")
    func groupsByCategory() {
        let puzzles = [
            makePuzzle(id: "swift-a-001", category: .swiftLanguage),
            makePuzzle(id: "swift-b-001", category: .swiftLanguage),
            makePuzzle(id: "conc-a-001", category: .concurrency)
        ]
        let records = [
            record("swift-a-001", isCorrect: true),
            record("swift-b-001", isCorrect: false),
            record("conc-a-001", isCorrect: true)
        ]

        let byCategory = StatsCalculator.byCategory(records: records, puzzles: puzzles)

        #expect(byCategory[.swiftLanguage] == StatsCalculator.Summary(answered: 2, correct: 1))
        #expect(byCategory[.concurrency] == StatsCalculator.Summary(answered: 1, correct: 1))
    }

    @Test("Untouched categories are absent, not zero")
    func skipsUntouchedCategories() {
        let puzzles = [
            makePuzzle(id: "swift-a-001", category: .swiftLanguage),
            makePuzzle(id: "algo-a-001", category: .algorithms)
        ]
        let records = [record("swift-a-001", isCorrect: true)]

        let byCategory = StatsCalculator.byCategory(records: records, puzzles: puzzles)

        #expect(byCategory.count == 1)
        #expect(byCategory[.algorithms] == nil)
    }

    @Test("An answer for an unknown puzzle is ignored rather than crashing")
    func ignoresUnknownPuzzles() {
        let puzzles = [makePuzzle(id: "swift-a-001", category: .swiftLanguage)]
        let records = [
            record("swift-a-001", isCorrect: true),
            record("vanished-puzzle-001", isCorrect: true)
        ]

        let byCategory = StatsCalculator.byCategory(records: records, puzzles: puzzles)

        #expect(byCategory.count == 1)
        #expect(byCategory[.swiftLanguage]?.answered == 1)
    }

    @Test("An empty history produces no categories")
    func emptyHistoryHasNoCategories() {
        let puzzles = [makePuzzle(id: "swift-a-001", category: .swiftLanguage)]

        let byCategory = StatsCalculator.byCategory(records: [], puzzles: puzzles)

        #expect(byCategory.isEmpty)
    }

    @Test("Category accuracy is computed per category, not globally")
    func accuracyIsPerCategory() {
        let puzzles = [
            makePuzzle(id: "swift-a-001", category: .swiftLanguage),
            makePuzzle(id: "swift-b-001", category: .swiftLanguage),
            makePuzzle(id: "conc-a-001", category: .concurrency),
            makePuzzle(id: "conc-b-001", category: .concurrency)
        ]
        let records = [
            record("swift-a-001", isCorrect: true),
            record("swift-b-001", isCorrect: true),
            record("conc-a-001", isCorrect: false),
            record("conc-b-001", isCorrect: false)
        ]

        let byCategory = StatsCalculator.byCategory(records: records, puzzles: puzzles)

        #expect(byCategory[.swiftLanguage]?.accuracy == 1)
        #expect(byCategory[.concurrency]?.accuracy == 0)
        #expect(StatsCalculator.overall(records: records).accuracy == 0.5)
    }
}
