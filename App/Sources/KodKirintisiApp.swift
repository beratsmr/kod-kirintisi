import SwiftUI

/// The host application.
///
/// M5 delivers the widget, and a widget extension can only ship inside an app,
/// so this entry point exists to give it one. The real screens — Today, Archive,
/// Statistics, Settings — arrive in M6 and replace the placeholder below.
@main
struct KodKirintisiApp: App {
    var body: some Scene {
        WindowGroup {
            // `verbatim` on purpose: this is the product name, which is not
            // translated, and no user-facing copy exists yet to localise.
            Text(verbatim: "Kod Kırıntısı")
                .font(.largeTitle.weight(.semibold))
        }
    }
}
