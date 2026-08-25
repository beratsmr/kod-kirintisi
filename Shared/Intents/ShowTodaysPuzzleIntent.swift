import AppIntents

/// Opens the app on today's puzzle.
///
/// M5 needs this because a `ControlWidgetButton` must be given an intent to
/// run. M7 builds on it for the Siri phrase and the shortcut; until the Today
/// screen exists in M6 it does nothing beyond bringing the app forward.
struct ShowTodaysPuzzleIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Show today's puzzle"
    }

    static var description: IntentDescription {
        IntentDescription("Opens Kod Kırıntısı on the puzzle of the day.")
    }

    static var openAppWhenRun: Bool {
        true
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}
