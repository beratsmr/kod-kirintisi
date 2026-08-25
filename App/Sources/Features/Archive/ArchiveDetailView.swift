import KodKirintisiCore
import SwiftUI

/// A single past puzzle, read-only.
///
/// `onSelect: nil` here is not a UI restriction so much as a fact: Core only
/// ever records an answer against *today's* puzzle (``DailyDigest`` has no
/// way to say "answer this other day instead"), so an old entry could never
/// really be answered from here regardless.
struct ArchiveDetailView: View {
    let entry: PuzzleArchive.Entry

    var body: some View {
        ScrollView {
            PuzzleCardView(digest: entry.asDigest, onSelect: nil)
                .padding()
        }
        .navigationTitle(entry.puzzle.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
