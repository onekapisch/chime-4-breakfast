import Foundation

/// Keeps App Nap disabled only while a finish edge is actively being tracked.
enum MonitoringActivityPolicy {
    static func requiresAppNapExemption(hasActiveDetection: Bool) -> Bool {
        hasActiveDetection
    }
}
