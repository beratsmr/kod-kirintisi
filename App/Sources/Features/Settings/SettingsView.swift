import KodKirintisiCore
import SwiftUI
import UIKit

/// The fourth tab: notification preferences, which categories are wanted,
/// and a way to start over.
///
/// The category toggles are UI-only: they persist a preference that nothing
/// reads, because ``DailyPuzzleSelector`` schedules over the whole bank and
/// has no way to honour an exclusion. That was a deliberate scope call, not
/// an oversight. The notification switches, UI-only in M6, now drive
/// ``NotificationScheduler``.
struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("settings.notificationMinuteOfDay") private var notificationMinuteOfDay = 9 * 60
    @AppStorage("settings.excludedCategories") private var excludedCategoriesRaw = ""

    @State private var isShowingResetConfirmation = false
    @State private var isShowingPermissionAlert = false
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
            .alert("Notifications Are Turned Off", isPresented: $isShowingPermissionAlert) {
                Button("Open Settings") { openSystemSettings() }
                Button("Not Now", role: .cancel) {}
            } message: {
                Text("Allow notifications for Kod Kırıntısı in Settings to get a daily reminder.")
            }
            .onChange(of: notificationsEnabled) { _, isEnabled in
                Task { await applyReminderSetting(isEnabled: isEnabled) }
            }
            .onChange(of: notificationMinuteOfDay) { _, _ in
                Task { await applyReminderSetting(isEnabled: notificationsEnabled) }
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

    /// Keeps the pending reminder in step with the two switches above.
    ///
    /// The toggle is put back to off when permission is refused, so the UI
    /// never claims a reminder is coming that the system will not deliver.
    /// Writing to `@AppStorage` re-enters this through `onChange`, but with
    /// `isEnabled` false that path only cancels — it cannot loop.
    private func applyReminderSetting(isEnabled: Bool) async {
        guard isEnabled else {
            NotificationScheduler.shared.disable()
            return
        }
        do {
            try await NotificationScheduler.shared.enable(atMinuteOfDay: notificationMinuteOfDay)
        } catch {
            notificationsEnabled = false
            isShowingPermissionAlert = true
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func resetProgress() async {
        do {
            try await DailyPuzzleService.shared.resetProgress()
        } catch {
            resetError = "Something went wrong. Please try again."
        }
    }
}
