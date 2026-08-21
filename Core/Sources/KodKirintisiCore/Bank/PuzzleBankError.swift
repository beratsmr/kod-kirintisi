import Foundation

/// Errors raised while loading or validating the puzzle bank.
///
/// Every case carries the offending puzzle's `id` so that a failing
/// integrity test names the exact entry to fix.
public enum PuzzleBankError: Error, Equatable {
    /// `puzzles.json` was not bundled with the package.
    case resourceMissing
    /// The bundled JSON could not be decoded into puzzles.
    case decodingFailed(String)
    /// Two puzzles share an `id`; progress is keyed by `id`, so it must be unique.
    case duplicateIdentifier(String)
    /// `correctIndex` does not point at an entry of `choices`.
    case correctIndexOutOfRange(String)
    /// `whyOthersWrong` is not the same length as `choices`.
    case explanationCountMismatch(String)
    /// The `whyOthersWrong` entry at `correctIndex` is not an empty string.
    case explanationNotEmptyForCorrectChoice(String)
    /// A field is too long to render in the widget. `field` names it.
    case widgetLimitExceeded(id: String, field: String)
}
