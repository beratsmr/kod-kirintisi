import SwiftUI
import UIKit
import WidgetKit

/// The fourth tab: notification preferences and a way to start over.
///
/// There were category toggles here too, which wrote a preference nothing
/// read — ``DailyPuzzleSelector`` schedules over the whole bank and has no
/// way to honour an exclusion. Honouring one would have meant giving up the
/// property the schedule is built on, that the puzzle of a day is a function
/// of the date alone (`docs/SPEC.md` §8): the day-to-puzzle mapping would
/// then depend on a setting, and flipping it would rewrite the archive. A
/// switch that does nothing is worse than no switch, so they are gone.
struct SettingsView: View {
    @Environment(\.openURL) private var openURL

    @AppStorage("settings.notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("settings.notificationMinuteOfDay") private var notificationMinuteOfDay = 9 * 60

    @State private var isShowingResetConfirmation = false
    @State private var isShowingPermissionAlert = false
    @State private var resetError: String?

    var body: some View {
        NavigationStack {
            Form {
                notificationSection
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
                Text("Allow notifications for Codestion in Settings to get a daily reminder.")
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
            // Same reason as answering: the widget serves its cached timeline
            // and cannot see that the container was emptied underneath it. Left
            // out, the Home Screen keeps showing an answer the user has just
            // asked the app to forget.
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.dailyPuzzle)
        } catch {
            resetError = "Something went wrong. Please try again."
        }
    }
}
