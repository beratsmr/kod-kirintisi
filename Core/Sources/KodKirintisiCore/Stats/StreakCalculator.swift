import Foundation

/// Counts consecutive days the user got the puzzle right.
///
/// **A wrong answer breaks the streak the moment it is given**, per
/// `docs/SPEC.md` §5.2. That is stricter than it first looks: a day the user
/// simply hasn't reached yet is *not* the same as a day they got wrong. An
/// unanswered today leaves the run intact — there is still time — but a wrong
/// answer today takes it to zero immediately. Distinguishing the two is why
/// these functions need both sets of days rather than just the correct ones.
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

    /// Days answered wrongly, as day keys, from raw answer records.
    ///
    /// The complement of ``correctDays(from:calendar:)`` over the same records;
    /// the two sets are disjoint because a day holds at most one answer.
    public static func wrongDays(
        from records: some Sequence<AnswerRecord>,
        calendar: Calendar
    ) -> Set<DateComponents> {
        Set(records.lazy.filter { !$0.isCorrect }.map { day(for: $0.answeredAt, calendar: calendar) })
    }

    /// Length of the run of correct days ending today, or yesterday.
    ///
    /// Today counts once it has been answered correctly, but an unanswered
    /// today does not end the run — the user still has the rest of the day.
    /// Answering today *wrongly* ends it at once and returns zero. Two
    /// consecutive missed days also end it.
    ///
    /// - Parameters:
    ///   - correctlyAnsweredDays: Day keys built with ``day(for:calendar:)``.
    ///     Days answered wrongly must not appear here.
    ///   - wronglyAnsweredDays: Day keys for answers that were wrong. Only
    ///     today's membership changes the result — earlier wrong days already
    ///     stop the walk by their absence from `correctlyAnsweredDays` — but
    ///     passing the whole set keeps the call honest. Defaults to empty for
    ///     callers that only ever record correct answers.
    public static func currentStreak(
        correctlyAnsweredDays: Set<DateComponents>,
        wronglyAnsweredDays: Set<DateComponents> = [],
        today: Date,
        calendar: Calendar
    ) -> Int {
        guard !correctlyAnsweredDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: today)
        if !correctlyAnsweredDays.contains(day(for: cursor, calendar: calendar)) {
            // Today was answered and it was wrong: the run is over now, not at
            // midnight. Without this the grace below would quietly carry
            // yesterday's streak through a day the user has already lost.
            guard !wronglyAnsweredDays.contains(day(for: cursor, calendar: calendar)) else {
                return 0
            }
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
