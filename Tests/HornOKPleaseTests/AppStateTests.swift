import XCTest
@testable import HornOKPleaseApp

@MainActor
final class AppStateTests: XCTestCase {
    func test_attention_state_uses_alert_symbol() {
        let state = AppState()
        state.status = .attention

        XCTAssertEqual(state.menuBarSymbolName, "bell.badge.fill")
    }

    func test_start_monitoring_requests_accessibility_prompt_once_when_not_trusted() {
        let probe = TestAccessibilityProbe()
        let authorizer = TestAccessibilityAuthorizer(isTrusted: false)
        let state = AppState(
            accessibilityProbe: probe,
            accessibilityAuthorizer: authorizer
        )

        state.startMonitoringIfNeeded()
        state.restartMonitoring()

        XCTAssertEqual(authorizer.requestPromptCallCount, 1)
        XCTAssertEqual(state.status, .permissionRequired)
    }

    func test_status_detail_reports_waiting_when_no_supported_apps_are_running() {
        let probe = TestAccessibilityProbe()
        probe.statusToSend = (true, [])
        let state = AppState(
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true)
        )

        state.startMonitoringIfNeeded()

        XCTAssertEqual(state.statusDetail, "Waiting for Codex or Claude to be open.")
    }

    func test_status_detail_reports_detected_apps() {
        let probe = TestAccessibilityProbe()
        probe.statusToSend = (true, [.codex])
        let state = AppState(
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true)
        )

        state.startMonitoringIfNeeded()

        XCTAssertEqual(state.statusDetail, "Watching Codex for finished responses.")
    }
}

@MainActor
private final class TestAccessibilityProbe: AccessibilityProbing {
    var statusToSend: (Bool, Set<TargetApp>)?

    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    ) {
        if let statusToSend {
            statusHandler(statusToSend.0, statusToSend.1)
        }
    }

    func stop() {}
}

@MainActor
private final class TestAccessibilityAuthorizer: AccessibilityAuthorizing {
    private let isTrustedValue: Bool
    private(set) var requestPromptCallCount = 0

    init(isTrusted: Bool) {
        self.isTrustedValue = isTrusted
    }

    func isTrusted() -> Bool {
        isTrustedValue
    }

    func requestPrompt() {
        requestPromptCallCount += 1
    }
}
