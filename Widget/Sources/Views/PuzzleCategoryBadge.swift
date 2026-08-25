import KodKirintisiCore
import SwiftUI

/// The small tinted pill naming a puzzle's category.
struct PuzzleCategoryBadge: View {
    let category: PuzzleCategory

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.symbolName)
            Text(category.badgeName)
        }
        .font(.system(.caption2, weight: .semibold))
        .foregroundStyle(.tint)
        .lineLimit(1)
    }
}
