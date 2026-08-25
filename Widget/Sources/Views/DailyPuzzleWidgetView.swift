import SwiftUI
import WidgetKit

/// Routes an entry to the layout for the family the system asked for.
struct DailyPuzzleWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: DailyPuzzleEntry

    var body: some View {
        switch entry.state {
        case let .ready(digest):
            switch family {
            case .systemSmall:
                DailyPuzzleSmallView(digest: digest)
            case .accessoryRectangular:
                DailyPuzzleAccessoryRectangularView(digest: digest)
            default:
                DailyPuzzleMediumView(digest: digest)
            }
        case .unavailable:
            PuzzleUnavailableView()
        }
    }
}
