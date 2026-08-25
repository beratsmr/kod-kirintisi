import Foundation
import Testing
@testable import KodKirintisiCore

/// The bank is meant to keep growing — more Swift puzzles now, whole new
/// subjects later — and every release must leave the days a user has already
/// lived through exactly where they were. That property is what block-based
/// shuffling buys, and these are the tests that hold it in place.
@Suite("Growing the puzzle bank")
struct DailyPuzzleSelectorGrowthTests {
    /// Day zero for the fixture installation: 2026-01-01T00:00:00Z.
    private let epoch = Date(timeIntervalSince1970: 1_767_225_600)

    /// A fixed calendar so a test never depends on where it runs.
    private func calendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)))
    }

    /// The test this whole design exists for.
    ///
    /// Shuffling the bank as a single unit passed every other test in the
    /// suite and still failed this one: growing 120 to 150 changed all 120 of
    /// the days already served, because each draw advances the generator and
    /// the number of draws depends on the count. A user would have opened the
    /// app after an update to find yesterday's puzzle replaced.
    @Test("Appending puzzles leaves every day already served untouched")
    func growingTheBankPreservesEarlierDays() throws {
        let calendar = try calendar()
        let before = try #require(DailyPuzzleSelector(seed: 4242, puzzleCount: 120, epoch: epoch))
        let after = try #require(DailyPuzzleSelector(seed: 4242, puzzleCount: 150, epoch: epoch))

        for offset in 0 ..< 120 {
            let day = try date(2026, 1, 1 + offset, in: calendar)
            #expect(
                before.index(for: day, calendar: calendar)
                    == after.index(for: day, calendar: calendar),
                "day \(offset) changed when the bank grew"
            )
        }
    }

    /// Content ships more than once, so stability has to survive a chain of
    /// releases, not just one.
    @Test("Repeated growth keeps the schedule stable at every step")
    func repeatedGrowthPreservesEarlierDays() throws {
        let sizes = [30, 60, 90, 120]
        let selectors = try sizes.map { size in
            try #require(DailyPuzzleSelector(seed: 77, puzzleCount: size, epoch: epoch))
        }

        for (index, selector) in selectors.enumerated().dropFirst() {
            let previous = selectors[index - 1]
            let sharedDays = sizes[index - 1]
            #expect(
                previous.revealedIndices(throughDayIndex: sharedDays - 1)
                    == selector.revealedIndices(throughDayIndex: sharedDays - 1),
                "growing to \(sizes[index]) disturbed the first \(sharedDays) days"
            )
        }
    }

    /// Stability comes from each block drawing only from its own slice of the
    /// bank, so a block's contents cannot depend on how many blocks follow it.
    @Test("Each block permutes only its own slice of the bank")
    func blocksStayWithinTheirOwnRange() throws {
        let blockSize = DailyPuzzleSelector.blockSize
        let selector = try #require(
            DailyPuzzleSelector(seed: 11, puzzleCount: blockSize * 4, epoch: epoch)
        )

        let schedule = selector.revealedIndices(throughDayIndex: blockSize * 4 - 1)

        for block in 0 ..< 4 {
            let start = block * blockSize
            let slice = Set(schedule[start ..< start + blockSize])
            #expect(slice == Set(start ..< start + blockSize), "block \(block) drew outside its range")
        }
    }

    /// A block must actually shuffle. Handing back the bank in file order would
    /// pass every stability test above and give every user the same schedule.
    @Test("A block is shuffled, not left in bank order")
    func blocksAreShuffled() throws {
        let blockSize = DailyPuzzleSelector.blockSize
        let selector = try #require(
            DailyPuzzleSelector(seed: 11, puzzleCount: blockSize, epoch: epoch)
        )

        #expect(selector.revealedIndices(throughDayIndex: blockSize - 1) != Array(0 ..< blockSize))
    }

    /// The real bank is kept a whole number of blocks, but nothing in the type
    /// requires it, and a half-filled trailing block must still behave.
    @Test("A bank that does not fill its last block is still a full cycle")
    func handlesAPartialTrailingBlock() throws {
        let count = DailyPuzzleSelector.blockSize + 7
        let selector = try #require(DailyPuzzleSelector(seed: 5, puzzleCount: count, epoch: epoch))

        let schedule = selector.revealedIndices(throughDayIndex: count - 1)

        #expect(schedule.count == count)
        #expect(Set(schedule) == Set(0 ..< count))
    }
}
