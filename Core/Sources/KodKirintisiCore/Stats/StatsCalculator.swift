import Foundation

/// Aggregates answer records into the figures the statistics screen shows.
///
/// See `docs/SPEC.md` §5.2.
public enum StatsCalculator {
    /// How many puzzles were answered, and how many of them correctly.
    public struct Summary: Sendable, Equatable {
        public let answered: Int
        public let correct: Int

        public init(answered: Int, correct: Int) {
            self.answered = answered
            self.correct = correct
        }

        /// Share of correct answers, from 0 to 1. Zero when nothing is answered,
        /// so the caller never has to guard against dividing by zero.
        public var accuracy: Double {
            guard answered > 0 else { return 0 }
            return Double(correct) / Double(answered)
        }
    }

    /// Totals across every answer.
    public static func overall(records: some Sequence<AnswerRecord>) -> Summary {
        var answered = 0
        var correct = 0
        for record in records {
            answered += 1
            if record.isCorrect {
                correct += 1
            }
        }
        return Summary(answered: answered, correct: correct)
    }

    /// Totals per category, for the bar chart on the statistics screen.
    ///
    /// Categories the user has not reached yet are absent from the result
    /// rather than present with zeroes, so the chart can skip them.
    /// Records whose puzzle is not in `puzzles` are ignored — that happens when
    /// a puzzle id disappears from the bank, which should never ship, but the
    /// statistics screen is the wrong place to crash over it.
    public static func byCategory(
        records: some Sequence<AnswerRecord>,
        puzzles: [Puzzle]
    ) -> [PuzzleCategory: Summary] {
        let categoryByID = Dictionary(
            puzzles.map { ($0.id, $0.category) },
            uniquingKeysWith: { first, _ in first }
        )

        var answered: [PuzzleCategory: Int] = [:]
        var correct: [PuzzleCategory: Int] = [:]
        for record in records {
            guard let category = categoryByID[record.puzzleID] else { continue }
            answered[category, default: 0] += 1
            if record.isCorrect {
                correct[category, default: 0] += 1
            }
        }

        return answered.reduce(into: [:]) { result, entry in
            let (category, total) = entry
            result[category] = Summary(answered: total, correct: correct[category] ?? 0)
        }
    }
}
