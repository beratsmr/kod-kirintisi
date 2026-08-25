import AppIntents
import KodKirintisiCore
import SwiftUI

/// One answer button in the medium widget.
///
/// While the day is open the button runs ``AnswerPuzzleIntent`` — an interactive
/// widget cannot use a closure. Once answered it stops being a button entirely
/// and becomes a plain label, so a second tap cannot fire an intent that
/// ``ProgressStore`` would only reject anyway.
struct PuzzleChoiceButton: View {
    let digest: DailyDigest
    let index: Int
    let title: String

    var body: some View {
        if digest.isAnswered {
            label
        } else {
            Button(intent: AnswerPuzzleIntent(choiceIndex: index)) {
                label
            }
            .buttonStyle(.plain)
        }
    }

    private var label: some View {
        Text(title)
            .font(.system(.caption2, design: .monospaced, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(background, in: .rect(cornerRadius: 7))
            .foregroundStyle(foreground)
    }

    /// Before answering every choice looks the same — a hint here would give the
    /// answer away. Afterwards the correct one is always marked, and a wrong
    /// pick is marked too, so the user sees both what they chose and what was
    /// right without opening the app.
    private var background: AnyShapeStyle {
        guard digest.isAnswered else { return AnyShapeStyle(.fill.secondary) }

        if index == digest.puzzle.correctIndex {
            return AnyShapeStyle(Color.green.opacity(0.25))
        }
        if digest.record?.selectedIndex == index {
            return AnyShapeStyle(Color.red.opacity(0.25))
        }
        return AnyShapeStyle(.fill.quaternary)
    }

    private var foreground: Color {
        guard digest.isAnswered else { return .primary }

        if index == digest.puzzle.correctIndex {
            return .green
        }
        if digest.record?.selectedIndex == index {
            return .red
        }
        return .secondary
    }
}
