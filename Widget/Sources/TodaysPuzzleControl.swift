import AppIntents
import SwiftUI
import WidgetKit

/// Control Center button that jumps straight to today's puzzle.
///
/// Controls arrived in iOS 18, which is the project's deployment target, so no
/// availability check is needed here.
struct TodaysPuzzleControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: WidgetKind.todaysPuzzleControl) {
            ControlWidgetButton(action: ShowTodaysPuzzleIntent()) {
                Label {
                    Text("Today's puzzle")
                } icon: {
                    Image(systemName: "curlybraces")
                }
            }
        }
        .displayName("Today's puzzle")
        .description("Opens Codestion on the puzzle of the day.")
    }
}
