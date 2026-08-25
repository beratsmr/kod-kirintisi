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
    @MainActor
    func testCaptureScreenshots() {
        // One failed screen should not leave the remaining ones uncaptured.
        continueAfterFailure = true

        let app = XCUIApplication()
        app.launchArguments += [
            // Fabricate a believable answer history — see `DemoContent`.
            "-KodKirintisiDemoContent",
            // Pin the language: the app ships `en` and `tr`, and the screenshots
            // generated here are the English set.
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        defer { app.terminate() }

        capture(app, tab: "Today", screen: "Today", named: "01-today")
        capture(app, tab: "Archive", screen: "Archive", named: "02-archive")
        captureArchiveDetail(app, named: "03-explanation")
        capture(app, tab: "Statistics", screen: "Statistics", named: "04-statistics")
        capture(app, tab: "Settings", screen: "Settings", named: "05-settings")
    }

    // MARK: - Steps

    /// Selects a tab, waits for it to finish loading, and files the screenshot.
    @MainActor
    private func capture(
        _ app: XCUIApplication, tab: String, screen: String, named name: String
    ) {
        let button = app.tabBars.buttons[tab]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "no \(tab) tab")
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
