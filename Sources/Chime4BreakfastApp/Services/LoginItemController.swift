import Foundation
import ServiceManagement

/// Wraps `SMAppService` so the app can register itself as a login item. Reflects
/// live system state rather than a stored preference, since the user can also
/// toggle this from System Settings.
@MainActor
protocol LoginItemControlling: AnyObject {
    func isEnabled() -> Bool
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
final class LoginItemController: LoginItemControlling {
    func isEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
