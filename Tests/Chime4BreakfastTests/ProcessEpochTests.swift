import XCTest
@testable import Chime4BreakfastApp

final class ProcessEpochTests: XCTestCase {
    func test_new_pid_invalidates_previous_scan_epoch() {
        var epochs = ProcessEpochs()
        let first = epochs.observe(app: .codex, pid: 100)

        let second = epochs.observe(app: .codex, pid: 200)

        XCTAssertTrue(first.didChange)
        XCTAssertTrue(second.didChange)
        XCTAssertFalse(epochs.accepts(app: .codex, pid: 100, epoch: first.epoch))
        XCTAssertTrue(epochs.accepts(app: .codex, pid: 200, epoch: second.epoch))
    }
}
