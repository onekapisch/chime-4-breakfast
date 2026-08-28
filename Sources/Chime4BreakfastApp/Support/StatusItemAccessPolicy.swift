import Foundation

/// Keeps an agent application reachable until the user has successfully opened
/// its status item at least once on the current Mac.
enum StatusItemAccessPolicy {
    static func needsRecoveryPanel(
        hasConfirmedStatusItemAccess: Bool,
        statusItemIsHostedOnScreen: Bool
    ) -> Bool {
        !hasConfirmedStatusItemAccess || !statusItemIsHostedOnScreen
    }
}
