import Foundation

/// The language a puzzle's code snippet is written in.
///
/// `none` marks a puzzle that asks a conceptual question and ships no snippet.
public enum CodeLanguage: String, Sendable, Codable, CaseIterable {
    case swift
    case objc
    case none
}
