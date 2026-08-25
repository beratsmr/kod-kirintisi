import Foundation

/// Everything a single day's screen or widget needs, in one value.
///
/// The widget runs in a tight refresh budget and has no room for logic, so the
/// three questions it would otherwise ask — *which* puzzle is today's, *has* it
/// been answered, and *how long* is the streak — are answered here instead, by
/// a pure function that compiles and tests on Linux.
///
/// Nothing in here reads the clock: the date and calendar are passed in, which
/// is what lets the timeline provider ask for "the digest at next midnight"
/// just as easily as for the current one.
public struct DailyDigest: Sendable, Equatable {
    /// Today's puzzle.
    public let puzzle: Puzzle
    /// The user's answer, or `nil` while the day is still open.
    public let record: AnswerRecord?
    /// Run of consecutive correct days, per ``StreakCalculator``.
    public let currentStreak: Int
    /// Days since the schedule epoch, for display and for debugging.
    public let dayIndex: Int

    public init(puzzle: Puzzle, record: AnswerRecord?, currentStreak: Int, dayIndex: Int) {
        self.puzzle = puzzle
        self.record = record
        self.currentStreak = currentStreak
        self.dayIndex = dayIndex
    }

    /// Whether the day has been answered.
    public var isAnswered: Bool {
        record != nil
    }

    /// Whether the day was answered correctly. `false` while unanswered.
    public var isCorrect: Bool {
        record?.isCorrect ?? false
    }

    /// Builds the digest for `date`.
    ///
    /// - Returns: `nil` only when the bank is empty, which ``PuzzleBank``
    ///   validation already rules out for the bundled bank. Callers that pass
    ///   the bundled bank can treat `nil` as impossible, but are still forced to
    ///   handle it rather than force-unwrapping.
    public static func make(
        bank: PuzzleBank,
        progress: UserProgress,
        date: Date,
        calendar: Calendar
    ) -> DailyDigest? {
        guard let selector = DailyPuzzleSelector(
            seed: progress.installSeed,
            puzzleCount: bank.puzzles.count,
            epoch: progress.installedOn
        ) else {
            return nil
        }

        let index = selector.index(for: date, calendar: calendar)
        guard bank.puzzles.indices.contains(index) else { return nil }
        let puzzle = bank.puzzles[index]

        let records = progress.records.values
        let correctDays = StreakCalculator.correctDays(from: records, calendar: calendar)
        let wrongDays = StreakCalculator.wrongDays(from: records, calendar: calendar)

        return DailyDigest(
            puzzle: puzzle,
            record: progress.record(for: puzzle.id),
            currentStreak: StreakCalculator.currentStreak(
                correctlyAnsweredDays: correctDays,
                wronglyAnsweredDays: wrongDays,
                today: date,
                calendar: calendar
            ),
            dayIndex: selector.dayIndex(for: date, calendar: calendar)
        )
    }
}
