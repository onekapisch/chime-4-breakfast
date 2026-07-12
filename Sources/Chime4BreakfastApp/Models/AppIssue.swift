import Foundation

/// A recoverable operation failure that must be visible in the menu bar UI.
enum AppIssue: Equatable {
    case loginItem(String)
    case diagnosticsWrite
    case notificationPermission

    var message: String {
        switch self {
        case let .loginItem(detail):
            detail
        case .diagnosticsWrite:
            "Diagnostics could not be saved. Check that your Desktop is available."
        case .notificationPermission:
            "Notification banners are enabled, but macOS permission was not granted."
        }
    }

    var iconName: String {
        switch self {
        case .loginItem:
            "person.crop.circle.badge.exclamationmark"
        case .diagnosticsWrite:
            "doc.badge.exclamationmark"
        case .notificationPermission:
            "bell.badge.exclamationmark"
        }
    }
}
