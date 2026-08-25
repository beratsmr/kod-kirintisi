import Foundation
import KodKirintisiCore
import WidgetKit

/// One point on the widget's timeline.
struct DailyPuzzleEntry: TimelineEntry {
    /// What the widget has to show at ``date``.
    enum State: Equatable {
        /// A puzzle is ready.
        case ready(DailyDigest)
        /// Progress could not be read — a missing App Group, or unreadable
        /// storage. The widget says so instead of pretending the day is empty,
        /// because an empty-looking widget reads as "no puzzle today".
        case unavailable
    }

    let date: Date
    let state: State

    /// A stand-in shown while the real entry loads, and in the widget gallery.
    ///
    /// The sample is hand-written rather than drawn from the bank so that the
    /// gallery never spoils a puzzle the user has not reached yet.
    static func placeholder(at date: Date = .now) -> DailyPuzzleEntry {
        DailyPuzzleEntry(
            date: date,
            state: .ready(DailyDigest(
                puzzle: Puzzle(
                    id: "sample",
                    category: .swiftLanguage,
                    difficulty: .basic,
                    title: "Value or reference?",
                    question: "What does this print?",
                    codeSnippet: "var a = [1, 2]\nvar b = a\nb.append(3)\nprint(a.count)",
                    choices: ["2", "3"],
                    correctIndex: 0,
                    explanation: "Arrays are value types, so b is a copy.",
                    whyOthersWrong: ["", "b is a copy, so a is untouched."],
                    tags: ["value-types"]
                ),
                record: nil,
                currentStreak: 3,
                dayIndex: 0
            ))
        )
    }
}
