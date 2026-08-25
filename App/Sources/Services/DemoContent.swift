import Foundation
import KodKirintisiCore
import os

/// Fills the shared container with a plausible answer history, for screenshots.
///
/// A clean install is honest but useless as a store listing: the Archive holds
/// one row, every statistic reads zero, and the charts are blank. Rather than
/// mocking the views — which would mean shipping a second, untested rendering
/// path and screenshots that no longer prove the app works — this writes real
/// progress to the real container and lets the real screens read it.
///
/// Two things keep it out of users' hands. The body compiles only in `DEBUG`,
/// so nothing here exists in an App Store build, and even in a debug build it
/// runs only when ``launchArgument`` is passed, which requires launching the
/// app from Xcode or `simctl`. It is invoked by `KodKirintisiApp.init`, before
/// any screen has read progress.
///
/// It is destructive by design: it overwrites whatever is in the container so
/// that a rerun produces byte-identical screenshots.
enum DemoContent {
    /// Pass this at launch to install the history. See `scripts/make-screenshots.sh`.
    static let launchArgument = "-KodKirintisiDemoContent"

    static func installIfRequested(now: Date = .now, calendar: Calendar = .current) {
        #if DEBUG
            guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }
            do {
                try install(now: now, calendar: calendar)
            } catch {
                // Fail loudly in the log but let the app start: a screenshot of the
                // empty state is a better failure than a crash nobody can diagnose.
                logger.error("Could not install demo content: \(error.localizedDescription, privacy: .public)")
            }
        #endif
    }

    #if DEBUG

        private static let logger = Logger(
            subsystem: "com.beratsumer.kodkirintisi", category: "DemoContent"
        )

        /// Fixed so that every run of the screenshot script produces the same
        /// puzzles in the same order — otherwise the store listing would change
        /// under us on every regeneration and diffs would be unreadable.
        private static let seed: UInt64 = 0xC0DE_C0DE_C0DE_C0DE

        /// How many days of history to fabricate. The last one is *today*, and it
        /// is deliberately left unanswered so the Today screen shows the question
        /// with its buttons rather than an explanation.
        private static let dayCount = 42

        /// Day offsets answered wrongly. Chosen to leave a current streak of 7 and
        /// a longest of 13, which reads as a real user rather than a perfect one,
        /// and gives the statistics screen two different numbers to show.
        private static let wrongDayOffsets: Set<Int> = [2, 7, 21, 33]

        /// The time of day the fictional user answers at. Any fixed hour will do;
        /// mid-morning keeps every record inside its own day in any time zone the
        /// screenshots might be taken in.
        private static let answerHour = 9
        private static let answerMinute = 12

        private static func install(now: Date, calendar: Calendar) throws {
            guard let url = AppGroup.progressURL else {
                throw Failure.containerUnavailable
            }
            let bank = try PuzzleBank.shared()

            // Day zero is far enough back that today is the last of `dayCount`.
            guard let installedOn = calendar.date(
                byAdding: .day, value: -(dayCount - 1), to: calendar.startOfDay(for: now)
            ) else {
                throw Failure.couldNotBuildCalendarDates
            }

            guard let selector = DailyPuzzleSelector(
                seed: seed, puzzleCount: bank.puzzles.count, epoch: installedOn
            ) else {
                throw Failure.emptyBank
            }

            var records: [String: AnswerRecord] = [:]
            // `dayCount - 1` is today, which stays unanswered.
            for offset in 0 ..< (dayCount - 1) {
                guard let day = calendar.date(byAdding: .day, value: offset, to: installedOn),
                      let answeredAt = calendar.date(
                          bySettingHour: answerHour, minute: answerMinute, second: 0, of: day
                      )
                else {
                    throw Failure.couldNotBuildCalendarDates
                }

                let puzzle = bank.puzzles[selector.index(for: day, calendar: calendar)]
                let isCorrect = !wrongDayOffsets.contains(offset)
                records[puzzle.id] = AnswerRecord(
                    puzzleID: puzzle.id,
                    selectedIndex: isCorrect ? puzzle.correctIndex : wrongChoice(for: puzzle),
                    isCorrect: isCorrect,
                    answeredAt: answeredAt
                )
            }

            try FileProgressStore(url: url).save(UserProgress(
                installSeed: seed, installedOn: installedOn, records: records
            ))
            logger.info("Installed \(records.count, privacy: .public) demo answers.")
        }

        /// Any choice that is not the right one. Every puzzle has at least two
        /// choices, so the first index differing from the answer always exists.
        private static func wrongChoice(for puzzle: Puzzle) -> Int {
            puzzle.choices.indices.first { $0 != puzzle.correctIndex } ?? puzzle.correctIndex
        }

        private enum Failure: Error {
            case containerUnavailable
            case emptyBank
            case couldNotBuildCalendarDates
        }

    #endif
}
