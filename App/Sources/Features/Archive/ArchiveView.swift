import KodKirintisiCore
import SwiftUI

/// The second tab: every puzzle the schedule has revealed so far, searchable
/// and filterable by category and difficulty, each one reopenable read-only.
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

    @State private var state = LoadState.loading
    @State private var searchText = ""
    @State private var categoryFilter: PuzzleCategory?
    @State private var difficultyFilter: Difficulty?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Archive")
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) { filterMenu }
                }
                .task { await load() }
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
                NavigationLink {
                    ArchiveDetailView(entry: entry)
                } label: {
                    ArchiveEntryRow(entry: entry)
                }
            }
        }
    }

    private var filterMenu: some View {
        Menu {
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
        categoryFilter != nil || difficultyFilter != nil
    }

    /// Newest reveal first, since browsing the archive is looking back at
    /// what was recently answered rather than reading it front to back.
    private func filtered(_ entries: [PuzzleArchive.Entry]) -> [PuzzleArchive.Entry] {
        entries
            .reversed()
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
