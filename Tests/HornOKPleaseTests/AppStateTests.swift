import XCTest
@testable import HornOKPleaseApp

@MainActor
final class AppStateTests: XCTestCase {
    func test_attention_state_uses_alert_symbol() {
        let state = AppState()
        state.status = .attention

        XCTAssertEqual(state.menuBarSymbolName, "bell.badge.fill")
    }
}
