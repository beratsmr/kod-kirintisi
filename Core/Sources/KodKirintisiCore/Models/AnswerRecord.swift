import Foundation

/// One answer the user gave, to one puzzle.
///
/// ``isCorrect`` is stored rather than derived so that statistics and streaks
/// can be computed without loading the puzzle bank.
public struct AnswerRecord: Sendable, Codable, Equatable, Identifiable {
    /// The answered puzzle's ``Puzzle/id``.
    public let puzzleID: String
    /// Index into the puzzle's `choices` that the user tapped.
    public let selectedIndex: Int
    /// Whether ``selectedIndex`` matched the puzzle's `correctIndex`.
    public let isCorrect: Bool
    /// When the answer was given, used to group answers into days.
    public let answeredAt: Date

    public var id: String {
        puzzleID
    }

    public init(puzzleID: String, selectedIndex: Int, isCorrect: Bool, answeredAt: Date) {
        self.puzzleID = puzzleID
        self.selectedIndex = selectedIndex
        self.isCorrect = isCorrect
        self.answeredAt = answeredAt
    }

    private enum CodingKeys: String, CodingKey {
        case puzzleID = "puzzleId"
        case selectedIndex
        case isCorrect
        case answeredAt
    }
}
