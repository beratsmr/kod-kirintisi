import Foundation

/// Counts consecutive days the user got the puzzle right.
///
/// **A wrong answer breaks the streak**: only days answered correctly count.
/// Answering wrongly is therefore the same as not answering at all, as far as
/// the streak is concerned. See `docs/SPEC.md` §5.2.
public enum StreakCalculator {
    /// The day key for a date, in the form the streak functions expect.
    ///
    /// Callers must build their day set with this function: a `DateComponents`
    /// carrying different fields would never compare equal to these.
    public static func day(for date: Date, calendar: Calendar) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    /// Days answered correctly, as day keys, from raw answer records.
    public static func correctDays(
        from records: some Sequence<AnswerRecord>,
        calendar: Calendar
    ) -> Set<DateComponents> {
        Set(records.lazy.filter(\.isCorrect).map { day(for: $0.answeredAt, calendar: calendar) })
    }

    /// Length of the run of correct days ending today, or yesterday.
    ///
    /// Today counts once it has been answered correctly, but an unanswered
    /// today does not end the run — the user still has the rest of the day.
    /// Two consecutive missed days end it.
    ///
    /// - Parameter correctlyAnsweredDays: Day keys built with ``day(for:calendar:)``.
    ///   Days answered *wrongly* must not appear here.
    public static func currentStreak(
        correctlyAnsweredDays: Set<DateComponents>,
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard !correctlyAnsweredDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: today)
        if !correctlyAnsweredDays.contains(day(for: cursor, calendar: calendar)) {
            // Today is still open; start counting from yesterday instead.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                return 0
            }
            cursor = yesterday
        }

        var streak = 0
        // Each iteration consumes one day from the set, so it cannot run away
        // even if a calendar arithmetic quirk stopped moving the cursor.
        while streak <= correctlyAnsweredDays.count {
            guard correctlyAnsweredDays.contains(day(for: cursor, calendar: calendar)) else {
                break
            }
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = previous
        }
        return streak
    }

    /// The longest run of correct days ever achieved.
    public static func longestStreak(
        correctlyAnsweredDays: Set<DateComponents>,
        calendar: Calendar
    ) -> Int {
        let dates = correctlyAnsweredDays
            .compactMap { calendar.date(from: $0) }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        guard let first = dates.first else { return 0 }

        var longest = 1
        var run = 1
        var previous = first
        for date in dates.dropFirst() {
            let gap = calendar.dateComponents([.day], from: previous, to: date).day ?? 0
            run = gap == 1 ? run + 1 : 1
            longest = max(longest, run)
            previous = date
        }
        return longest
    }
}
