import XCTest

/// Captures the App Store screenshots by driving the real app.
///
/// These are not assertions about behaviour — `KodKirintisiTests` and the Core
/// suite do that. The point here is that the store listing is generated from
/// the shipping screens rather than drawn by hand, so it cannot quietly drift
/// away from what the app actually looks like. The waits are still real
/// assertions though: if a screen fails to load, the run fails instead of
/// producing a screenshot of a spinner.
///
/// Run through `scripts/make-screenshots.sh`, which extracts the attachments
/// into `docs/screenshots/`.
///
/// The app is launched inside the test rather than in `setUp`: `XCUIApplication`
/// is main-actor isolated, and `XCTestCase.setUp` is not, so keeping the whole
/// interaction in one `@MainActor` method is what makes this build without
/// concurrency warnings.
final class ScreenshotTests: XCTestCase {
    /// The App Store set.
    @MainActor
    func testCaptureScreenshots() {
        captureAll(in: .english)
    }

    /// A translation review pass rather than part of the listing, which is
    /// English only.
    ///
    /// A second test method rather than a parameter because there is no
    /// dependable way to hand a UI test a value from the command line: the test
    /// runs in the simulator, so the environment `xcodebuild` was invoked with
    /// is not its environment. `-only-testing:` selects one of the two, which is
    /// also what keeps a single set of attachments in the result bundle.
    @MainActor
    func testCaptureTurkishScreenshots() {
        captureAll(in: .turkish)
    }

    @MainActor
    private func captureAll(in language: Language) {
        // One failed screen should not leave the remaining ones uncaptured.
        continueAfterFailure = true

        let app = XCUIApplication()
        app.launchArguments += [
            // Fabricate a believable answer history — see `DemoContent`.
            "-KodKirintisiDemoContent",
            "-AppleLanguages", "(\(language.code))",
            "-AppleLocale", language.locale
        ]
        app.launch()
        defer { app.terminate() }

        capture(app, screen: language.today, named: "01-today")
        capture(app, screen: language.archive, named: "02-archive")
        captureArchiveDetail(app, named: "03-explanation")
        capture(app, screen: language.statistics, named: "04-statistics")
        capture(app, screen: language.settings, named: "05-settings")
    }

    // MARK: - Language

    /// The language the capture runs in, and the labels to expect in it.
    ///
    /// The language is pinned rather than inherited from the simulator: a
    /// screenshot set that quietly follows whatever language the device happens
    /// to be in is not reproducible. Note that `-testLanguage` cannot do this —
    /// XCTest injects it into `launchArguments`, the launch below appends its
    /// own `-AppleLanguages` afterwards, and the last value in the argument
    /// domain wins, so the flag is swallowed without a word.
    ///
    /// Each screen's navigation title is also its tab label, so one string per
    /// screen covers both. Spelling the expected labels out is what makes a
    /// missing translation fail the run instead of producing a screenshot of
    /// the wrong language.
    private struct Language {
        let code: String
        let locale: String
        let today: String
        let archive: String
        let statistics: String
        let settings: String

        static let english = Language(
            code: "en", locale: "en_US",
            today: "Today", archive: "Archive", statistics: "Statistics", settings: "Settings"
        )

        static let turkish = Language(
            code: "tr", locale: "tr_TR",
            today: "Bugün", archive: "Arşiv", statistics: "İstatistik", settings: "Ayarlar"
        )
    }

    // MARK: - Steps

    /// Selects a screen's tab, waits for it to finish loading, and files the
    /// screenshot.
    @MainActor
    private func capture(_ app: XCUIApplication, screen: String, named name: String) {
        let button = app.tabBars.buttons[screen]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "no \(screen) tab")
        button.tap()

        waitUntilLoaded(app, screen: screen)
        attach(name: name)
    }

    /// Opens an answered archive row, the only screen that shows a full
    /// explanation — the thing the app is actually selling.
    ///
    /// The second row, not the first: the archive is newest-first and today's
    /// puzzle is deliberately left unanswered, so row zero would capture the
    /// question again rather than an explanation.
    @MainActor
    private func captureArchiveDetail(_ app: XCUIApplication, named name: String) {
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10), "the archive is empty")
        let row = app.cells.element(boundBy: 1)
        XCTAssertTrue(row.waitForExistence(timeout: 10), "the archive holds only today")
        row.tap()

        // The detail pushes its own navigation bar with a back button; waiting
        // for that is what proves the push happened rather than a failed tap.
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 10), "the detail never appeared")
        waitUntilLoaded(app, screen: nil)

        // The explanation renders only once the puzzle has been answered, so
        // waiting for it is what stops this silently capturing an open
        // question instead. The literal matches
        // `PuzzleCardView.explanationIdentifier`; a UI test bundle shares no
        // code with the app, so it cannot reference the constant directly.
        XCTAssertTrue(
            app.staticTexts["puzzle.explanation"].waitForExistence(timeout: 10),
            "this row has no explanation — did an unanswered puzzle get picked?"
        )
        attach(name: name)

        backButton.tap()
    }

    // MARK: - Helpers

    /// Waits for a screen to be both present and done loading.
    ///
    /// Every screen loads its data in a `.task`, so tapping a tab and shooting
    /// immediately reliably captures a spinner. Waiting for the activity
    /// indicator to go away is what makes the output deterministic.
    /// - Parameter screen: The navigation title to expect, or `nil` to only
    ///   wait for loading to finish.
    @MainActor
    private func waitUntilLoaded(_ app: XCUIApplication, screen: String?) {
        if let screen {
            XCTAssertTrue(
                app.navigationBars[screen].waitForExistence(timeout: 10),
                "\(screen) never appeared"
            )
        }
        let spinner = app.activityIndicators.firstMatch
        if spinner.exists {
            XCTAssertTrue(
                spinner.waitForNonExistence(timeout: 20),
                "\(screen ?? "the screen") is still loading"
            )
        }
    }

    /// Files a full-screen shot under a stable name.
    ///
    /// `XCUIScreen.main` rather than `app.screenshot()`: the latter omits the
    /// status bar, and App Store screenshots must include it.
    @MainActor
    private func attach(name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        // Attachments are discarded on success by default, and every one of
        // these runs is meant to succeed.
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
