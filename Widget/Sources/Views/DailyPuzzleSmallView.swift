import KodKirintisiCore
import SwiftUI

/// Small family: the headline, the category, and how the streak stands.
///
/// There is no room to answer here, so the whole widget is a tap target that
/// opens the app — WidgetKit gives a `StaticConfiguration` that behaviour for
/// free, without a `Link`.
struct DailyPuzzleSmallView: View {
    let digest: DailyDigest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PuzzleCategoryBadge(category: digest.puzzle.category)

            Text(digest.puzzle.title)
                .font(.system(.subheadline, weight: .semibold))
                .lineLimit(4)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 2)

            HStack(spacing: 6) {
                StreakLabel(streak: digest.currentStreak)
                Spacer(minLength: 0)
                AnswerStatusMark(digest: digest)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
