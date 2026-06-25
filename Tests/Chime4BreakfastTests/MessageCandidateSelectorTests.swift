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
}
