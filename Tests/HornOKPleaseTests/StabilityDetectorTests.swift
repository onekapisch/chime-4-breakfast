import XCTest
@testable import HornOKPleaseApp

final class StabilityDetectorTests: XCTestCase {
    func test_emits_after_message_stops_changing() {
        let detector = StabilityDetector(settleDuration: 2.0)

        detector.record(candidate: "Draft", at: 0)
        detector.record(candidate: "Draft complete", at: 1)

        XCTAssertNil(detector.stableCandidate(at: 2.5))
        XCTAssertEqual(detector.stableCandidate(at: 3.1), "Draft complete")
    }

    func test_same_message_can_emit_again_after_intermediate_change() {
        let detector = StabilityDetector(settleDuration: 1.0)

        detector.record(candidate: "Same text", at: 0)
        XCTAssertEqual(detector.stableCandidate(at: 1.1), "Same text")
        XCTAssertNil(detector.stableCandidate(at: 1.5))

        detector.record(candidate: "Different text", at: 2.0)
        XCTAssertEqual(detector.stableCandidate(at: 3.1), "Different text")

        detector.record(candidate: "Same text", at: 4.0)
        XCTAssertEqual(detector.stableCandidate(at: 5.1), "Same text")
    }
}
