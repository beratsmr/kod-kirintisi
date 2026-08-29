import AppIntents

/// Opens the app on today's puzzle.
///
/// M5 needs this because a `ControlWidgetButton` must be given an intent to
/// run, and it did nothing beyond bringing the app forward until the Today
/// screen existed. Now it selects that tab too, so the intent lands somewhere
/// predictable even if the user last left the app on Statistics.
struct ShowTodaysPuzzleIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Show today's puzzle"
    }

    static var description: IntentDescription {
        IntentDescription("Opens Codestion on the puzzle of the day.")
    }

    static var openAppWhenRun: Bool {
        true
    }

    /// Resolved from the app process, never the widget's: ``openAppWhenRun``
    /// means the system launches the app and performs there, which is the only
    /// place ``KodKirintisiApp`` has registered a router.
    @Dependency private var router: AppRouter

    @MainActor
    func perform() async throws -> some IntentResult {
        router.showToday()
        return .result()
    }
}
