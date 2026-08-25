import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Daily digest")
struct DailyDigestTests {
    /// The fixture installation's day zero: 2026-01-01T00:00:00Z.
    ///
    /// The schedule counts from the install, so the dates below are meaningful
    /// only as offsets from here.
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

    @Test("The digest names the puzzle the selector picked")
    func agreesWithSelector() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)
        let bank = try bank(count: 12)
        let progress = UserProgress(installSeed: 99, installedOn: installedOn)

        let digest = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: today, calendar: calendar
        ))
        let selector = try #require(DailyPuzzleSelector(seed: 99, puzzleCount: bank.puzzles.count, epoch: installedOn))

        #expect(digest.puzzle == bank.puzzles[selector.index(for: today, calendar: calendar)])
        #expect(digest.dayIndex == selector.dayIndex(for: today, calendar: calendar))
    }

    @Test("An empty bank yields no digest")
    func emptyBankIsNil() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)

        #expect(try DailyDigest.make(
            bank: PuzzleBank(version: 1, puzzles: []),
            progress: UserProgress(installSeed: 1, installedOn: installedOn),
            date: today,
            calendar: calendar
        ) == nil)
    }

    @Test("An untouched day reads as unanswered")
    func unansweredDay() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)

        let digest = try #require(try DailyDigest.make(
            bank: bank(count: 12),
            progress: UserProgress(installSeed: 7, installedOn: installedOn),
            date: today,
            calendar: calendar
        ))

        #expect(digest.record == nil)
        #expect(digest.isAnswered == false)
        #expect(digest.isCorrect == false)
        #expect(digest.currentStreak == 0)
    }

    @Test("The digest surfaces the record belonging to today's puzzle")
    func picksUpTodaysRecord() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)
        let bank = try bank(count: 12)
        var progress = UserProgress(installSeed: 7, installedOn: installedOn)

        let selector = try #require(DailyPuzzleSelector(seed: 7, puzzleCount: bank.puzzles.count, epoch: installedOn))
        let todaysPuzzle = bank.puzzles[selector.index(for: today, calendar: calendar)]

        let stored = progress.recordAnswer(AnswerRecord(
            puzzleID: todaysPuzzle.id, selectedIndex: 0, isCorrect: true, answeredAt: today
        ))
        #expect(stored)

        let digest = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: today, calendar: calendar
        ))

        #expect(digest.isAnswered)
        #expect(digest.isCorrect)
        #expect(digest.record?.puzzleID == todaysPuzzle.id)
        #expect(digest.currentStreak == 1)
    }

    @Test("A record for another day does not mark today answered")
    func otherDaysRecordIsIgnored() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)
        let yesterday = try date(2026, 3, 3, in: calendar)
        let bank = try bank(count: 12)
        var progress = UserProgress(installSeed: 7, installedOn: installedOn)

        let selector = try #require(DailyPuzzleSelector(seed: 7, puzzleCount: bank.puzzles.count, epoch: installedOn))
        let yesterdaysPuzzle = bank.puzzles[selector.index(for: yesterday, calendar: calendar)]

        let stored = progress.recordAnswer(AnswerRecord(
            puzzleID: yesterdaysPuzzle.id, selectedIndex: 0, isCorrect: true, answeredAt: yesterday
        ))
        #expect(stored)

        let digest = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: today, calendar: calendar
        ))

        #expect(digest.isAnswered == false)
        // Yesterday was correct and today is still open, so the run survives.
        #expect(digest.currentStreak == 1)
    }

    @Test("A wrong answer today shows as answered but breaks the streak")
    func wrongAnswerBreaksStreak() throws {
        let calendar = try calendar()
        let today = try date(2026, 3, 4, in: calendar)
        let yesterday = try date(2026, 3, 3, in: calendar)
        let bank = try bank(count: 12)
        var progress = UserProgress(installSeed: 7, installedOn: installedOn)

        let selector = try #require(DailyPuzzleSelector(seed: 7, puzzleCount: bank.puzzles.count, epoch: installedOn))
        let yesterdaysPuzzle = bank.puzzles[selector.index(for: yesterday, calendar: calendar)]
        let todaysPuzzle = bank.puzzles[selector.index(for: today, calendar: calendar)]

        let storedYesterday = progress.recordAnswer(AnswerRecord(
            puzzleID: yesterdaysPuzzle.id, selectedIndex: 0, isCorrect: true, answeredAt: yesterday
        ))
        let storedToday = progress.recordAnswer(AnswerRecord(
            puzzleID: todaysPuzzle.id, selectedIndex: 1, isCorrect: false, answeredAt: today
        ))
        #expect(storedYesterday)
        #expect(storedToday)

        let digest = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: today, calendar: calendar
        ))

        #expect(digest.isAnswered)
        #expect(digest.isCorrect == false)
        // SPEC §5.2: the wrong answer breaks the run now, not at midnight —
        // yesterday's correct day does not keep it alive.
        #expect(digest.currentStreak == 0)
    }

    @Test("The digest changes at the user's local midnight")
    func rollsOverAtLocalMidnight() throws {
        let calendar = try calendar(timeZone: "Europe/Istanbul")
        let bank = try bank(count: 30)
        let progress = UserProgress(installSeed: 4242, installedOn: installedOn)

        let lateTonight = try date(2026, 3, 4, hour: 23, in: calendar)
        let earlyTomorrow = try date(2026, 3, 5, hour: 0, in: calendar)

        let tonight = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: lateTonight, calendar: calendar
        ))
        let tomorrow = try #require(DailyDigest.make(
            bank: bank, progress: progress, date: earlyTomorrow, calendar: calendar
        ))

        #expect(tonight.dayIndex + 1 == tomorrow.dayIndex)
        #expect(tonight.puzzle != tomorrow.puzzle)
    }
}
