import AppIntents
import CoreSpotlight
import SwiftUI

/// The host application.
///
/// M5 delivered the widget, and a widget extension can only ship inside an
/// app, so this entry point existed to give it one, with a placeholder body.
/// M6 fills it in with the app's four real screens, and M7 puts the tab
/// selection under ``AppRouter`` so that intents can steer it.
@main
struct KodKirintisiApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var router: AppRouter

    init() {
        // Before any screen reads progress. A no-op unless this is a debug
        // build launched with the screenshot flag — see ``DemoContent``.
        DemoContent.installIfRequested()

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
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                guard let id = SpotlightIndexer.puzzleID(from: activity) else { return }
                router.showArchivedPuzzle(id: id)
            }
        }
        // Not `.task`: the revealed set grows at local midnight, which usually
        // happens while the app is in the background, so re-indexing only at
        // launch would leave Spotlight a day behind for anyone who never
        // fully quits the app.
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task { await SpotlightIndexer.shared.reindex() }
        }
    }
}
