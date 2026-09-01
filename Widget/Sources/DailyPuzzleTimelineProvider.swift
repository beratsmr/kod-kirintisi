import Foundation
import KodKirintisiCore
import os
import WidgetKit

/// Supplies the widget with today's puzzle and tomorrow's.
///
/// Exactly two entries are produced — now and the next local midnight — as
/// `docs/ARCHITECTURE.md` §5 sets out. WidgetKit rations refreshes, and a
/// puzzle only changes once a day, so anything denser would spend the budget
/// without showing the user anything new.
struct DailyPuzzleTimelineProvider: TimelineProvider {
    private static let logger = Logger(
        subsystem: "com.beratsumer.kodkirintisi.widget",
        category: "timeline"
    )

    private let service: DailyPuzzleService
    private let calendar: Calendar

    init(service: DailyPuzzleService = .shared, calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    func placeholder(in _: Context) -> DailyPuzzleEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (DailyPuzzleEntry) -> Void) {
        // The gallery preview must not depend on the container being readable.
        guard !context.isPreview else {
            completion(.placeholder())
            return
        }

        Task {
            await refreshProgress()
            await completion(entry(for: .now))
        }
    }

    func getTimeline(in _: Context, completion: @escaping @Sendable (Timeline<DailyPuzzleEntry>) -> Void) {
        Task {
            await refreshProgress()

            let now = Date.now
            let midnight = nextMidnight(after: now)

            var entries = await [entry(for: now)]
            if let midnight {
                await entries.append(entry(for: midnight))
            }

            // Refreshing *at* midnight rather than after the last entry means a
            // device awake at the rollover redraws immediately instead of
            // waiting for WidgetKit to get around to it.
            completion(Timeline(
                entries: entries,
                policy: midnight.map { .after($0) } ?? .atEnd
            ))
        }
    }

    /// Picks up whatever the app has written before any entry is built.
    ///
    /// WidgetKit reuses this extension process between reloads, so the service's
    /// cached progress outlives the reload that populated it — an answer given
    /// in the app would otherwise never reach a warm widget, however many times
    /// `reloadTimelines` was called. Once per timeline rather than once per
    /// entry: both entries of a timeline describe the same stored progress.
    ///
    /// A failure is logged and swallowed. The entries built next report their
    /// own trouble, and a stale card beats no card.
    private func refreshProgress() async {
        do {
            try await service.refresh()
        } catch {
            Self.logger.error("Could not refresh progress: \(error, privacy: .public)")
        }
    }

    private func entry(for date: Date) async -> DailyPuzzleEntry {
        do {
            let digest = try await service.digest(for: date, calendar: calendar)
            return DailyPuzzleEntry(date: date, state: .ready(digest))
        } catch {
            Self.logger.error("Could not build the digest: \(error, privacy: .public)")
            return DailyPuzzleEntry(date: date, state: .unavailable)
        }
    }

    /// The start of the next day in the user's calendar.
    ///
    /// `nextDate(after:matching:)` is used instead of adding 24 hours so that
    /// the entry lands on the real local midnight across daylight saving shifts,
    /// where a day is 23 or 25 hours long.
    private func nextMidnight(after date: Date) -> Date? {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        )
    }
}
