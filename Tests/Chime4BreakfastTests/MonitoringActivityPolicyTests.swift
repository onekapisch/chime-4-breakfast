import XCTest
@testable import Chime4BreakfastApp

final class MonitoringActivityPolicyTests: XCTestCase {
    func test_activity_is_only_needed_during_generation_or_confirmation() {
        XCTAssertFalse(MonitoringActivityPolicy.requiresAppNapExemption(hasActiveDetection: false))
        XCTAssertTrue(MonitoringActivityPolicy.requiresAppNapExemption(hasActiveDetection: true))
    }
}
