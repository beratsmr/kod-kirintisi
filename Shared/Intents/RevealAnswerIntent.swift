import AppIntents

/// Gives up on today's puzzle and opens the app on the explanation.
///
/// This records nothing. Revealing is not answering: the day stays unanswered
/// in ``UserProgress``, the streak neither grows nor breaks, and the accuracy
/// figures never see it. That is also why the reveal lives in ``AppRouter``
/// and not in Core — there is no fact here worth persisting.
struct RevealAnswerIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Reveal today's answer"
    }

    static var description: IntentDescription {
        IntentDescription("Opens Codestion on today's answer and explanation, without recording an answer.")
    }

    static var openAppWhenRun: Bool {
        true
    }

    /// Resolved from the app process — see ``ShowTodaysPuzzleIntent``.
    @Dependency private var router: AppRouter

    @MainActor
    func perform() async throws -> some IntentResult {
        router.revealTodaysAnswer()
        return .result()
    }
}
