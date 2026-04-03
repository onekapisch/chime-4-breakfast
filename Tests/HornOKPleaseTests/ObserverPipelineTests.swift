import XCTest
@testable import HornOKPleaseApp

final class ObserverPipelineTests: XCTestCase {
    func test_observer_classifies_every_new_snapshot() {
        let observer = AppObserver(classifier: MessageClassifier())
        let snapshot = WindowSnapshot(
            app: .codex,
            message: "Which sound do you want?",
            fingerprint: "codex-1"
        )

        XCTAssertEqual(observer.process(snapshot)?.eventType, .attention)
        XCTAssertEqual(observer.process(snapshot)?.eventType, .attention)
    }
}
