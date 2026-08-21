import Foundation
import Testing
@testable import KodKirintisiCore

@Suite("Puzzle decoding")
struct PuzzleTests {
    @Test("A fully populated puzzle decodes every field")
    func decodesAllFields() throws {
        let json = """
        {
          "id": "swift-value-semantics-001",
          "category": "swift-language",
          "difficulty": 2,
          "title": "Copying a struct",
          "question": "What does this print?",
          "codeSnippet": "print(a.x)",
          "language": "swift",
          "choices": ["0", "5"],
          "correctIndex": 0,
          "explanation": "Structs are value types, so the copy is independent.",
          "whyOthersWrong": ["", "That would be true for a class."],
          "reference": { "title": "Swift Book", "url": "https://docs.swift.org" },
          "tags": ["value-type", "struct"]
        }
        """
        let puzzle = try JSONDecoder().decode(Puzzle.self, from: Data(json.utf8))

        #expect(puzzle.id == "swift-value-semantics-001")
        #expect(puzzle.category == .swiftLanguage)
        #expect(puzzle.difficulty == .intermediate)
        #expect(puzzle.title == "Copying a struct")
        #expect(puzzle.codeSnippet == "print(a.x)")
        #expect(puzzle.language == .swift)
        #expect(puzzle.choices == ["0", "5"])
        #expect(puzzle.correctIndex == 0)
        #expect(puzzle.whyOthersWrong.count == 2)
        #expect(puzzle.tags == ["value-type", "struct"])

        let reference = try #require(puzzle.reference)
        #expect(reference.title == "Swift Book")
        #expect(reference.url == "https://docs.swift.org")
    }

    @Test("An absent language defaults to Swift")
    func languageDefaultsToSwift() throws {
        let json = """
        {
          "id": "swift-sample-001",
          "category": "algorithms",
          "difficulty": 1,
          "title": "A sample puzzle",
          "question": "Pick one.",
          "choices": ["a", "b"],
          "correctIndex": 1,
          "explanation": "Because b is the answer here.",
          "whyOthersWrong": ["Not a.", ""],
          "tags": ["sample"]
        }
        """
        let puzzle = try JSONDecoder().decode(Puzzle.self, from: Data(json.utf8))

        #expect(puzzle.language == .swift)
        #expect(puzzle.codeSnippet == nil)
        #expect(puzzle.reference == nil)
        #expect(puzzle.category == .algorithms)
    }

    @Test("A conceptual puzzle decodes language none")
    func decodesLanguageNone() throws {
        let json = """
        {
          "id": "concurrency-sample-001",
          "category": "concurrency",
          "difficulty": 3,
          "title": "A concept question",
          "question": "Pick one.",
          "language": "none",
          "choices": ["a", "b"],
          "correctIndex": 0,
          "explanation": "A is the answer for a reason worth reading.",
          "whyOthersWrong": ["", "Not b."],
          "tags": ["sample"]
        }
        """
        let puzzle = try JSONDecoder().decode(Puzzle.self, from: Data(json.utf8))

        #expect(puzzle.language == CodeLanguage.none)
        #expect(puzzle.difficulty == .advanced)
    }

    @Test("Every category raw value round-trips")
    func categoryRawValuesRoundTrip() {
        for category in PuzzleCategory.allCases {
            #expect(PuzzleCategory(rawValue: category.rawValue) == category)
        }
    }

    @Test("Difficulty maps the documented raw values")
    func difficultyRawValues() {
        #expect(Difficulty.basic.rawValue == 1)
        #expect(Difficulty.intermediate.rawValue == 2)
        #expect(Difficulty.advanced.rawValue == 3)
        #expect(Difficulty.allCases.count == 3)
    }
}
