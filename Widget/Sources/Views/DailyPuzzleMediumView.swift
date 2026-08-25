import KodKirintisiCore
import SwiftUI

/// Medium family: the question and the answer buttons — the heart of the app.
///
/// The layout is deliberately tight. `Puzzle.WidgetLimits` caps the question at
/// 120 characters, a snippet at six lines of 44, and a choice at 24, precisely
/// so that this view never has to scroll or truncate; the bank refuses content
/// that would not fit.
struct DailyPuzzleMediumView: View {
    let digest: DailyDigest

    private var choiceColumns: [GridItem] {
        // Two or four choices read best in two columns; three fit better in a
        // single column, where an orphan on the second row would look broken.
        let columns = digest.puzzle.choices.count == 3 ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 4), count: columns)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                PuzzleCategoryBadge(category: digest.puzzle.category)
                Spacer(minLength: 0)
                StreakLabel(streak: digest.currentStreak)
                AnswerStatusMark(digest: digest)
            }

            Text(digest.puzzle.question)
                .font(.system(.caption, weight: .medium))
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if let snippet = digest.puzzle.codeSnippet {
                Text(snippet)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(Puzzle.WidgetLimits.codeSnippetLines)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 2)

            LazyVGrid(columns: choiceColumns, spacing: 4) {
                ForEach(Array(digest.puzzle.choices.enumerated()), id: \.offset) { index, choice in
                    PuzzleChoiceButton(digest: digest, index: index, title: choice)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
