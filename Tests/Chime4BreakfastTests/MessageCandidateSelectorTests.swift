import XCTest
@testable import Chime4BreakfastApp

final class MessageCandidateSelectorTests: XCTestCase {
    private let selector = MessageCandidateSelector()

    func test_prefers_recent_sentence_over_short_chrome_labels() {
        let strings = [
            "Search",
            "Projects",
            "Use Cmd + I to generate code",
            "I finished the pass and the app is ready for the next step."
        ]

        XCTAssertEqual(selector.select(from: strings), "I finished the pass and the app is ready for the next step.")
    }

    func test_ignores_short_navigation_entries() {
        let strings = [
            "New chat",
            "Open",
            "Settings",
            "The build completed successfully and the watcher is running."
        ]

        XCTAssertEqual(selector.select(from: strings), "The build completed successfully and the watcher is running.")
    }

    func test_prefers_latest_assistant_turn_over_longer_user_prompt() {
        let userPrompt = """
        Please inspect the complete landing page implementation, verify the mobile layout, \
        check the animation behavior, and tell me exactly what still needs to change before launch?
        """
        let assistantReply = "The mobile layout is fixed. Build and tests pass."

        let strings = [
            "Projects",
            "You",
            userPrompt,
            "Edit",
            "Claude",
            assistantReply,
            "Copy",
            "Good response",
            "Bad response"
        ]

        XCTAssertEqual(selector.select(from: strings), assistantReply)
    }

    func test_prefers_codex_assistant_turn_after_user_prompt() {
        let strings = [
            "New chat",
            "You",
            "Can you audit the subscription flow and explain every remaining blocker?",
            "Edit",
            "Codex",
            "The subscription flow now validates products, handles restore, and reports missing configuration.",
            "Copy"
        ]

        XCTAssertEqual(
            selector.select(from: strings),
            "The subscription flow now validates products, handles restore, and reports missing configuration."
        )
    }
}
