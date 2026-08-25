import KodKirintisiCore

extension PuzzleArchive.Entry {
    /// Adapts this entry to ``DailyDigest`` so the Archive can reuse
    /// ``PuzzleCardView`` instead of a second, near-identical card.
    ///
    /// `currentStreak` is a concept tied to *today*, which an old entry is
    /// not, so it is fixed at zero here — that also keeps ``StreakLabel``
    /// from drawing a streak that has nothing to do with the day being
    /// looked at.
    var asDigest: DailyDigest {
        DailyDigest(puzzle: puzzle, record: record, currentStreak: 0, dayIndex: revealedOnDayIndex)
    }
}
