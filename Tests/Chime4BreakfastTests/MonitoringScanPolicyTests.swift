import XCTest
@testable import Chime4BreakfastApp

final class MonitoringScanPolicyTests: XCTestCase {
    func test_idle_polling_uses_a_low_frequency_recovery_interval() {
        XCTAssertEqual(MonitoringScanPolicy.pollInterval(hasActiveFinishEdge: false), 30)
    }

    func test_active_polling_stays_fast_while_a_finish_edge_is_tracked() {
        XCTAssertEqual(MonitoringScanPolicy.pollInterval(hasActiveFinishEdge: true), 1)
    }

    func test_idle_accessibility_events_are_rate_limited() {
        XCTAssertEqual(MonitoringScanPolicy.eventCooldown(hasActiveFinishEdge: false), 2)
    }

    func test_active_accessibility_events_keep_the_finish_confirmation_responsive() {
        XCTAssertEqual(MonitoringScanPolicy.eventCooldown(hasActiveFinishEdge: true), 0.5)
    }

    func test_message_extraction_only_runs_after_a_generation_edge() {
        XCTAssertFalse(MonitoringScanPolicy.shouldExtractMessage(
            hasActiveFinishEdge: false,
            generating: false
        ))
        XCTAssertFalse(MonitoringScanPolicy.shouldExtractMessage(
            hasActiveFinishEdge: true,
            generating: true
        ))
        XCTAssertTrue(MonitoringScanPolicy.shouldExtractMessage(
            hasActiveFinishEdge: true,
            generating: false
        ))
    }

    func test_active_poll_only_rescans_the_app_with_a_pending_finish_edge() {
        let now = Date()

        XCTAssertTrue(MonitoringScanPolicy.shouldScan(
            hasActiveFinishEdge: true,
            isEventDriven: false,
            lastIdleScanAt: now,
            now: now
        ))
        XCTAssertFalse(MonitoringScanPolicy.shouldScan(
            hasActiveFinishEdge: false,
            isEventDriven: false,
            lastIdleScanAt: now.addingTimeInterval(-29),
            now: now
        ))
        XCTAssertTrue(MonitoringScanPolicy.shouldScan(
            hasActiveFinishEdge: false,
            isEventDriven: false,
            lastIdleScanAt: now.addingTimeInterval(-30),
            now: now
        ))
    }

    func test_accessibility_event_always_scans_its_target_immediately() {
        let now = Date()

        XCTAssertTrue(MonitoringScanPolicy.shouldScan(
            hasActiveFinishEdge: false,
            isEventDriven: true,
            lastIdleScanAt: now,
            now: now
        ))
    }
}
