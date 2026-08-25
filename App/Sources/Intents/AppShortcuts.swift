import AppIntents

/// The two things worth asking Siri for, and what the Shortcuts app offers
/// without the user having to build anything.
///
/// This lives in the app target rather than `Shared/`, unlike the intents it
/// names: a provider is registered per bundle, and letting the widget
/// extension declare a second one would offer the same shortcuts twice.
///
/// Every phrase has to contain `\(.applicationName)` — App Intents rejects a
/// phrase without it at build time, since a bare "show today's puzzle" would
/// collide with every other app on the device.
struct KodKirintisiShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowTodaysPuzzleIntent(),
            phrases: [
                "Show today's puzzle in \(.applicationName)",
                "Open today's \(.applicationName)",
                "What's today's \(.applicationName) puzzle"
            ],
            shortTitle: "Today's Puzzle",
            systemImageName: "questionmark.circle"
        )
        AppShortcut(
            intent: RevealAnswerIntent(),
            phrases: [
                "Reveal today's \(.applicationName) answer",
                "Show me the \(.applicationName) answer"
            ],
            shortTitle: "Reveal Answer",
            systemImageName: "lightbulb"
        )
    }
}
