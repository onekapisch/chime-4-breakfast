import Foundation
@preconcurrency import UserNotifications

/// Interface for local banner notification delivery, isolated so AppState can
/// be tested without touching Notification Center.
@MainActor
protocol NotificationPresenting: AnyObject {
    func requestAuthorizationIfNeeded()
    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void)
    func present(title: String, body: String)
}

extension NotificationPresenting {
    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void) {
        requestAuthorizationIfNeeded()
        onResult(true)
    }
}

/// Posts optional banner notifications alongside the audible/visual cues. Local
/// notifications only; no payload leaves the machine.
@MainActor
final class NotificationPresenter: NotificationPresenting {
    private var hasRequestedAuthorization = false

    func requestAuthorizationIfNeeded() {
        requestAuthorizationIfNeeded(onResult: { _ in })
    }

    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                Task { @MainActor in onResult(true) }
            case .denied:
                Task { @MainActor in onResult(false) }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error {
                        chimeDebugLog("NOTIFICATION authorization.error=\(error.localizedDescription)")
                    } else {
                        chimeDebugLog("NOTIFICATION authorization.granted=\(granted)")
                    }
                    Task { @MainActor in onResult(granted) }
                }
            @unknown default:
                Task { @MainActor in onResult(false) }
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
