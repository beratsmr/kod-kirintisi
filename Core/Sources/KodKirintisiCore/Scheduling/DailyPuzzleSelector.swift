import Foundation

/// Picks the puzzle of the day, as a pure function of the date.
///
/// There is no backend, so the app and the widget each compute the answer
/// independently and must always agree. Nothing here reads the clock or the
/// system random generator: the date and the calendar are passed in, and the
/// shuffle is seeded, which is what makes the whole thing testable.
///
/// See `docs/SPEC.md` §8.
public struct DailyPuzzleSelector: Sendable {
    /// Day zero of the schedule.
    public static let epoch = DateComponents(year: 2026, month: 1, day: 1)

    /// Number of puzzles the selector was built for.
    public let puzzleCount: Int

    /// Bank indices in the order this installation will see them.
    private let permutation: [Int]

    /// Creates a selector over a bank of `puzzleCount` puzzles.
    /// - Returns: `nil` for an empty bank, which has no puzzle to select.
    public init?(seed: UInt64, puzzleCount: Int) {
        guard puzzleCount > 0 else { return nil }
        self.puzzleCount = puzzleCount

        var generator = SeededRandom(seed: seed)
        var indices = Array(0 ..< puzzleCount)
        // Fisher-Yates is written out rather than delegating to
        // `shuffled(using:)`, because the standard library does not promise a
        // stable shuffling algorithm across Swift releases. If it changed, every
        // user's schedule would silently shift after an app update.
        for position in stride(from: puzzleCount - 1, to: 0, by: -1) {
            let target = Int(generator.next(upperBound: UInt64(position + 1)))
            indices.swapAt(position, target)
        }
        permutation = indices
    }

    /// Whole days from the epoch to `date`, in the user's calendar.
    ///
    /// Dates before the epoch clamp to day zero, so a device whose clock is set
    /// backwards still gets a puzzle instead of nothing.
    public func dayIndex(for date: Date, calendar: Calendar) -> Int {
        guard let epochDate = calendar.date(from: Self.epoch) else { return 0 }
        let start = calendar.startOfDay(for: epochDate)
        let target = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        return max(0, days)
    }

    /// The bank index to show on `date`.
    ///
    /// Days are measured with `startOfDay` in the given calendar, so the puzzle
    /// changes at the user's local midnight, daylight saving shifts included.
    public func index(for date: Date, calendar: Calendar) -> Int {
        permutation[dayIndex(for: date, calendar: calendar) % permutation.count]
    }
}
