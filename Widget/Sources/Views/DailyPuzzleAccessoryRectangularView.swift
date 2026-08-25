import KodKirintisiCore
import SwiftUI

/// Lock screen family: the headline and whether the day is done.
///
/// Lock screen accessories are rendered as a stencil, so colour carries no
/// meaning here — the tick and cross have to be legible on their own.
struct DailyPuzzleAccessoryRectangularView: View {
    let digest: DailyDigest

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 3) {
                Image(systemName: digest.puzzle.category.symbolName)
                Text(digest.puzzle.category.badgeName)
                if digest.currentStreak > 0 {
                    Image(systemName: "flame.fill")
                    Text(digest.currentStreak, format: .number)
                }
            }
            .font(.system(.caption2, weight: .semibold))
            .widgetAccentable()

            Text(digest.puzzle.title)
                .font(.system(.caption, weight: .medium))
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Label {
                Text(statusText)
            } icon: {
                Image(systemName: statusSymbol)
            }
            .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSymbol: String {
        guard digest.isAnswered else { return "circle.dotted" }
        return digest.isCorrect ? "checkmark" : "xmark"
    }

    private var statusText: LocalizedStringResource {
        guard digest.isAnswered else { return "Not answered" }
        return digest.isCorrect ? "Correct" : "Wrong"
    }
}
