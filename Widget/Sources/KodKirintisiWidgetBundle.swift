import SwiftUI
import WidgetKit

/// Entry point of the widget extension.
///
/// Everything the extension exposes to the system is listed here: the home and
/// lock screen widget, and the Control Center control.
@main
struct KodKirintisiWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyPuzzleWidget()
        TodaysPuzzleControl()
    }
}
