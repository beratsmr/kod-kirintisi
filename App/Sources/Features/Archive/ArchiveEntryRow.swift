import KodKirintisiCore
import SwiftUI

/// One line in the Archive list: what the puzzle was and how the day went.
struct ArchiveEntryRow: View {
    let entry: PuzzleArchive.Entry

    var body: some View {
        HStack(spacing: 10) {
            AnswerStatusMark(digest: entry.asDigest)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.puzzle.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    PuzzleCategoryBadge(category: entry.puzzle.category)
                    Text(entry.puzzle.difficulty.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
