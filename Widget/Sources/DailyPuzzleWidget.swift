import SwiftUI
import WidgetKit

/// The home and lock screen puzzle widget.
struct DailyPuzzleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: WidgetKind.dailyPuzzle,
            provider: DailyPuzzleTimelineProvider()
        ) { entry in
            DailyPuzzleWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Kod Kırıntısı")
        .description("Today's Swift puzzle — answer it without leaving the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
