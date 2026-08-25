import SwiftUI

/// Shown when progress could not be read.
///
/// Saying so plainly beats an empty widget, which the user would read as "there
/// is no puzzle today" and blame the content for.
struct PuzzleUnavailableView: View {
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title3)
            Text("Puzzle unavailable")
                .font(.system(.caption, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
