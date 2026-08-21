import Foundation

/// Stores progress as a JSON file at a location chosen by the caller.
///
/// The store deliberately does **not** look up the App Group container itself:
/// the URL is injected, which keeps `Core` free of platform APIs and lets the
/// tests point it at a temporary directory on Linux.
///
/// Writes go through `Data.write(to:options: .atomic)`, so a crash or a full
/// disk halfway through leaves the previous file intact rather than a truncated
/// one — the app and the widget write to the same file from separate processes.
public struct FileProgressStore: ProgressPersisting {
    /// Where the progress file lives.
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    /// Where an unreadable file is moved before starting over.
    ///
    /// `progress.json` becomes `progress.corrupt.json`. Keeping it means the
    /// data can still be recovered by hand instead of vanishing silently.
    public var quarantineURL: URL {
        let directory = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        let corrupted = directory.appendingPathComponent("\(name).corrupt")
        let ext = url.pathExtension
        return ext.isEmpty ? corrupted : corrupted.appendingPathExtension(ext)
    }

    public func load() throws -> UserProgress? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(UserProgress.self, from: data)
        } catch {
            // The file exists but is not readable progress. Losing a streak is
            // bad; refusing to launch is worse. Move it aside and start clean.
            try quarantineUnreadableFile()
            return nil
        }
    }

    public func save(_ progress: UserProgress) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(progress)
        try data.write(to: url, options: .atomic)
    }

    private func quarantineUnreadableFile() throws {
        let manager = FileManager.default
        let destination = quarantineURL
        if manager.fileExists(atPath: destination.path) {
            try manager.removeItem(at: destination)
        }
        try manager.moveItem(at: url, to: destination)
    }
}
