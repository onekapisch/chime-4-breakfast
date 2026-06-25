import ApplicationServices
import Foundation

@MainActor
protocol AccessibilityAuthorizing: AnyObject {
    func isTrusted() -> Bool
    func requestPrompt()
}

@MainActor
final class AccessibilityAuthorizer: AccessibilityAuthorizing {
    private let promptOptionKey = "AXTrustedCheckOptionPrompt"

    func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestPrompt() {
        let options = [promptOptionKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
