import Foundation

/// The single point through which progress is read and changed.
///
/// The app and the widget both mutate progress, and inside one process several
/// tasks may answer at once, so every mutation is serialised by this actor and
/// written through immediately. Between processes, safety comes from the
/// atomic write in the underlying store rather than from the actor.
public actor ProgressStore {
    private let persistence: any ProgressPersisting
    private let makeSeed: @Sendable () -> UInt64
    private var cached: UserProgress?

    /// - Parameters:
    ///   - persistence: Where progress is kept.
    ///   - makeSeed: Produces the installation seed on first launch. It is
    ///     injected rather than read from the system generator so tests are
    ///     deterministic; production passes `{ UInt64.random(in: .min ... .max) }`.
    public init(
        persistence: any ProgressPersisting,
        makeSeed: @escaping @Sendable () -> UInt64
    ) {
        self.persistence = persistence
        self.makeSeed = makeSeed
    }

    /// The current progress, loading it on first use.
    ///
    /// On a first launch a fresh progress is created and **written straight
    /// away**, because the app and the widget derive the daily puzzle from the
    /// seed: if it were only held in memory, the two processes could generate
    /// different seeds and disagree about the day's puzzle.
    public func progress() throws -> UserProgress {
        if let cached {
            return cached
        }

        if let loaded = try persistence.load() {
            cached = loaded
            return loaded
        }

        let fresh = UserProgress(installSeed: makeSeed())
        try persistence.save(fresh)
        cached = fresh
        return fresh
    }

    /// Stores an answer, unless that puzzle was already answered.
    ///
    /// The in-memory copy is only updated once the write succeeds, so a failed
    /// write leaves the actor agreeing with what is actually on disk.
    /// - Returns: `true` when the answer was stored.
    @discardableResult
    public func recordAnswer(_ record: AnswerRecord) throws -> Bool {
        var progress = try progress()
        guard progress.recordAnswer(record) else { return false }

        try persistence.save(progress)
        cached = progress
        return true
    }

    /// Clears every stored answer and persists the result immediately.
    ///
    /// Keeps the same installation seed — see ``UserProgress/resetAnswers()``
    /// — so the Settings screen's "reset progress" erases history without
    /// reshuffling the schedule the app and the widget already agree on.
    public func reset() throws {
        var progress = try progress()
        progress.resetAnswers()
        try persistence.save(progress)
        cached = progress
    }

    /// Re-reads progress written by the other process.
    ///
    /// The app calls this when it comes to the foreground, since the widget may
    /// have answered in the meantime.
    public func reload() throws -> UserProgress {
        if let loaded = try persistence.load() {
            cached = loaded
            return loaded
        }

        // The file is gone — deleted, or quarantined as unreadable. Reuse the
        // seed already in memory instead of drawing a new one, which would
        // reshuffle the user's whole schedule mid-session.
        let fallback = cached ?? UserProgress(installSeed: makeSeed())
        try persistence.save(fallback)
        cached = fallback
        return fallback
    }
}
