import KodKirintisiCore
import SwiftUI

/// Tick, cross, or an open circle, depending on how the day stands.
struct AnswerStatusMark: View {
    let digest: DailyDigest

    var body: some View {
        Image(systemName: symbolName)
            .font(.caption)
            .foregroundStyle(tint)
            .accessibilityLabel(accessibilityLabel)
    }

    private var symbolName: String {
        guard digest.isAnswered else { return "circle.dotted" }
        return digest.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var tint: Color {
        guard digest.isAnswered else { return .secondary }
        return digest.isCorrect ? .green : .red
    }

    private var accessibilityLabel: Text {
        guard digest.isAnswered else { return Text("Not answered yet") }
        return digest.isCorrect ? Text("Answered correctly") : Text("Answered incorrectly")
    }
}
