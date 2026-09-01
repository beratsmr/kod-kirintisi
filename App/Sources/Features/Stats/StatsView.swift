import KodKirintisiCore
import SwiftUI

/// The third tab: streaks and per-category accuracy, built entirely from a
/// single ``StatsSnapshot`` so the layout never has to reach back into Core.
struct StatsView: View {
    private enum LoadState {
        case loading
        case loaded(StatsSnapshot)
        case failed
    }

    @Environment(AppRouter.self) private var router

    @State private var state = LoadState.loading

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Statistics")
                // See ``AppRouter/progressRevision``: every answer moves a
                // streak and an accuracy bar on this screen.
                .task(id: router.progressRevision) { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case let .loaded(snapshot):
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryGrid(snapshot)
                    CategoryAccuracyChart(byCategory: snapshot.byCategory)
                }
                .padding()
            }
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

    private func summaryGrid(_ snapshot: StatsSnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Current Streak", value: "\(snapshot.currentStreak)", systemImage: "flame.fill")
            StatTile(title: "Longest Streak", value: "\(snapshot.longestStreak)", systemImage: "trophy.fill")
            StatTile(
                title: "Accuracy",
                value: snapshot.overall.accuracy.formatted(.percent.precision(.fractionLength(0))),
                systemImage: "checkmark.seal.fill"
            )
            StatTile(title: "Answered", value: "\(snapshot.overall.answered)", systemImage: "list.bullet")
        }
    }

    private func load() async {
        do {
            state = try await .loaded(DailyPuzzleService.shared.stats())
        } catch {
            state = .failed
        }
    }
}
