import XCTest
@testable import Chime4BreakfastApp

final class ConversationWindowSelectorTests: XCTestCase {
    func test_prefers_assistant_conversation_over_richer_settings_window() {
        let settings = [
            "Settings", "Appearance", "Keyboard shortcuts", "General", "Notifications",
            "Theme options", "Advanced preferences", "Privacy and security", "Reset settings"
        ]
        let conversation = [
            "You", "Please review the release notes.", "Codex",
            "The release notes are ready. Would you like me to open a pull request?", "Copy", "Edit"
        ]

        let selected = ConversationWindowSelector().select(from: [settings, conversation])

        XCTAssertEqual(selected, conversation)
    }

    func test_returns_nil_when_every_window_looks_like_navigation() {
        let selected = ConversationWindowSelector().select(from: [
            ["New chat", "Search", "History", "Projects"],
            ["Settings", "Appearance", "Notifications"]
        ])

        XCTAssertNil(selected)
    }
}
