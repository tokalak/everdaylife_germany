import Foundation
import UserNotifications

/// Abstraction over local-notification permission so the onboarding flow (P2-03)
/// and later reminder scheduling (P3-06/08) can be unit-tested without touching
/// the real system permission prompt.
///
/// Seeds `Core/Notifications` (architecture §2.2). Scheduling APIs are added
/// here as the Vault/Calendar reminder features land.
protocol NotificationAuthorizing: Sendable {
    /// Requests permission to show local notifications. Returns whether it was
    /// granted. Never throws — onboarding proceeds regardless of the answer.
    func requestAuthorization() async -> Bool

    /// The current authorization status (e.g. to reflect state in Settings).
    func authorizationStatus() async -> UNAuthorizationStatus
}

/// Production implementation backed by `UNUserNotificationCenter`.
struct SystemNotificationAuthorizer: NotificationAuthorizing {
    /// Permission options requested — alerts and sound for deadline reminders;
    /// no badge (we don't drive a badge count in v1).
    private let options: UNAuthorizationOptions = [.alert, .sound]

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: options)
        } catch {
            // A failed request is treated as "not granted"; onboarding continues.
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current()
            .notificationSettings().authorizationStatus
    }
}
