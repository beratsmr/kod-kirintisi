import KodKirintisiCore
import SwiftUI

/// The full-size question card shared by the Today screen and the Archive
/// detail view.
///
/// Unlike the widget's medium view this is not squeezed by
/// `Puzzle.WidgetLimits` — there is room for the code snippet at full size,
/// the post-answer explanation, and the "why the others are wrong" notes.
struct PuzzleCardView: View {
    let digest: DailyDigest
    /// Called with the tapped choice's index. `nil` makes every choice a
    /// plain, unresponsive row instead of a button — the Archive uses this to
    /// look back at an old day. Core only ever records an answer against
    /// *today's* puzzle (``DailyDigest`` carries no way to say "answer this
    /// other day instead"), so an old entry could never really be answered
    /// from here regardless.
    var onSelect: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            VStack(alignment: .leading, spacing: 10) {
                Text(digest.puzzle.question)
                    .font(.headline)
                if let snippet = digest.puzzle.codeSnippet {
                    Text(snippet)
                        .font(.system(.callout, design: .monospaced))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 8))
                }
            }
            choices
            if digest.isAnswered {
                explanation
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            PuzzleCategoryBadge(category: digest.puzzle.category)
            Spacer(minLength: 0)
            StreakLabel(streak: digest.currentStreak)
            AnswerStatusMark(digest: digest)
        }
    }

    private var choices: some View {
        VStack(spacing: 8) {
            ForEach(Array(digest.puzzle.choices.enumerated()), id: \.offset) { index, choice in
                choiceRow(index: index, title: choice)
            }
        }
    }

    @ViewBuilder
    private func choiceRow(index: Int, title: String) -> some View {
        if let onSelect, !digest.isAnswered {
            Button {
                onSelect(index)
            } label: {
                choiceLabel(index: index, title: title)
            }
            .buttonStyle(.plain)
        } else {
            choiceLabel(index: index, title: title)
        }
    }

    private func choiceLabel(index: Int, title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .monospaced))
            Spacer(minLength: 8)
            if digest.isAnswered, index == digest.puzzle.correctIndex {
                Image(systemName: "checkmark.circle.fill")
            } else if digest.record?.selectedIndex == index {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(choiceBackground(index: index), in: .rect(cornerRadius: 10))
        .foregroundStyle(choiceForeground(index: index))
    }

    /// Before answering every choice looks the same — a hint here would give
    /// the answer away. Afterwards the correct one is always marked, and a
    /// wrong pick is marked too, so the user sees both what they chose and
    /// what was right.
    private func choiceBackground(index: Int) -> AnyShapeStyle {
        guard digest.isAnswered else { return AnyShapeStyle(.fill.secondary) }

        if index == digest.puzzle.correctIndex {
            return AnyShapeStyle(Color.green.opacity(0.2))
        }
        if digest.record?.selectedIndex == index {
            return AnyShapeStyle(Color.red.opacity(0.2))
        }
        return AnyShapeStyle(.fill.quaternary)
    }

    private func choiceForeground(index: Int) -> Color {
        guard digest.isAnswered else { return .primary }

        if index == digest.puzzle.correctIndex {
            return .green
        }
        if digest.record?.selectedIndex == index {
            return .red
        }
        return .secondary
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()

            Text(digest.puzzle.explanation)
                .font(.body)

            if let note = wrongAnswerNote {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let reference = digest.puzzle.reference, let url = URL(string: reference.url) {
                Link(reference.title, destination: url)
                    .font(.callout)
            }
        }
    }

    /// Why the tapped wrong choice was wrong, or `nil` when the answer was
    /// correct — the schema leaves ``Puzzle/whyOthersWrong`` empty at
    /// `correctIndex`, so there is nothing to show either way.
    private var wrongAnswerNote: String? {
        guard let record = digest.record, !record.isCorrect,
              digest.puzzle.whyOthersWrong.indices.contains(record.selectedIndex)
        else {
            return nil
        }
        let note = digest.puzzle.whyOthersWrong[record.selectedIndex]
        return note.isEmpty ? nil : note
    }
}
