import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("User progress")
struct UserProgressTests {
    private let referenceDate = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01T00:00:00Z

    private func makeRecord(
        puzzleID: String = "swift-sample-001",
        selectedIndex: Int = 0,
        isCorrect: Bool = true,
        offset: TimeInterval = 0
    ) -> AnswerRecord {
        AnswerRecord(
            puzzleID: puzzleID,
            selectedIndex: selectedIndex,
            isCorrect: isCorrect,
            answeredAt: referenceDate.addingTimeInterval(offset)
        )
    }

    @Test("A new progress starts empty and keeps its seed")
    func startsEmpty() {
        let progress = UserProgress(installSeed: 42)

        #expect(progress.installSeed == 42)
        #expect(progress.records.isEmpty)
        #expect(progress.record(for: "swift-sample-001") == nil)
        #expect(!progress.hasAnswered("swift-sample-001"))
    }

    @Test("Recording an answer stores it")
    func recordsAnswer() {
        var progress = UserProgress(installSeed: 1)
        let record = makeRecord()

        // The result is bound first: #expect rewrites the call in a way that
        // cannot take a mutating method's receiver inout.
        let stored = progress.recordAnswer(record)

        #expect(stored)
        #expect(progress.record(for: "swift-sample-001") == record)
        #expect(progress.hasAnswered("swift-sample-001"))
    }

    @Test("The first answer to a puzzle is final")
    func firstAnswerWins() {
        var progress = UserProgress(installSeed: 1)
        let first = makeRecord(selectedIndex: 1, isCorrect: false)
        let second = makeRecord(selectedIndex: 0, isCorrect: true, offset: 60)

        let storedFirst = progress.recordAnswer(first)
        let storedSecond = progress.recordAnswer(second)

        #expect(storedFirst)
        #expect(!storedSecond)
        #expect(progress.record(for: "swift-sample-001") == first)
        #expect(progress.records.count == 1)
    }

    @Test("Resetting clears every answer but keeps the seed")
    func resetAnswersKeepsSeed() {
        var progress = UserProgress(installSeed: 42)
        progress.recordAnswer(makeRecord(puzzleID: "swift-sample-001"))
        progress.recordAnswer(makeRecord(puzzleID: "swift-sample-002", isCorrect: false))

        progress.resetAnswers()

        #expect(progress.installSeed == 42)
        #expect(progress.records.isEmpty)
    }

    @Test("A puzzle answered after a reset can be recorded again")
    func canAnswerAgainAfterReset() {
        var progress = UserProgress(installSeed: 1)
        progress.recordAnswer(makeRecord(isCorrect: false))
        progress.resetAnswers()

        let stored = progress.recordAnswer(makeRecord(isCorrect: true))

        #expect(stored)
        #expect(progress.record(for: "swift-sample-001")?.isCorrect == true)
    }

    @Test("Answers to different puzzles are kept side by side")
    func keepsAnswersPerPuzzle() {
        var progress = UserProgress(installSeed: 1)

        let storedFirst = progress.recordAnswer(makeRecord(puzzleID: "swift-sample-001"))
        let storedSecond = progress.recordAnswer(
            makeRecord(puzzleID: "swift-sample-002", isCorrect: false)
        )

        #expect(storedFirst)
        #expect(storedSecond)
        #expect(progress.records.count == 2)
        #expect(progress.record(for: "swift-sample-002")?.isCorrect == false)
    }

    @Test("Progress round-trips through JSON")
    func roundTripsThroughJSON() throws {
        var progress = UserProgress(installSeed: .max)
        progress.recordAnswer(makeRecord())
        progress.recordAnswer(makeRecord(puzzleID: "swift-sample-002", isCorrect: false, offset: 3600))

        let data = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(UserProgress.self, from: data)

        #expect(decoded == progress)
        #expect(decoded.installSeed == .max)
        #expect(decoded.records.count == 2)
    }

    @Test("An answer record encodes puzzleId in the documented shape")
    func recordUsesDocumentedKeys() throws {
        let data = try JSONEncoder().encode(makeRecord())
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let json = try #require(object)

        #expect(json["puzzleId"] as? String == "swift-sample-001")
        #expect(json["selectedIndex"] as? Int == 0)
        #expect(json["isCorrect"] as? Bool == true)
    }
}
