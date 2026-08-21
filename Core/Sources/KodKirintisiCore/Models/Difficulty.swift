import Foundation

/// How demanding a puzzle is.
///
/// The raw values are part of the bundled bank format and must never change.
public enum Difficulty: Int, Sendable, Codable, CaseIterable {
    /// Fundamentals a newcomer is expected to recognise.
    case basic = 1
    /// Everyday knowledge that is easy to misremember under pressure.
    case intermediate = 2
    /// Subtle behaviour that trips up experienced developers.
    case advanced = 3
}
