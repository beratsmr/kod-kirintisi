import Foundation

/// The validated collection of puzzles that ships with the app.
///
/// A bank can only exist in a valid state: every initialiser runs
/// ``PuzzleBank/validate(_:)`` and throws ``PuzzleBankError`` rather than
/// returning a half-checked value. `PuzzleBankIntegrityTests` loads the real
/// bundled bank through the same path, so malformed content fails in CI
/// instead of shipping.
public struct PuzzleBank: Sendable, Equatable {
    /// Bumped whenever puzzles are appended, to invalidate the Spotlight index.
    public let version: Int

    /// Puzzles in bank order. Order is stable: entries are only ever appended,
    /// because the daily selection is derived from the index.
    public let puzzles: [Puzzle]

    /// Creates a bank from already-decoded puzzles.
    /// - Throws: ``PuzzleBankError`` if any puzzle is invalid.
    public init(version: Int, puzzles: [Puzzle]) throws {
        try Self.validate(puzzles)
        self.version = version
        self.puzzles = puzzles
    }

    /// Decodes and validates a bank from raw `puzzles.json` contents.
    /// - Throws: ``PuzzleBankError/decodingFailed(_:)`` if the JSON does not
    ///   match the schema, or any validation error.
    public static func decode(from data: Data) throws -> PuzzleBank {
        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw PuzzleBankError.decodingFailed(String(describing: error))
        }
        return try PuzzleBank(version: payload.version, puzzles: payload.puzzles)
    }

    /// Decodes and validates the bank bundled with this package.
    public static func bundled() throws -> PuzzleBank {
        try decode(from: PuzzleBankResource.data())
    }

    /// The bundled bank, loaded once and reused.
    ///
    /// The widget timeline provider runs under a tight budget and must not
    /// re-parse the JSON on every refresh, so the result — success or failure —
    /// is computed a single time.
    /// - Throws: the error produced by the one-time load.
    public static func shared() throws -> PuzzleBank {
        try cached.get()
    }

    private static let cached: Result<PuzzleBank, PuzzleBankError> = {
        do {
            return try .success(bundled())
        } catch let error as PuzzleBankError {
            return .failure(error)
        } catch {
            return .failure(.decodingFailed(String(describing: error)))
        }
    }()

    /// The on-disk shape of `puzzles.json`.
    private struct Payload: Decodable {
        let version: Int
        let puzzles: [Puzzle]
    }

    /// Checks bank-wide rules, then each puzzle in turn.
    private static func validate(_ puzzles: [Puzzle]) throws {
        var seenIDs = Set<String>()
        for puzzle in puzzles {
            guard seenIDs.insert(puzzle.id).inserted else {
                throw PuzzleBankError.duplicateIdentifier(puzzle.id)
            }
            try validate(puzzle)
        }
    }

    /// Checks one puzzle against the schema rules and the widget limits.
    private static func validate(_ puzzle: Puzzle) throws {
        let id = puzzle.id

        guard Puzzle.WidgetLimits.choiceCount.contains(puzzle.choices.count) else {
            throw PuzzleBankError.widgetLimitExceeded(id: id, field: "choices")
        }
        guard puzzle.choices.indices.contains(puzzle.correctIndex) else {
            throw PuzzleBankError.correctIndexOutOfRange(id)
        }
        guard puzzle.whyOthersWrong.count == puzzle.choices.count else {
            throw PuzzleBankError.explanationCountMismatch(id)
        }
        guard puzzle.whyOthersWrong[puzzle.correctIndex].isEmpty else {
            throw PuzzleBankError.explanationNotEmptyForCorrectChoice(id)
        }
        guard puzzle.title.count <= Puzzle.WidgetLimits.titleLength else {
            throw PuzzleBankError.widgetLimitExceeded(id: id, field: "title")
        }
        guard puzzle.question.count <= Puzzle.WidgetLimits.questionLength else {
            throw PuzzleBankError.widgetLimitExceeded(id: id, field: "question")
        }
        if let index = puzzle.choices.firstIndex(where: { $0.count > Puzzle.WidgetLimits.choiceLength }) {
            throw PuzzleBankError.widgetLimitExceeded(id: id, field: "choices[\(index)]")
        }
        if let snippet = puzzle.codeSnippet {
            let lines = snippet.split(separator: "\n", omittingEmptySubsequences: false)
            guard lines.count <= Puzzle.WidgetLimits.codeSnippetLines else {
                throw PuzzleBankError.widgetLimitExceeded(id: id, field: "codeSnippet")
            }
            guard !lines.contains(where: { $0.count > Puzzle.WidgetLimits.codeSnippetLineLength }) else {
                throw PuzzleBankError.widgetLimitExceeded(id: id, field: "codeSnippet")
            }
        }
    }
}
