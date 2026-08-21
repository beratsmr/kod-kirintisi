import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Streak calculation")
struct StreakCalculatorTests {
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

    private func days(
        _ dates: [Date],
        in calendar: Calendar
    ) -> Set<DateComponents> {
        Set(dates.map { StreakCalculator.day(for: $0, calendar: calendar) })
    }

    @Test("No answers means no streak")
    func emptyIsZero() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: [], today: today, calendar: calendar
        ) == 0)
    }

    @Test("Answering today correctly starts a streak of one")
    func todayCountsOnce() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days([today], in: calendar),
            today: today,
            calendar: calendar
        ) == 1)
    }

    @Test("Consecutive days accumulate")
    func consecutiveDaysAccumulate() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)
        let answered = try (0 ..< 5).map { try date(2026, 5, 10 - $0, in: calendar) }

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 5)
    }

    @Test("An unanswered today keeps yesterday's streak alive")
    func todayStillOpen() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)
        let answered = try [
            date(2026, 5, 9, in: calendar),
            date(2026, 5, 8, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 2)
    }

    @Test("A two-day gap resets the streak")
    func twoDayGapResets() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)
        let answered = try [
            date(2026, 5, 8, in: calendar),
            date(2026, 5, 7, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 0)
    }

    @Test("Only the run ending now counts, not an older longer one")
    func ignoresOlderRuns() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)
        let answered = try [
            date(2026, 5, 10, in: calendar),
            date(2026, 5, 9, in: calendar),
            // gap
            date(2026, 5, 5, in: calendar),
            date(2026, 5, 4, in: calendar),
            date(2026, 5, 3, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 2)
    }

    @Test("A wrong answer does not extend the streak")
    func wrongAnswersAreExcluded() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, in: calendar)
        let records = try [
            AnswerRecord(
                puzzleID: "a", selectedIndex: 0, isCorrect: true,
                answeredAt: date(2026, 5, 10, in: calendar)
            ),
            AnswerRecord(
                puzzleID: "b", selectedIndex: 1, isCorrect: false,
                answeredAt: date(2026, 5, 9, in: calendar)
            ),
            AnswerRecord(
                puzzleID: "c", selectedIndex: 0, isCorrect: true,
                answeredAt: date(2026, 5, 8, in: calendar)
            )
        ]

        let correct = StreakCalculator.correctDays(from: records, calendar: calendar)

        // The wrong answer on the 9th breaks the run, leaving only the 10th.
        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: correct, today: today, calendar: calendar
        ) == 1)
    }

    @Test("The streak survives a spring-forward day")
    func survivesSpringForward() throws {
        let newYork = try calendar(timeZone: "America/New_York")
        let today = try date(2026, 3, 9, in: newYork)
        let answered = try [
            date(2026, 3, 9, in: newYork),
            date(2026, 3, 8, in: newYork), // the 23-hour day
            date(2026, 3, 7, in: newYork)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: newYork),
            today: today,
            calendar: newYork
        ) == 3)
    }

    @Test("The streak survives a fall-back day")
    func survivesFallBack() throws {
        let newYork = try calendar(timeZone: "America/New_York")
        let today = try date(2026, 11, 2, in: newYork)
        let answered = try [
            date(2026, 11, 2, in: newYork),
            date(2026, 11, 1, in: newYork), // the 25-hour day
            date(2026, 10, 31, in: newYork)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: newYork),
            today: today,
            calendar: newYork
        ) == 3)
    }

    @Test("The streak survives new year's eve")
    func survivesYearBoundary() throws {
        let calendar = try calendar()
        let today = try date(2027, 1, 1, in: calendar)
        let answered = try [
            date(2027, 1, 1, in: calendar),
            date(2026, 12, 31, in: calendar),
            date(2026, 12, 30, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 3)
    }

    @Test("The streak survives a leap day")
    func survivesLeapDay() throws {
        let calendar = try calendar()
        let today = try date(2028, 3, 1, in: calendar)
        let answered = try [
            date(2028, 3, 1, in: calendar),
            date(2028, 2, 29, in: calendar),
            date(2028, 2, 28, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 3)
    }

    @Test("Answering at either edge of a day counts as that day")
    func timeOfDayDoesNotMatter() throws {
        let calendar = try calendar()
        let today = try date(2026, 5, 10, hour: 23, in: calendar)
        let answered = try [
            date(2026, 5, 10, hour: 0, in: calendar),
            date(2026, 5, 9, hour: 23, in: calendar)
        ]

        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(answered, in: calendar),
            today: today,
            calendar: calendar
        ) == 2)
    }

    @Test("The longest streak looks at the whole history")
    func longestStreakScansEverything() throws {
        let calendar = try calendar()
        let answered = try [
            date(2026, 5, 10, in: calendar),
            date(2026, 5, 9, in: calendar),
            // gap
            date(2026, 5, 5, in: calendar),
            date(2026, 5, 4, in: calendar),
            date(2026, 5, 3, in: calendar),
            date(2026, 5, 2, in: calendar)
        ]

        #expect(StreakCalculator.longestStreak(
            correctlyAnsweredDays: days(answered, in: calendar), calendar: calendar
        ) == 4)
    }

    @Test("The longest streak of an empty history is zero")
    func longestStreakOfNothing() throws {
        let calendar = try calendar()

        #expect(StreakCalculator.longestStreak(
            correctlyAnsweredDays: [], calendar: calendar
        ) == 0)
    }

    @Test("Only correct answers reach the day set")
    func correctDaysFiltersWrongAnswers() throws {
        let calendar = try calendar()
        let records = try [
            AnswerRecord(
                puzzleID: "a", selectedIndex: 0, isCorrect: true,
                answeredAt: date(2026, 5, 10, in: calendar)
            ),
            AnswerRecord(
                puzzleID: "b", selectedIndex: 1, isCorrect: false,
                answeredAt: date(2026, 5, 9, in: calendar)
            )
        ]

        let correct = StreakCalculator.correctDays(from: records, calendar: calendar)

        #expect(correct.count == 1)
        #expect(try correct.contains(StreakCalculator.day(
            for: date(2026, 5, 10, in: calendar), calendar: calendar
        )))
    }
}
