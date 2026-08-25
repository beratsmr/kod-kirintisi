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

    /// Day zero of this installation's schedule.
    ///
    /// The schedule used to count from a fixed calendar date, which meant a
    /// user installing months later found the whole archive already unlocked
    /// and nothing left to come back for. Counting from the install gives
    /// everyone a real first day. See ``DailyPuzzleSelector``.
    public let installedOn: Date

    /// Answers keyed by ``Puzzle/id``.
    public private(set) var records: [String: AnswerRecord]

    public init(installSeed: UInt64, installedOn: Date, records: [String: AnswerRecord] = [:]) {
        self.installSeed = installSeed
        self.installedOn = installedOn
        self.records = records
    }

    /// Reads progress written before ``installedOn`` existed.
    ///
    /// Such a file has to be given a day zero from somewhere. The earliest
    /// answer is the best evidence of when the install actually started; with
    /// no answers there is no history to preserve, so the fixed date the
    /// schedule used to count from keeps that file exactly where it was.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        installSeed = try container.decode(UInt64.self, forKey: .installSeed)
        records = try container.decode([String: AnswerRecord].self, forKey: .records)
        installedOn = try container.decodeIfPresent(Date.self, forKey: .installedOn)
            ?? records.values.map(\.answeredAt).min()
            ?? Self.legacyEpoch
    }

    /// 2026-01-01T00:00:00Z — the fixed day zero the schedule used before it
    /// was anchored to the install.
    static let legacyEpoch = Date(timeIntervalSince1970: 1_767_225_600)

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

    /// Clears every stored answer, keeping ``installSeed`` untouched.
    ///
    /// The daily schedule is derived from the seed alone, so this does not
    /// reshuffle which puzzle appears on which day — only the answers, streak,
    /// and statistics are forgotten. A fresh seed would be a different, more
    /// drastic operation this type does not offer.
    public mutating func resetAnswers() {
        records = [:]
    }
}
