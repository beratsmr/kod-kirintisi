import AppIntents
import WidgetKit

/// Answers today's puzzle straight from the widget, without opening the app.
///
/// Interactive widget buttons can only run an `AppIntent` — a closure will not
/// do — so each answer button in the medium widget is a `Button(intent:)`
/// wrapping one of these, carrying the tapped position.
struct AnswerPuzzleIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Answer today's puzzle"
    }

    /// Hidden from Shortcuts and Siri: on its own, "answer with choice 2" means
    /// nothing to a user. The discoverable entry point is ``ShowTodaysPuzzleIntent``.
    static var isDiscoverable: Bool {
        false
    }

    @Parameter(title: "Choice")
    var choiceIndex: Int

    init() {}

    init(choiceIndex: Int) {
        self.choiceIndex = choiceIndex
    }

    func perform() async throws -> some IntentResult {
        try await DailyPuzzleService.shared.answer(choiceIndex: choiceIndex)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.dailyPuzzle)
        return .result()
    }
}
