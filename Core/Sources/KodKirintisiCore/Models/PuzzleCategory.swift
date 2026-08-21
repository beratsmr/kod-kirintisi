import Foundation

/// The topic a puzzle belongs to.
///
/// The raw values are part of the bundled bank format and must never change;
/// they are also used as the stable key for per-category statistics.
public enum PuzzleCategory: String, Sendable, Codable, CaseIterable {
    case swiftLanguage = "swift-language"
    case concurrency
    case memoryARC = "memory-arc"
    case swiftUI = "swiftui"
    case foundation
    case algorithms
    case iOSPlatform = "ios-platform"
}
