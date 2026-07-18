import ApplicationServices

@MainActor
protocol AccessibilityAuthorizing: AnyObject {
    func isTrusted() -> Bool
}

@MainActor
final class AccessibilityAuthorizer: AccessibilityAuthorizing {
    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }
}
