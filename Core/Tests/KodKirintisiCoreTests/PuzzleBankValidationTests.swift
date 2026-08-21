import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Puzzle bank validation")
struct PuzzleBankValidationTests {
    @Test("A valid bank is accepted")
    func acceptsValidBank() throws {
        let bank = try PuzzleBank(version: 1, puzzles: [
            makePuzzle(id: "swift-sample-001"),
            makePuzzle(id: "swift-sample-002")
        ])

        #expect(bank.version == 1)
        #expect(bank.puzzles.count == 2)
    }

    @Test("An empty bank is accepted")
    func acceptsEmptyBank() throws {
        let bank = try PuzzleBank(version: 1, puzzles: [])
        #expect(bank.puzzles.isEmpty)
    }

    @Test("Two puzzles sharing an id are rejected")
    func rejectsDuplicateIdentifier() {
        #expect(throws: PuzzleBankError.duplicateIdentifier("swift-sample-001")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(id: "swift-sample-001"),
                makePuzzle(id: "swift-sample-001")
            ])
        }
    }

    @Test("A correctIndex past the last choice is rejected")
    func rejectsCorrectIndexAboveRange() {
        #expect(throws: PuzzleBankError.correctIndexOutOfRange("swift-sample-001")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a", "b"], correctIndex: 2, whyOthersWrong: ["", "Not b."])
            ])
        }
    }

    @Test("A negative correctIndex is rejected")
    func rejectsNegativeCorrectIndex() {
        #expect(throws: PuzzleBankError.correctIndexOutOfRange("swift-sample-001")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a", "b"], correctIndex: -1, whyOthersWrong: ["", "Not b."])
            ])
        }
    }

    @Test("whyOthersWrong shorter than choices is rejected")
    func rejectsExplanationCountMismatch() {
        #expect(throws: PuzzleBankError.explanationCountMismatch("swift-sample-001")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a", "b", "c"], correctIndex: 0, whyOthersWrong: ["", "Not b."])
            ])
        }
    }

    @Test("A non-empty note at the correct choice is rejected")
    func rejectsNoteForCorrectChoice() {
        #expect(throws: PuzzleBankError.explanationNotEmptyForCorrectChoice("swift-sample-001")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a", "b"], correctIndex: 0, whyOthersWrong: ["This is right.", "Not b."])
            ])
        }
    }

    @Test("A single choice is rejected")
    func rejectsTooFewChoices() {
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "choices")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a"], correctIndex: 0, whyOthersWrong: [""])
            ])
        }
    }

    @Test("More than four choices is rejected")
    func rejectsTooManyChoices() {
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "choices")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(
                    choices: ["a", "b", "c", "d", "e"],
                    correctIndex: 0,
                    whyOthersWrong: ["", "No.", "No.", "No.", "No."]
                )
            ])
        }
    }

    @Test("A title longer than the widget allows is rejected")
    func rejectsLongTitle() {
        let title = String(repeating: "a", count: Puzzle.WidgetLimits.titleLength + 1)
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "title")) {
            try PuzzleBank(version: 1, puzzles: [makePuzzle(title: title)])
        }
    }

    @Test("A title exactly at the limit is accepted")
    func acceptsTitleAtLimit() throws {
        let title = String(repeating: "a", count: Puzzle.WidgetLimits.titleLength)
        let bank = try PuzzleBank(version: 1, puzzles: [makePuzzle(title: title)])
        #expect(bank.puzzles.count == 1)
    }

    @Test("A question longer than the widget allows is rejected")
    func rejectsLongQuestion() {
        let question = String(repeating: "a", count: Puzzle.WidgetLimits.questionLength + 1)
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "question")) {
            try PuzzleBank(version: 1, puzzles: [makePuzzle(question: question)])
        }
    }

    @Test("A choice longer than the widget allows is rejected, and names its index")
    func rejectsLongChoice() {
        let choice = String(repeating: "a", count: Puzzle.WidgetLimits.choiceLength + 1)
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "choices[1]")) {
            try PuzzleBank(version: 1, puzzles: [
                makePuzzle(choices: ["a", choice], correctIndex: 0, whyOthersWrong: ["", "Not b."])
            ])
        }
    }

    @Test("A code snippet with too many lines is rejected")
    func rejectsTallSnippet() {
        let snippet = Array(repeating: "x", count: Puzzle.WidgetLimits.codeSnippetLines + 1)
            .joined(separator: "\n")
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "codeSnippet")) {
            try PuzzleBank(version: 1, puzzles: [makePuzzle(codeSnippet: snippet)])
        }
    }

    @Test("A code snippet with an over-long line is rejected")
    func rejectsWideSnippet() {
        let line = String(repeating: "x", count: Puzzle.WidgetLimits.codeSnippetLineLength + 1)
        #expect(throws: PuzzleBankError.widgetLimitExceeded(id: "swift-sample-001", field: "codeSnippet")) {
            try PuzzleBank(version: 1, puzzles: [makePuzzle(codeSnippet: "let x = 1\n\(line)")])
        }
    }

    @Test("A snippet exactly at both limits is accepted")
    func acceptsSnippetAtLimits() throws {
        let line = String(repeating: "x", count: Puzzle.WidgetLimits.codeSnippetLineLength)
        let snippet = Array(repeating: line, count: Puzzle.WidgetLimits.codeSnippetLines)
            .joined(separator: "\n")
        let bank = try PuzzleBank(version: 1, puzzles: [makePuzzle(codeSnippet: snippet)])
        #expect(bank.puzzles.count == 1)
    }

    @Test("A puzzle without a snippet skips the snippet limits")
    func acceptsMissingSnippet() throws {
        let bank = try PuzzleBank(version: 1, puzzles: [makePuzzle(codeSnippet: nil)])
        #expect(bank.puzzles.first?.codeSnippet == nil)
    }

    @Test("Malformed JSON is reported as a decoding failure")
    func rejectsMalformedJSON() {
        #expect(throws: PuzzleBankError.self) {
            try PuzzleBank.decode(from: Data("not json".utf8))
        }
    }

    @Test("Valid JSON decodes into a validated bank")
    func decodesValidJSON() throws {
        let json = """
        {
          "version": 3,
          "puzzles": [
            {
              "id": "swift-sample-001",
              "category": "foundation",
              "difficulty": 1,
              "title": "A sample puzzle",
              "question": "Pick one.",
              "choices": ["a", "b"],
              "correctIndex": 0,
              "explanation": "A is correct for a reason worth reading.",
              "whyOthersWrong": ["", "Not b."],
              "tags": ["sample"]
            }
          ]
        }
        """
        let bank = try PuzzleBank.decode(from: Data(json.utf8))

        #expect(bank.version == 3)
        #expect(bank.puzzles.count == 1)
        #expect(bank.puzzles.first?.category == .foundation)
    }

    @Test("Validation failures survive decoding")
    func decodeRunsValidation() {
        let json = """
        {
          "version": 1,
          "puzzles": [
            {
              "id": "swift-sample-001",
              "category": "foundation",
              "difficulty": 1,
              "title": "A sample puzzle",
              "question": "Pick one.",
              "choices": ["a", "b"],
              "correctIndex": 5,
              "explanation": "A is correct for a reason worth reading.",
              "whyOthersWrong": ["", "Not b."],
              "tags": ["sample"]
            }
          ]
        }
        """
        #expect(throws: PuzzleBankError.correctIndexOutOfRange("swift-sample-001")) {
            try PuzzleBank.decode(from: Data(json.utf8))
        }
    }
}
