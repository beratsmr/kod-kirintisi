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
    /// How many puzzles are shuffled together as one unit.
    ///
    /// The schedule is built block by block rather than as a single shuffle of
    /// the whole bank, and that is what makes the bank safely append-only. A
    /// block's order depends on the seed and on where the block starts, never
    /// on how many puzzles exist in total, so shipping new content leaves
    /// every earlier block — and therefore every day already seen — untouched.
    ///
    /// Shuffling the whole bank at once looked equivalent and was not: growing
    /// a bank from 120 to 130 puzzles changed all 120 of the first days,
    /// because every draw advances the generator and the sequence of draws
    /// depends on the count. `PuzzleBankIntegrityTests` keeps the bank a whole
    /// number of blocks, so a block is never half-filled by one release and
    /// completed by the next, which would move the days inside it.
    public static let blockSize = 30

    /// Number of puzzles the selector was built for.
    public let puzzleCount: Int

    /// Day zero of this installation's schedule.
    public let epoch: Date

    /// Bank indices in the order this installation will see them.
    private let permutation: [Int]

    /// Creates a selector over a bank of `puzzleCount` puzzles.
    /// - Parameter epoch: The day to start counting from, normally
    ///   ``UserProgress/installedOn``.
    /// - Returns: `nil` for an empty bank, which has no puzzle to select.
    public init?(seed: UInt64, puzzleCount: Int, epoch: Date) {
        guard puzzleCount > 0 else { return nil }
        self.puzzleCount = puzzleCount
        self.epoch = epoch

        var indices: [Int] = []
        indices.reserveCapacity(puzzleCount)
        for start in stride(from: 0, to: puzzleCount, by: Self.blockSize) {
            let end = min(start + Self.blockSize, puzzleCount)
            indices.append(contentsOf: Self.shuffledBlock(seed: seed, range: start ..< end))
        }
        permutation = indices
    }

    /// One block's indices in the order this installation will see them.
    ///
    /// Seeded from the installation seed mixed with the block's starting
    /// position, so every block draws from its own stream and none can be
    /// disturbed by a change to another.
    private static func shuffledBlock(seed: UInt64, range: Range<Int>) -> [Int] {
        // The multiplier is the golden-ratio constant SplitMix64 uses as its
        // increment. It is odd, so multiplying by the block start is
        // invertible and no two blocks can land on the same stream.
        var generator = SeededRandom(seed: seed ^ (UInt64(range.lowerBound) &* 0x9E37_79B9_7F4A_7C15))
        var indices = Array(range)
        // Fisher-Yates is written out rather than delegating to
        // `shuffled(using:)`, because the standard library does not promise a
        // stable shuffling algorithm across Swift releases. If it changed, every
        // user's schedule would silently shift after an app update.
        for position in stride(from: indices.count - 1, to: 0, by: -1) {
            let target = Int(generator.next(upperBound: UInt64(position + 1)))
            indices.swapAt(position, target)
        }
        return indices
    }

    /// Whole days from this installation's epoch to `date`, in the user's
    /// calendar.
    ///
    /// Dates before the epoch clamp to day zero, so a device whose clock is set
    /// backwards still gets a puzzle instead of nothing.
    public func dayIndex(for date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: epoch)
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

    /// Bank indices revealed by day `dayIndex`, oldest first, each exactly once.
    ///
    /// The permutation built at init already is one full, non-repeating cycle
    /// through every puzzle; ``index(for:calendar:)`` only wraps around it with
    /// `%` once a user has been active longer than the bank is long. This
    /// returns the prefix of that cycle a user reaching `dayIndex` has seen at
    /// least once — which is what an archive should show, since listing a
    /// second reveal of the same puzzle would just repeat the first.
    ///
    /// - Parameter dayIndex: A value from ``dayIndex(for:calendar:)``. Negative
    ///   values yield an empty array rather than trapping.
    public func revealedIndices(throughDayIndex dayIndex: Int) -> [Int] {
        guard dayIndex >= 0 else { return [] }
        return Array(permutation.prefix(min(dayIndex + 1, puzzleCount)))
    }
}
