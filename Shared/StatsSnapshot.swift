import KodKirintisiCore

/// Everything the Statistics screen needs, gathered in one call so the view
/// stays a pure function of a single value, the same shape ``DailyDigest``
/// gives the Today screen.
struct StatsSnapshot: Sendable {
    let overall: StatsCalculator.Summary
    let byCategory: [PuzzleCategory: StatsCalculator.Summary]
    let currentStreak: Int
    let longestStreak: Int
}
