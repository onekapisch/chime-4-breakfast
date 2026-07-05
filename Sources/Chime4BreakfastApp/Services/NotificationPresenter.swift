import Foundation
import UserNotifications

/// Interface for local banner notification delivery, isolated so AppState can
/// be tested without touching Notification Center.
@MainActor
protocol NotificationPresenting: AnyObject {
    func requestAuthorizationIfNeeded()
    func present(title: String, body: String)
}

/// Posts optional banner notifications alongside the audible/visual cues. Local
/// notifications only; no payload leaves the machine.
@MainActor
final class NotificationPresenter: NotificationPresenting {
    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                chimeDebugLog("NOTIFICATION authorization.error=\(error.localizedDescription)")
            } else {
                chimeDebugLog("NOTIFICATION authorization.granted=\(granted)")
            }
        }
    }

    func present(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                chimeDebugLog("NOTIFICATION present.error=\(error.localizedDescription)")
            }
        }
    }
}
