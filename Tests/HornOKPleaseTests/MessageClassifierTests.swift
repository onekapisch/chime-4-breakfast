import XCTest
@testable import HornOKPleaseApp

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
}
