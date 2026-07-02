import XCTest
import SwiftUI
@testable import Chime4BreakfastApp

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

    func test_attention_snapshot_uses_persistent_attention_glow_when_user_was_away() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: quietPreferencesStore(),
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .claude,
            message: "Which option should I use for the release?",
            fingerprint: "claude-question",
            userWasAway: true
        ))

        XCTAssertEqual(glow.events, [.attention])
    }

    func test_completion_snapshot_uses_completion_flash_when_user_was_away() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: quietPreferencesStore(),
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .codex,
            message: "The implementation is complete and all checks pass.",
            fingerprint: "codex-complete",
            userWasAway: true
        ))

        XCTAssertEqual(glow.events, [.completion])
    }

    func test_preview_glow_prefers_codex_when_both_supported_apps_are_running() {
        XCTAssertEqual(AppState.preferredPreviewApp(from: Set<TargetApp>([.claude, .codex])), .codex)
    }

    func test_preview_glow_uses_claude_when_it_is_the_only_running_supported_app() {
        XCTAssertEqual(AppState.preferredPreviewApp(from: Set<TargetApp>([.claude])), .claude)
    }

    func test_preview_glow_defaults_to_codex_when_no_supported_apps_are_running() {
        XCTAssertEqual(AppState.preferredPreviewApp(from: Set<TargetApp>()), .codex)
    }

    func test_snapshot_does_not_glow_when_user_was_not_away() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: quietPreferencesStore(),
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .codex,
            message: "The implementation is complete and all checks pass.",
            fingerprint: "codex-visible",
            userWasAway: false
        ))

        XCTAssertEqual(glow.events, [])
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "Chime4BreakfastTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func quietPreferencesStore() -> PreferencesStore {
        let store = PreferencesStore(defaults: isolatedDefaults())
        var preferences = UserPreferences.defaultValue
        preferences.completionAlertsEnabled = false
        preferences.attentionAlertsEnabled = false
        store.preferences = preferences
        return store
    }
}

@MainActor
private final class TestAccessibilityProbe: AccessibilityProbing {
    var statusToSend: (Bool, Set<TargetApp>)?
    private var snapshotHandler: AccessibilitySnapshotHandler?

    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    ) {
        self.snapshotHandler = snapshotHandler
        if let statusToSend {
            statusHandler(statusToSend.0, statusToSend.1)
        }
    }

    func stop() {}

    func captureDiagnostics(for apps: [TargetApp]) -> String { "" }

    func emit(_ snapshot: WindowSnapshot) {
        snapshotHandler?(snapshot)
    }
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

@MainActor
private final class TestScreenGlowPresenter: ScreenGlowPresenting {
    enum Event: Equatable {
        case completion
        case attention
        case preview
        case dismiss
    }

    private(set) var events: [Event] = []

    func flashCompletion(color: Color, intensity: Double) {
        events.append(.completion)
    }

    func showAttention(color: Color, intensity: Double) {
        events.append(.attention)
    }

    func preview(color: Color, intensity: Double) {
        events.append(.preview)
    }

    func dismiss() {
        events.append(.dismiss)
    }
}
