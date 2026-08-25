import KodKirintisiCore
import XCTest
@testable import KodKirintisi

/// Covers the seam between `Core` and the two processes.
///
/// `Core` is tested on Linux and the SwiftUI views need eyes on a device, but
/// ``DailyPuzzleService`` sits between them and is where a wiring mistake would
/// actually bite: answering the wrong puzzle, or losing the answer on the way
/// to disk. XCTest rather than swift-testing because this bundle runs on the
/// simulator, per `CLAUDE.md`.
final class DailyPuzzleServiceTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory
    private var service = DailyPuzzleService()

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        service = DailyPuzzleService(progressURL: directory.appending(path: "progress.json"))
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        try super.tearDownWithError()
    }

    func testDigestComesFromTheBundledBank() async throws {
        let digest = try await service.digest()
        let bank = try PuzzleBank.shared()

        XCTAssertTrue(bank.puzzles.contains(digest.puzzle))
        XCTAssertFalse(digest.isAnswered)
    }

    func testAskingTwiceOnTheSameDayGivesTheSamePuzzle() async throws {
        let first = try await service.digest()
        let second = try await service.digest()

        XCTAssertEqual(first.puzzle, second.puzzle)
    }

    func testAnsweringCorrectlyIsRecorded() async throws {
        let digest = try await service.digest()
        let answered = try await service.answer(choiceIndex: digest.puzzle.correctIndex)

        XCTAssertTrue(answered.isAnswered)
        XCTAssertTrue(answered.isCorrect)
        XCTAssertEqual(answered.record?.puzzleID, digest.puzzle.id)
        XCTAssertEqual(answered.currentStreak, 1)
    }

    func testAnsweringWronglyIsRecordedAsWrong() async throws {
        let digest = try await service.digest()
        let wrongIndex = try XCTUnwrap(
            digest.puzzle.choices.indices.first { $0 != digest.puzzle.correctIndex }
        )

        let answered = try await service.answer(choiceIndex: wrongIndex)

        XCTAssertTrue(answered.isAnswered)
        XCTAssertFalse(answered.isCorrect)
        XCTAssertEqual(answered.record?.selectedIndex, wrongIndex)
    }

    func testTheFirstAnswerWins() async throws {
        let digest = try await service.digest()
        let wrongIndex = try XCTUnwrap(
            digest.puzzle.choices.indices.first { $0 != digest.puzzle.correctIndex }
        )

        _ = try await service.answer(choiceIndex: wrongIndex)
        let second = try await service.answer(choiceIndex: digest.puzzle.correctIndex)

        // Tapping again after answering must not turn a wrong day into a right
        // one — the widget hides the buttons, but the intent is still reachable.
        XCTAssertEqual(second.record?.selectedIndex, wrongIndex)
        XCTAssertFalse(second.isCorrect)
    }

    func testAnOutOfRangeChoiceChangesNothing() async throws {
        let digest = try await service.digest()
        let untouched = try await service.answer(choiceIndex: digest.puzzle.choices.count + 5)

        XCTAssertFalse(untouched.isAnswered)
    }

    func testTheAnswerSurvivesANewService() async throws {
        let url = directory.appending(path: "progress.json")
        let digest = try await service.digest()
        _ = try await service.answer(choiceIndex: digest.puzzle.correctIndex)

        // A second instance stands in for the app reading what the widget wrote.
        let reopened = DailyPuzzleService(progressURL: url)
        let seenByTheApp = try await reopened.digest()

        XCTAssertEqual(seenByTheApp.puzzle, digest.puzzle)
        XCTAssertTrue(seenByTheApp.isCorrect)
    }

    func testAMissingContainerReportsItselfRatherThanCrashing() async throws {
        let orphan = DailyPuzzleService(progressURL: nil)

        do {
            _ = try await orphan.digest()
            XCTFail("Expected the service to refuse without a container")
        } catch DailyPuzzleService.Failure.containerUnavailable {
            // Expected: the widget shows PuzzleUnavailableView instead of blank.
        }
    }
}
