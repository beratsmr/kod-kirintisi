import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Puzzle archive")
struct PuzzleArchiveTests {
    /// The fixture installation's day zero: 2026-01-01T00:00:00Z.
    ///
    /// The archive counts reveals from the install, so the dates below are
    /// meaningful only as offsets from here.
    private let installedOn = Date(timeIntervalSince1970: 1_767_225_600)

    private func calendar(timeZone identifier: String = "UTC") throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: identifier))
        return calendar
    }

    private func date(
        _ year: Int, _ month: Int, _ day: Int,
        hour: Int = 12,
        in calendar: Calendar
    ) throws -> Date {
        try #require(calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour
        )))
    }

    private func bank(count: Int) throws -> PuzzleBank {
        try PuzzleBank(
            version: 1,
            puzzles: (0 ..< count).map { index in
                makePuzzle(id: String(format: "swift-sample-%03d", index))
            }
        )
    }

    @Test("An empty bank has no archive")
    func emptyBankIsEmpty() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)

        let entries = try PuzzleArchive.entries(
            bank: PuzzleBank(version: 1, puzzles: []),
            progress: UserProgress(installSeed: 1, installedOn: installedOn),
            through: today,
            calendar: calendar
        )

        #expect(entries.isEmpty)
    }

    @Test("Day zero reveals exactly one puzzle, unanswered")
    func firstDayHasOneEntry() throws {
        let calendar = try calendar()
        let today = try date(2026, 1, 1, in: calendar)

        let entries = try PuzzleArchive.entries(
            bank: bank(count: 12),
            progress: UserProgress(installSeed: 7, installedOn: installedOn),
            through: today,
            calendar: calendar
        )

        #expect(entries.count == 1)
        #expect(entries[0].record == nil)
        #expect(entries[0].revealedOnDayIndex == 0)
    }

    @Test("The archive agrees with the selector about which puzzles are due")
    func matchesTheSelector() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)
        let bank = try bank(count: 12)
        let progress = UserProgress(installSeed: 99, installedOn: installedOn)
        let selector = try #require(DailyPuzzleSelector(seed: 99, puzzleCount: bank.puzzles.count, epoch: installedOn))

        let entries = PuzzleArchive.entries(
            bank: bank, progress: progress, through: today, calendar: calendar
        )

        let expectedIndices = selector.revealedIndices(
            throughDayIndex: selector.dayIndex(for: today, calendar: calendar)
        )
        #expect(entries.map(\.puzzle) == expectedIndices.map { bank.puzzles[$0] })
    }

    @Test("Entries carry the user's answer when one exists")
    func carriesTheStoredRecord() throws {
        let calendar = try calendar()
        let today = try date(2026, 1, 1, in: calendar)
        let bank = try bank(count: 12)
        var progress = UserProgress(installSeed: 7, installedOn: installedOn)

        let selector = try #require(DailyPuzzleSelector(seed: 7, puzzleCount: bank.puzzles.count, epoch: installedOn))
        let todaysPuzzle = bank.puzzles[selector.index(for: today, calendar: calendar)]
        let stored = progress.recordAnswer(AnswerRecord(
            puzzleID: todaysPuzzle.id, selectedIndex: 0, isCorrect: true, answeredAt: today
        ))
        #expect(stored)

        let entries = PuzzleArchive.entries(
            bank: bank, progress: progress, through: today, calendar: calendar
        )

        #expect(entries.count == 1)
        #expect(entries[0].record?.isCorrect == true)
    }

    @Test("A puzzle that recurs after a full cycle is not listed twice")
    func doesNotDuplicateAfterWrapping() throws {
        let calendar = try calendar()
        let count = 5
        // Two full cycles plus a bit, so the schedule has wrapped more than once.
        let farInTheFuture = try date(2026, 1, 1 + count * 2 + 1, in: calendar)
        let bank = try bank(count: count)
        let progress = UserProgress(installSeed: 3, installedOn: installedOn)

        let entries = PuzzleArchive.entries(
            bank: bank, progress: progress, through: farInTheFuture, calendar: calendar
        )

        #expect(entries.count == count)
        #expect(Set(entries.map(\.id)).count == count)
    }

    @Test("Entries are ordered oldest reveal first")
    func ordersByRevealDay() throws {
        let calendar = try calendar()
        let today = try date(2026, 1, 6, in: calendar)
        let bank = try bank(count: 20)
        let progress = UserProgress(installSeed: 15, installedOn: installedOn)

        let entries = PuzzleArchive.entries(
            bank: bank, progress: progress, through: today, calendar: calendar
        )

        #expect(entries.map(\.revealedOnDayIndex) == Array(0 ..< entries.count))
    }
}
