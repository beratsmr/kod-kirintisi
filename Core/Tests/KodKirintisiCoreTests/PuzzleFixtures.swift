import Foundation
@testable import KodKirintisiCore

/// Builds a puzzle that passes every validation rule.
///
/// Tests override exactly the field under test, so a failure points at that
/// field rather than at unrelated fixture drift.
func makePuzzle(
    id: String = "swift-sample-001",
    category: PuzzleCategory = .swiftLanguage,
    difficulty: Difficulty = .basic,
    title: String = "A sample puzzle",
    question: String = "What does this print?",
    codeSnippet: String? = "print(1)",
    language: CodeLanguage = .swift,
    choices: [String] = ["1", "2"],
    correctIndex: Int = 0,
    explanation: String = "One is printed, because the literal is one.",
    whyOthersWrong: [String]? = nil,
    reference: Puzzle.Reference? = nil,
    tags: [String] = ["sample"]
) -> Puzzle {
    Puzzle(
        id: id,
        category: category,
        difficulty: difficulty,
        title: title,
        question: question,
        codeSnippet: codeSnippet,
        language: language,
        choices: choices,
        correctIndex: correctIndex,
        explanation: explanation,
        whyOthersWrong: whyOthersWrong ?? defaultExplanations(choices: choices, correctIndex: correctIndex),
        reference: reference,
        tags: tags
    )
}

/// Wrong-answer notes matching `choices`, with an empty entry at `correctIndex`.
private func defaultExplanations(choices: [String], correctIndex: Int) -> [String] {
    choices.indices.map { $0 == correctIndex ? "" : "Not this one." }
}
