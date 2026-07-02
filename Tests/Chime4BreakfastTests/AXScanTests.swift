import XCTest
@testable import Chime4BreakfastApp

final class AXScanTests: XCTestCase {
    func test_detects_stop_and_generation_status_labels() {
        XCTAssertTrue(AXScan.indicatesGenerating(["Stop"]))
        XCTAssertTrue(AXScan.indicatesGenerating(["Stop generating response"]))
        XCTAssertTrue(AXScan.indicatesGenerating(["Thinking..."]))
        XCTAssertTrue(AXScan.indicatesGenerating(["Responding…"]))
        XCTAssertTrue(AXScan.indicatesGenerating(["Generating"]))
    }

    func test_does_not_treat_normal_sentence_as_generation_status() {
        XCTAssertFalse(AXScan.indicatesGenerating(["Please stop after this step is complete."]))
        XCTAssertFalse(AXScan.indicatesGenerating(["The implementation finished generating assets."]))
    }
}
