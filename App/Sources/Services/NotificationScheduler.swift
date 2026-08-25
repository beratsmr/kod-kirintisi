import Foundation
import os
import UserNotifications

/// Schedules the one daily reminder the app sends.
///
/// The copy is deliberately generic — "today's puzzle is ready", never the
/// question itself. A repeating trigger is registered once and fired by the
/// system for months, so any puzzle text baked in would be whatever was
/// current on the day the user flipped the switch, and showing it on the lock
/// screen would give the day away before the widget does.
///
/// One pending request, replaced rather than added to, so changing the
/// reminder time cannot leave an old one behind.
struct NotificationScheduler: Sendable {
    enum Failure: Error {
        /// The user has not granted permission, so nothing was scheduled.
        case authorizationDenied
    }

    static let shared = NotificationScheduler()

    private static let requestIdentifier = "com.beratsumer.kodkirintisi.daily-reminder"

    private static let logger = Logger(
        subsystem: "com.beratsumer.kodkirintisi",
        category: "notifications"
    )

    /// Fetched per use rather than stored: `UNUserNotificationCenter` is not
    /// `Sendable`, so holding one would keep this type from being. There is
    /// nothing to inject anyway — the class is final with no protocol behind
    /// it, so a test double is not on offer either way.
    private var center: UNUserNotificationCenter {
        .current()
    }

    /// Asks for permission if it has not been asked for yet, then schedules
    /// the reminder to repeat daily at `minuteOfDay` minutes past midnight.
    ///
    /// - Throws: ``Failure/authorizationDenied`` when the user says no, or has
    ///   said no before — the system does not prompt twice, so this is also
    ///   the answer for someone who turned notifications off in Settings later.
    func enable(atMinuteOfDay minuteOfDay: Int) async throws {
        guard try await center.requestAuthorization(options: [.alert, .sound, .badge]) else {
            throw Failure.authorizationDenied
        }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Kod Kırıntısı")
        content.body = String(localized: "Today's puzzle is ready.")
        content.sound = .default

        var components = DateComponents()
        components.hour = minuteOfDay / 60
        components.minute = minuteOfDay % 60

        disable()
        try await center.add(UNNotificationRequest(
            identifier: Self.requestIdentifier,
            content: content,
            // Matching on hour and minute alone is what makes this daily, and
            // it follows the device's calendar — so it stays at the user's
            // chosen wall-clock time across a time zone change.
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        ))
        Self.logger.debug("Daily reminder set for \(minuteOfDay, privacy: .public) minutes past midnight.")
    }

    /// Cancels the reminder. Safe to call when none is pending.
    func disable() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestIdentifier])
    }
}
