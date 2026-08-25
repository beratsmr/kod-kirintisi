import SwiftUI

/// The host application.
///
/// M5 delivered the widget, and a widget extension can only ship inside an
/// app, so this entry point existed to give it one, with a placeholder body.
/// M6 fills it in with the app's four real screens.
@main
struct KodKirintisiApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Today", systemImage: "questionmark.circle") {
                    TodayView()
                }
                Tab("Archive", systemImage: "clock.arrow.circlepath") {
                    ArchiveView()
                }
                Tab("Statistics", systemImage: "chart.bar") {
                    StatsView()
                }
                Tab("Settings", systemImage: "gearshape") {
                    SettingsView()
                }
            }
        }
    }
}
