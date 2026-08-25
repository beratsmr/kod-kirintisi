import AppIntents
import SwiftUI

/// The host application.
///
/// M5 delivered the widget, and a widget extension can only ship inside an
/// app, so this entry point existed to give it one, with a placeholder body.
/// M6 fills it in with the app's four real screens, and M7 puts the tab
/// selection under ``AppRouter`` so that intents can steer it.
@main
struct KodKirintisiApp: App {
    @State private var router: AppRouter

    init() {
        let router = AppRouter()
        _router = State(initialValue: router)
        // Intents with `openAppWhenRun` perform inside this process, so handing
        // the same instance to `AppDependencyManager` is what lets them move
        // the live UI rather than a router nobody is watching.
        AppDependencyManager.shared.add(dependency: router)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $router.selectedScreen) {
                Tab("Today", systemImage: "questionmark.circle", value: AppRouter.Screen.today) {
                    TodayView()
                }
                Tab("Archive", systemImage: "clock.arrow.circlepath", value: AppRouter.Screen.archive) {
                    ArchiveView()
                }
                Tab("Statistics", systemImage: "chart.bar", value: AppRouter.Screen.statistics) {
                    StatsView()
                }
                Tab("Settings", systemImage: "gearshape", value: AppRouter.Screen.settings) {
                    SettingsView()
                }
            }
            .environment(router)
        }
    }
}
