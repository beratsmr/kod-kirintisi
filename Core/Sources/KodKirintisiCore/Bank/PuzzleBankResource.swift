import Foundation

/// Locates the bundled puzzle bank.
///
/// The bank ships as an SPM resource so that the app target, the widget
/// extension and the Linux test suite all read the exact same file.
public enum PuzzleBankResource {
    /// Name of the bundled JSON file, without extension.
    public static let fileName = "puzzles"

    /// URL of the bundled puzzle bank, or `nil` if the resource is missing.
    public static var url: URL? {
        Bundle.module.url(forResource: fileName, withExtension: "json")
    }

    /// Raw contents of the bundled puzzle bank.
    /// - Throws: `PuzzleBankError.resourceMissing` when the resource is not bundled.
    public static func data() throws -> Data {
        guard let url else { throw PuzzleBankError.resourceMissing }
        return try Data(contentsOf: url)
    }
}
