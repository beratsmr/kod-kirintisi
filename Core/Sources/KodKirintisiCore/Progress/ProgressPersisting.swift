import Foundation

/// Somewhere the user's progress can be kept between launches.
///
/// This protocol is the seam that keeps the rest of the app from knowing how
/// progress is stored. v1.0 writes a JSON file in the App Group container;
/// when CloudKit sync arrives in v1.1, only the conforming type changes.
public protocol ProgressPersisting: Sendable {
    /// Reads the stored progress.
    /// - Returns: `nil` when nothing has been stored yet — a first launch is
    ///   not an error.
    func load() throws -> UserProgress?

    /// Writes the progress, replacing whatever was there.
    func save(_ progress: UserProgress) throws
}
