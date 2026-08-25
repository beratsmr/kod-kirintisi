import Foundation

/// The puzzles a user has already had a chance to see, each paired with its
/// answer if there is one.
///
/// Every install gets a different order — the daily shuffle is seeded per
/// user — so "past questions" cannot be a fixed slice of the bank. It has to
/// be recomputed from the same selector the daily puzzle itself comes from.
/// Doing that here, next to the schedule it depends on, keeps the Archive
/// screen from ever being able to show a puzzle before its day, and keeps the
/// rule testable without a device.
public enum PuzzleArchive {
    /// One puzzle in the archive: what it was, whether it has been answered,
    /// and which day first revealed it.
    public struct Entry: Sendable, Equatable, Identifiable {
        public let puzzle: Puzzle
        /// The user's answer, or `nil` if this puzzle has not been answered.
        public let record: AnswerRecord?
        /// Days since the schedule epoch. See ``DailyPuzzleSelector``.
        public let revealedOnDayIndex: Int

        public init(puzzle: Puzzle, record: AnswerRecord?, revealedOnDayIndex: Int) {
            self.puzzle = puzzle
            self.record = record
            self.revealedOnDayIndex = revealedOnDayIndex
        }

        public var id: String {
            puzzle.id
        }
    }

    /// Every puzzle revealed by `date`, oldest first, each appearing once.
    ///
    /// A puzzle whose day recurs — the schedule wraps once a user has been
    /// active longer than the bank is long — is not repeated: it already
    /// appears at its first reveal, and its ``AnswerRecord`` is keyed by
    /// puzzle id rather than by day, so it is the same record either time.
    public static func entries(
        bank: PuzzleBank,
        progress: UserProgress,
        through date: Date,
        calendar: Calendar
    ) -> [Entry] {
        guard let selector = DailyPuzzleSelector(
            seed: progress.installSeed,
            puzzleCount: bank.puzzles.count
        ) else {
            return []
        }

        let dayIndex = selector.dayIndex(for: date, calendar: calendar)
        let revealed = selector.revealedIndices(throughDayIndex: dayIndex)

        return revealed.enumerated().map { revealDay, bankIndex in
            let puzzle = bank.puzzles[bankIndex]
            return Entry(
                puzzle: puzzle,
                record: progress.record(for: puzzle.id),
                revealedOnDayIndex: revealDay
            )
        }
    }
}
