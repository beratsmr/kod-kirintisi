import KodKirintisiCore
import SwiftUI
import WidgetKit

/// The first tab: today's puzzle, answerable right here without the widget.
///
/// This mirrors the widget's medium view rather than sharing its code with
/// it: the widget is bound to `Button(intent:)` and `Puzzle.WidgetLimits`,
/// neither of which apply to a plain screen. What the two do share is
/// `DailyPuzzleService` underneath and ``PuzzleCardView`` on top.
struct TodayView: View {
    private enum LoadState {
        case loading
        case loaded(DailyDigest)
        case failed
    }

    @Environment(AppRouter.self) private var router

    @State private var state = LoadState.loading

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today")
                .task { await load() }
                // A reveal lasts only as long as the visit that asked for it.
                // Leaving the tab is the clearest "I'm done looking" signal
                // available without inventing a piece of stored state.
                .onDisappear { router.revealsTodaysAnswer = false }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView()
        case let .loaded(digest):
            ScrollView {
                PuzzleCardView(
                    digest: digest,
                    isRevealed: router.revealsTodaysAnswer,
                    onSelect: digest.isAnswered ? nil : { index in
                        Task { await answer(index) }
                    }
                )
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

    private func load() async {
        do {
            state = try await .loaded(DailyPuzzleService.shared.digest())
        } catch {
            state = .failed
        }
    }

    private func answer(_ index: Int) async {
        do {
            state = try await .loaded(DailyPuzzleService.shared.answer(choiceIndex: index))
            // The widget caches its own timeline; without this it would keep
            // showing "not answered" until its next scheduled refresh.
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.dailyPuzzle)
        } catch {
            state = .failed
        }
    }
}
