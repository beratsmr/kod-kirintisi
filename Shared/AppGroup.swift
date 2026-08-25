import Foundation

/// The container the app and the widget extension share.
///
/// Both targets compile this file, so the identifier cannot drift apart between
/// them. That matters more than it looks: a mismatched App Group does not raise
/// an error, it just hands each process its own empty container, and the widget
/// silently shows a puzzle the app has never heard of.
enum AppGroup {
    static let identifier = "group.com.beratsumer.kodkirintisi"

    /// The shared progress file, or `nil` when the container is unavailable —
    /// which in practice means the entitlement is missing or not yet granted.
    static var progressURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appending(path: "progress.json")
    }
}
