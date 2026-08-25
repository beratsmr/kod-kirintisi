import SwiftUI

/// Flame and count for the current streak.
///
/// A streak of zero shows nothing rather than a discouraging "0" — the widget
/// has little enough room that a number meaning "you have no streak" is not
/// worth the line.
struct StreakLabel: View {
    let streak: Int

    var body: some View {
        if streak > 0 {
            HStack(spacing: 2) {
                Image(systemName: "flame.fill")
                Text(streak, format: .number)
            }
            .font(.system(.caption2, weight: .medium))
            .foregroundStyle(.orange)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Streak: \(streak) days"))
        }
    }
}
