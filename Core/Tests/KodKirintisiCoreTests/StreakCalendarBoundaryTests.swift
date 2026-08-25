import Foundation
import Testing
@testable import KodKirintisiCore

/// The days where "add one day" is not "add 86400 seconds".
///
/// ``StreakCalculator`` walks backwards a day at a time, so every irregular day
/// in the calendar is a chance for it to skip or repeat one. These live apart
/// from ``StreakCalculatorTests`` because they exercise the calendar rather than
/// the streak rules.
@Suite("Streak calculation at calendar boundaries")
struct StreakCalendarBoundaryTests {
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

    @Test("A wrong answer just before midnight still zeroes the streak")
    func lateWrongAnswerBreaksTheSameDay() throws {
        let istanbul = try calendar(timeZone: "Europe/Istanbul")
        let today = try date(2026, 5, 10, hour: 23, in: istanbul)
        let earlier = try [
            date(2026, 5, 9, in: istanbul),
            date(2026, 5, 8, in: istanbul)
        ]

        // The run is lost for the last hour of the day too, not just from the
        // moment of the answer onwards — the day key is what matters.
        #expect(StreakCalculator.currentStreak(
            correctlyAnsweredDays: days(earlier, in: istanbul),
            wronglyAnsweredDays: days([today], in: istanbul),
            today: today,
            calendar: istanbul
        ) == 0)
    }
}
