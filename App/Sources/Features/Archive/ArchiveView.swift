import KodKirintisiCore
import SwiftUI

/// The second tab: every puzzle the schedule has revealed so far, searchable
/// and filterable by answer status, category and difficulty, each one
/// reopenable read-only.
///
/// "Revealed so far" is Core's rule, not this view's: ``DailyPuzzleService/archive()``
/// already excludes anything the user hasn't reached yet, so there is no
/// spoiler risk in listing everything it returns.
struct ArchiveView: View {
    private enum LoadState {
        case loading
        case loaded([PuzzleArchive.Entry])
        case failed
    }

    /// The two states worth going back for — a day answered wrong is worth
    /// rereading, and a day never answered is still open. "Answered correctly"
    /// is deliberately absent: nobody browses for what they already got right.
    private enum StatusFilter: CaseIterable {
        case all
        case answeredIncorrectly
        case unanswered

        var label: LocalizedStringKey {
            switch self {
            case .all: "All Puzzles"
            case .answeredIncorrectly: "Answered Incorrectly"
            case .unanswered: "Unanswered"
            }
        }

        func matches(_ entry: PuzzleArchive.Entry) -> Bool {
            switch self {
            case .all: true
            case .answeredIncorrectly: entry.record?.isCorrect == false
            case .unanswered: entry.record == nil
            }
        }
    }

    @Environment(AppRouter.self) private var router

    @State private var state = LoadState.loading
    @State private var searchText = ""
    @State private var statusFilter = StatusFilter.all
    @State private var categoryFilter: PuzzleCategory?
    @State private var difficultyFilter: Difficulty?

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.archivePath) {
            content
                .navigationTitle("Archive")
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { filterMenu }
                }
                .navigationDestination(for: String.self) { detail(for: $0) }
                // See ``AppRouter/progressRevision``: an answer given on Today
                // or in the widget changes a row in this list.
                .task(id: router.progressRevision) { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case let .loaded(entries):
            list(of: filtered(entries))
        case .failed:
            VStack(spacing: 12) {
                PuzzleUnavailableView()
                Button("Try Again") {
                    Task { await load() }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func list(of entries: [PuzzleArchive.Entry]) -> some View {
        if entries.isEmpty {
            ContentUnavailableView(
                "No Matching Puzzles",
                systemImage: "magnifyingglass",
                description: Text("Try a different search or filter.")
            )
        } else {
            List(entries) { entry in
                NavigationLink(value: entry.id) {
                    ArchiveEntryRow(entry: entry)
                }
            }
        }
    }

    /// Resolves a pushed id against the loaded entries.
    ///
    /// The id can arrive before ``load()`` finishes — Spotlight and Siri both
    /// push one straight into ``AppRouter/archivePath`` — so a miss here is
    /// usually "not yet", and this rebuilds once the entries land. A genuine
    /// miss means the day has not been revealed, which is the same dead end.
    @ViewBuilder
    private func detail(for puzzleID: String) -> some View {
        if case let .loaded(entries) = state, let entry = entries.first(where: { $0.id == puzzleID }) {
            ArchiveDetailView(entry: entry)
        } else {
            PuzzleUnavailableView()
        }
    }

    private var filterMenu: some View {
        Menu {
            Picker("Status", selection: $statusFilter) {
                ForEach(StatusFilter.allCases, id: \.self) { status in
                    Text(status.label).tag(status)
                }
            }
            Picker("Category", selection: $categoryFilter) {
                Text("All Categories").tag(PuzzleCategory?.none)
                ForEach(PuzzleCategory.allCases, id: \.self) { category in
                    Text(category.badgeName).tag(Optional(category))
                }
            }
            Picker("Difficulty", selection: $difficultyFilter) {
                Text("All Difficulties").tag(Difficulty?.none)
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.displayName).tag(Optional(difficulty))
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: hasActiveFilter
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
    }

    private var hasActiveFilter: Bool {
        statusFilter != .all || categoryFilter != nil || difficultyFilter != nil
    }

    /// Newest reveal first, since browsing the archive is looking back at
    /// what was recently answered rather than reading it front to back.
    private func filtered(_ entries: [PuzzleArchive.Entry]) -> [PuzzleArchive.Entry] {
        entries
            .reversed()
            .filter { statusFilter.matches($0) }
            .filter { categoryFilter == nil || $0.puzzle.category == categoryFilter }
            .filter { difficultyFilter == nil || $0.puzzle.difficulty == difficultyFilter }
            .filter { matches($0, searchText: searchText) }
    }

    private func matches(_ entry: PuzzleArchive.Entry, searchText: String) -> Bool {
        guard !searchText.isEmpty else { return true }
        return entry.puzzle.title.localizedCaseInsensitiveContains(searchText)
            || entry.puzzle.question.localizedCaseInsensitiveContains(searchText)
    }

    private func load() async {
        do {
            state = try await .loaded(DailyPuzzleService.shared.archive())
        } catch {
            state = .failed
        }
    }
}
