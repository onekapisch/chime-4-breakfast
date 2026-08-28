import XCTest
@testable import Chime4BreakfastApp

final class StatusItemHostValidatorTests: XCTestCase {
    private let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 876)

    func test_offscreen_status_item_frame_is_not_a_usable_menu_bar_host() {
        let offscreenFrame = CGRect(x: 0, y: -4, width: 22.5, height: 31.5)

        XCTAssertFalse(
            StatusItemHostValidator.isHosted(
                statusItemFrame: offscreenFrame,
                screenFrame: screenFrame,
                visibleFrame: visibleFrame
            )
        )
    }

    func test_frame_in_menu_bar_band_is_a_usable_host() {
        let menuBarFrame = CGRect(x: 1200, y: 876, width: 22.5, height: 24)

        XCTAssertTrue(
            StatusItemHostValidator.isHosted(
                statusItemFrame: menuBarFrame,
                screenFrame: screenFrame,
                visibleFrame: visibleFrame
            )
        )
    }

    func test_unconfirmed_status_item_access_requires_recovery() {
        XCTAssertTrue(
            StatusItemAccessPolicy.needsRecoveryPanel(
                hasConfirmedStatusItemAccess: false,
                statusItemIsHostedOnScreen: true
            )
        )
    }

    func test_confirmed_onscreen_status_item_does_not_require_recovery() {
        XCTAssertFalse(
            StatusItemAccessPolicy.needsRecoveryPanel(
                hasConfirmedStatusItemAccess: true,
                statusItemIsHostedOnScreen: true
            )
        )
    }

    func test_confirmed_but_offscreen_status_item_requires_recovery() {
        XCTAssertTrue(
            StatusItemAccessPolicy.needsRecoveryPanel(
                hasConfirmedStatusItemAccess: true,
                statusItemIsHostedOnScreen: false
            )
        )
    }
}
