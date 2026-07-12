import AppKit
import Foundation
@preconcurrency import UserNotifications

enum NotificationActionPayload {
    static let sourceAppKey = "sourceApp"
    static let openSourceActionIdentifier = "open-source-app"

    static func userInfo(for app: TargetApp) -> [AnyHashable: Any] {
        [sourceAppKey: app.rawValue]
    }

    static func sourceApp(from userInfo: [AnyHashable: Any]) -> TargetApp? {
        guard let rawValue = userInfo[sourceAppKey] as? String else { return nil }
        return TargetApp(rawValue: rawValue)
    }

    static func categoryIdentifier(for app: TargetApp) -> String {
        "app.chime4breakfast.source.\(app.rawValue)"
    }
}

/// Interface for local banner notification delivery, isolated so AppState can
/// be tested without touching Notification Center.
@MainActor
protocol NotificationPresenting: AnyObject {
    func requestAuthorizationIfNeeded()
    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void)
    func present(title: String, body: String, sourceApp: TargetApp)
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
final class NotificationPresenter: NSObject, NotificationPresenting {
    private var hasRequestedAuthorization = false
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        center.setNotificationCategories(Self.notificationCategories)
    }

    func requestAuthorizationIfNeeded() {
        requestAuthorizationIfNeeded(onResult: { _ in })
    }

    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        let notificationCenter = center
        notificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                Task { @MainActor in onResult(true) }
            case .denied:
                Task { @MainActor in onResult(false) }
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
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

    func present(title: String, body: String, sourceApp: TargetApp) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = NotificationActionPayload.categoryIdentifier(for: sourceApp)
        content.userInfo = NotificationActionPayload.userInfo(for: sourceApp)

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

    private static let notificationCategories: Set<UNNotificationCategory> = Set(TargetApp.allCases.map { app in
        let action = UNNotificationAction(
            identifier: NotificationActionPayload.openSourceActionIdentifier,
            title: "Open \(app.displayName)",
            options: [.foreground]
        )
        return UNNotificationCategory(
            identifier: NotificationActionPayload.categoryIdentifier(for: app),
            actions: [action],
            intentIdentifiers: [],
            options: []
        )
    })

    private func activate(_ app: TargetApp) {
        guard let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier).first else {
            chimeDebugLog("NOTIFICATION action target-not-running=\(app.rawValue)")
            return
        }

        runningApp.activate()
        chimeDebugLog("NOTIFICATION action opened=\(app.rawValue)")
    }
}

extension NotificationPresenter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        let actionIdentifier = response.actionIdentifier
        guard actionIdentifier == NotificationActionPayload.openSourceActionIdentifier
            || actionIdentifier == UNNotificationDefaultActionIdentifier,
            let app = NotificationActionPayload.sourceApp(from: response.notification.request.content.userInfo)
        else {
            return
        }

        Task { @MainActor [weak self] in
            self?.activate(app)
        }
    }
}
