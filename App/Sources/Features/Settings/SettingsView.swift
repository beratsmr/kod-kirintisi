import KodKirintisiCore
import SwiftUI

/// The fourth tab: notification preferences, which categories are wanted,
/// and a way to start over.
///
/// The notification toggle/time and the category toggles are UI-only for
/// now — they persist a preference but nothing reads it yet. Local
/// notifications are wired up in M7; category filtering has no consumer at
/// all yet, since ``DailyPuzzleSelector`` schedules over the whole bank.
/// Both were a deliberate scope call, not an oversight.
struct SettingsView: View {
    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("settings.notificationMinuteOfDay") private var notificationMinuteOfDay = 9 * 60
    @AppStorage("settings.excludedCategories") private var excludedCategoriesRaw = ""

    @State private var isShowingResetConfirmation = false
    @State private var resetError: String?

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
                categorySection
                resetSection
                aboutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset All Progress?",
                isPresented: $isShowingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Progress", role: .destructive) {
                    Task { await resetProgress() }
                }
            } message: {
                Text("This clears every answered puzzle. Your daily schedule stays the same.")
            }
            .alert("Couldn't Reset Progress", isPresented: isShowingResetError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resetError ?? "")
            }
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("Daily Reminder", isOn: $notificationsEnabled)
            if notificationsEnabled {
                DatePicker("Reminder Time", selection: notificationTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Notifications")
        }
    }

    private var categorySection: some View {
        Section {
            ForEach(PuzzleCategory.allCases, id: \.self) { category in
                Toggle(isOn: binding(for: category)) {
                    Text(category.badgeName)
                }
            }
        } header: {
            Text("Categories")
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset Progress", role: .destructive) {
                isShowingResetConfirmation = true
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: appVersion)
        } header: {
            Text("About")
        }
    }

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: notificationMinuteOfDay / 60,
                    minute: notificationMinuteOfDay % 60,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                notificationMinuteOfDay = (components.hour ?? 9) * 60 + (components.minute ?? 0)
            }
        )
    }

    private var excludedCategories: Set<PuzzleCategory> {
        Set(excludedCategoriesRaw.split(separator: ",").compactMap { PuzzleCategory(rawValue: String($0)) })
    }

    private func binding(for category: PuzzleCategory) -> Binding<Bool> {
        Binding(
            get: { !excludedCategories.contains(category) },
            set: { included in
                var excluded = excludedCategories
                if included {
                    excluded.remove(category)
                } else {
                    excluded.insert(category)
                }
                excludedCategoriesRaw = excluded.map(\.rawValue).sorted().joined(separator: ",")
            }
        )
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(shortVersion) (\(buildNumber))"
    }

    private var isShowingResetError: Binding<Bool> {
        Binding(get: { resetError != nil }, set: {
            if !$0 {
                resetError = nil
            }
        })
    }

    private func resetProgress() async {
        do {
            try await DailyPuzzleService.shared.resetProgress()
        } catch {
            resetError = "Something went wrong. Please try again."
        }
    }
}
