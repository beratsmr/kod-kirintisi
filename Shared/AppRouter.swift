import Observation

/// Where the app should be pointing after something outside it — a Siri
/// phrase, a widget tap, a Spotlight result — asks for a particular screen.
///
/// This lives in `Shared/` rather than `App/` because `Shared/Intents/` is
/// compiled into the widget extension as well, and those intents name this
/// type. The widget process never touches an instance: the intents that route
/// all set `openAppWhenRun`, so their `perform()` runs in the app.
@MainActor
@Observable
final class AppRouter {
    /// One case per tab in ``KodKirintisiApp``. Named `Screen` rather than
    /// `Tab` so it cannot be confused with SwiftUI's `Tab` at the call site.
    enum Screen: Hashable {
        case today
        case archive
        case statistics
        case settings
    }

    var selectedScreen = Screen.today

    /// Puzzle ids stacked on top of the Archive list. Ids rather than
    /// ``PuzzleArchive/Entry`` values because a navigation path element has to
    /// be `Hashable`, and an entry is not — ``ArchiveView`` looks the id back
    /// up in the entries it has already loaded.
    var archivePath: [String] = []

    /// Whether the Today screen should show the answer for a day that has not
    /// been answered. Deliberately not persisted anywhere: revealing is a peek,
    /// it records nothing, and it counts for nothing in the streak. ``TodayView``
    /// clears it as soon as the user leaves the tab.
    var revealsTodaysAnswer = false

    /// Bumped whenever stored progress may have changed underneath the screens.
    ///
    /// Every tab reads the same progress file, but a `.task` runs once and a
    /// `TabView` keeps visited tabs alive — so answering on Today left Archive
    /// and Statistics showing what they loaded on first visit, and an answer
    /// given in the widget reached none of them. Screens key their loading task
    /// on this value instead, and a change re-runs the load.
    ///
    /// A counter rather than a flag: what SwiftUI acts on is the value being
    /// *different* from the last one it saw, not what the value is.
    private(set) var progressRevision = 0

    /// Tells every screen to reload. Call after anything that writes progress,
    /// and after returning to the foreground, where the widget may have written
    /// it for us.
    func progressDidChange() {
        progressRevision += 1
    }

    /// Brings today's puzzle forward. The Archive stack is left as it was, so
    /// returning to that tab by hand lands where the user left off.
    func showToday() {
        selectedScreen = .today
    }

    /// Opens today's puzzle with the answer already showing.
    func revealTodaysAnswer() {
        selectedScreen = .today
        revealsTodaysAnswer = true
    }

    /// Opens one revealed puzzle read-only, replacing whatever the Archive
    /// stack held. Replacing rather than appending keeps repeated entries —
    /// three Spotlight taps in a row — from building a stack of detail views.
    func showArchivedPuzzle(id: String) {
        selectedScreen = .archive
        archivePath = [id]
    }
}
