import Foundation

/// Everything the app remembers about one installation.
///
/// A puzzle can be answered only once: the first answer is final, which is what
/// makes the widget's tap-to-answer flow unambiguous. Attempting to answer an
/// already-answered puzzle leaves the stored record untouched.
public struct UserProgress: Sendable, Codable, Equatable {
    /// Per-installation seed for the deterministic daily shuffle.
    ///
    /// Generated once at first launch so that two users see puzzles in a
    /// different order, and never changed afterwards.
    public let installSeed: UInt64

    /// Answers keyed by ``Puzzle/id``.
    public private(set) var records: [String: AnswerRecord]

    public init(installSeed: UInt64, records: [String: AnswerRecord] = [:]) {
        self.installSeed = installSeed
        self.records = records
    }

    /// The answer given for a puzzle, or `nil` if it has not been answered.
    public func record(for puzzleID: String) -> AnswerRecord? {
        records[puzzleID]
    }

    /// Whether the given puzzle has already been answered.
    public func hasAnswered(_ puzzleID: String) -> Bool {
        records[puzzleID] != nil
    }

    /// Stores an answer, unless the puzzle was already answered.
    /// - Returns: `true` when the record was stored, `false` when an earlier
    ///   answer for the same puzzle was kept.
    @discardableResult
    public mutating func recordAnswer(_ record: AnswerRecord) -> Bool {
        guard records[record.puzzleID] == nil else { return false }
        records[record.puzzleID] = record
        return true
    }
}
