import XCTest
@testable import Chime4BreakfastApp

final class DeliveryPolicyTests: XCTestCase {
    func test_quiet_hours_sound_only_preserves_glow_and_banner() {
        let decision = DeliveryPolicy.decide(eventEnabled: true, isAway: true, glowEnabled: true, bannersEnabled: true, quietHours: .soundOnly)

        XCTAssertFalse(decision.playsSound)
        XCTAssertTrue(decision.showsGlow)
        XCTAssertTrue(decision.showsBanner)
    }

    func test_quiet_hours_all_signals_mutes_every_output() {
        let decision = DeliveryPolicy.decide(eventEnabled: true, isAway: true, glowEnabled: true, bannersEnabled: true, quietHours: .allSignals)

        XCTAssertEqual(decision, .muted)
    }
}
