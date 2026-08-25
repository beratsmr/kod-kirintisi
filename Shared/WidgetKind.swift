/// Kind identifiers the widget extension registers with WidgetKit.
///
/// These live in `Shared` because the intents that trigger a reload run in both
/// processes, and `WidgetCenter.reloadTimelines(ofKind:)` silently does nothing
/// when handed a string no widget declares.
enum WidgetKind {
    /// The home and lock screen puzzle widget.
    static let dailyPuzzle = "DailyPuzzle"
    /// The Control Center button.
    static let todaysPuzzleControl = "TodaysPuzzleControl"
}
