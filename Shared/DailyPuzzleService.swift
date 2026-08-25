import Foundation
import KodKirintisiCore

/// Reads and updates today's puzzle on behalf of whichever process is running.
///
/// This is the only place where the two halves meet: `Core` supplies the pure
/// logic and knows nothing about containers, ``AppGroup`` supplies the location,
/// and this type hands one to the other. It holds no state itself — the bank is
/// cached inside ``PuzzleBank/shared()`` and progress lives in the actor — so
/// the widget can build one per timeline reload without paying for it.
struct DailyPuzzleService: Sendable {
    enum Failure: Error {
        /// The App Group container could not be resolved.
        case containerUnavailable
        /// The bank held no puzzle for the requested day.
        case noPuzzleForDay
    }

    static let shared = DailyPuzzleService()

    private let store: ProgressStore?

    /// - Parameter progressURL: Where progress is kept. Injected so that tests
    ///   and previews can point at a temporary file instead of the container.
    init(progressURL: URL? = AppGroup.progressURL) {
        store = progressURL.map { url in
            ProgressStore(
                persistence: FileProgressStore(url: url),
                makeSeed: { UInt64.random(in: .min ... .max) },
                now: { .now }
            )
        }
    }

    /// The digest for `date`, loading progress and the bank as needed.
    func digest(
        for date: Date = .now,
        calendar: Calendar = .current
    ) async throws -> DailyDigest {
        guard let store else { throw Failure.containerUnavailable }
        let progress = try await store.progress()
        return try digest(for: date, calendar: calendar, progress: progress)
    }

    /// Records an answer to the puzzle of `date` and returns the updated digest.
    ///
    /// The correctness check happens here rather than in the caller so that the
    /// widget button only has to know which position was tapped — it never sees
    /// ``Puzzle/correctIndex`` and so cannot leak it.
    ///
    /// Answering a day twice is a no-op: ``ProgressStore`` keeps the first
    /// answer, and the digest returned reflects that stored one.
    @discardableResult
    func answer(
        choiceIndex: Int,
        at date: Date = .now,
        calendar: Calendar = .current
    ) async throws -> DailyDigest {
        guard let store else { throw Failure.containerUnavailable }

        let current = try await digest(
            for: date, calendar: calendar, progress: store.progress()
        )
        guard current.puzzle.choices.indices.contains(choiceIndex) else {
            return current
        }

        try await store.recordAnswer(AnswerRecord(
            puzzleID: current.puzzle.id,
            selectedIndex: choiceIndex,
            isCorrect: choiceIndex == current.puzzle.correctIndex,
            answeredAt: date
        ))

        return try await digest(
            for: date, calendar: calendar, progress: store.progress()
        )
    }

    /// Every puzzle revealed through `date`, oldest first — the data behind
    /// the Archive screen. See ``PuzzleArchive`` for what "revealed" means.
    func archive(
        through date: Date = .now,
        calendar: Calendar = .current
    ) async throws -> [PuzzleArchive.Entry] {
        guard let store else { throw Failure.containerUnavailable }
        let progress = try await store.progress()
        let bank = try PuzzleBank.shared()
        return PuzzleArchive.entries(bank: bank, progress: progress, through: date, calendar: calendar)
    }

    /// Streaks and per-category accuracy for the Statistics screen.
    func stats(
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) async throws -> StatsSnapshot {
        guard let store else { throw Failure.containerUnavailable }
        let progress = try await store.progress()
        let bank = try PuzzleBank.shared()
        let records = progress.records.values

        let correctDays = StreakCalculator.correctDays(from: records, calendar: calendar)
        let wrongDays = StreakCalculator.wrongDays(from: records, calendar: calendar)

        return StatsSnapshot(
            overall: StatsCalculator.overall(records: records),
            byCategory: StatsCalculator.byCategory(records: records, puzzles: bank.puzzles),
            currentStreak: StreakCalculator.currentStreak(
                correctlyAnsweredDays: correctDays, wronglyAnsweredDays: wrongDays,
                today: date, calendar: calendar
            ),
            longestStreak: StreakCalculator.longestStreak(
                correctlyAnsweredDays: correctDays, calendar: calendar
            )
        )
    }

    /// Clears every recorded answer. The install seed is untouched, so the
    /// schedule the user has already partly seen does not reshuffle under
    /// them — see ``ProgressStore/reset()``.
    func resetProgress() async throws {
        guard let store else { throw Failure.containerUnavailable }
        try await store.reset()
    }

    private func digest(
        for date: Date,
        calendar: Calendar,
        progress: UserProgress
    ) throws -> DailyDigest {
        let bank = try PuzzleBank.shared()
        guard let digest = DailyDigest.make(
            bank: bank, progress: progress, date: date, calendar: calendar
        ) else {
            throw Failure.noPuzzleForDay
        }
        return digest
    }
}
