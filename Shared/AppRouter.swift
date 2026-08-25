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

    /// Brings today's puzzle forward. The Archive stack is left as it was, so
    /// returning to that tab by hand lands where the user left off.
    func showToday() {
        selectedScreen = .today
    }

    /// Opens one revealed puzzle read-only, replacing whatever the Archive
    /// stack held. Replacing rather than appending keeps repeated entries —
    /// three Spotlight taps in a row — from building a stack of detail views.
    func showArchivedPuzzle(id: String) {
        selectedScreen = .archive
        archivePath = [id]
    }
}
