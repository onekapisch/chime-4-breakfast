import XCTest
@testable import Chime4BreakfastApp

final class MessageClassifierTests: XCTestCase {
    private let classifier = MessageClassifier()

    func test_question_mark_becomes_attention() {
        XCTAssertEqual(classifier.classify("Which sound do you want?"), .attention)
    }

    func test_action_phrase_becomes_attention() {
        XCTAssertEqual(classifier.classify("Choose one and let me know."), .attention)
    }

    func test_regular_summary_becomes_completion() {
        XCTAssertEqual(classifier.classify("The build finished and all checks passed."), .completion)
    }

    func test_phrase_substring_does_not_false_positive() {
        XCTAssertEqual(classifier.classify("I approved the changes and shipped them."), .completion)
        XCTAssertEqual(classifier.classify("The pipeline is now unblocked."), .completion)
    }

    func test_whole_word_phrase_still_matches() {
        XCTAssertEqual(classifier.classify("Please approve before I continue."), .attention)
    }

    func test_custom_phrase_triggers_attention() {
        XCTAssertEqual(
            classifier.classify("Your review is required before merge.", extraPhrases: ["review is required"]),
            .attention
        )
    }

    func test_custom_phrase_does_not_affect_unrelated_text() {
        XCTAssertEqual(
            classifier.classify("The deploy is complete.", extraPhrases: ["review is required"]),
            .completion
        )
    }
}
