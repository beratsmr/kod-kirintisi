import CoreSpotlight
import Foundation
import KodKirintisiCore
import os
import UniformTypeIdentifiers

/// Publishes the puzzles the user has already seen to Spotlight.
///
/// Two rules shape this. It indexes only what ``PuzzleArchive`` calls revealed
/// — searching the device must not surface a puzzle before its day, which
/// would be the same spoiler the Archive screen is careful to avoid. And it
/// indexes only the title, the question and the labels: never
/// ``Puzzle/explanation``, never ``Puzzle/choices``, never which choice is
/// right. A Spotlight preview is not a place to give the answer away.
struct SpotlightIndexer: Sendable {
    static let shared = SpotlightIndexer()

    /// Groups every item this app owns, so a future version can drop or
    /// migrate the whole set in one call.
    private static let domainIdentifier = "com.beratsumer.kodkirintisi.archive"

    private static let logger = Logger(
        subsystem: "com.beratsumer.kodkirintisi",
        category: "spotlight"
    )

    private let service: DailyPuzzleService
    private let calendar: Calendar

    init(service: DailyPuzzleService = .shared, calendar: Calendar = .current) {
        self.service = service
        self.calendar = calendar
    }

    /// Brings the index up to date with the puzzles revealed by `date`.
    ///
    /// Worth calling whenever the app becomes active rather than only at
    /// launch: the set grows at local midnight, which routinely happens while
    /// the app sits in the background. Re-indexing an id already present just
    /// overwrites it, and the bank is append-only, so nothing has to be
    /// deleted first.
    ///
    /// Failures are logged and swallowed. Spotlight is a convenience — an app
    /// that cannot index should still open.
    func reindex(through date: Date = .now) async {
        do {
            let entries = try await service.archive(through: date, calendar: calendar)
            try await CSSearchableIndex.default().indexSearchableItems(entries.map(item(for:)))
            Self.logger.debug("Indexed \(entries.count, privacy: .public) revealed puzzles.")
        } catch {
            Self.logger.error("Spotlight indexing failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// The puzzle id carried by a tapped search result, or `nil` if the
    /// activity is something else. ``AppRouter/showArchivedPuzzle(id:)`` takes
    /// it from here.
    static func puzzleID(from userActivity: NSUserActivity) -> String? {
        guard userActivity.activityType == CSSearchableItemActionType else { return nil }
        return userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }

    private func item(for entry: PuzzleArchive.Entry) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = entry.puzzle.title
        attributes.contentDescription = entry.puzzle.question
        attributes.keywords = [
            String(localized: entry.puzzle.category.badgeName),
            String(localized: entry.puzzle.difficulty.displayName)
        ]

        return CSSearchableItem(
            uniqueIdentifier: entry.puzzle.id,
            domainIdentifier: Self.domainIdentifier,
            attributeSet: attributes
        )
    }
}
