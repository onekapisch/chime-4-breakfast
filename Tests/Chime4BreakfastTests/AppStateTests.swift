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

    func test_startup_requests_notification_authorization_when_saved_preference_is_enabled() {
        let notifications = TestNotificationPresenter()

        _ = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.notificationsEnabled = true
            },
            notificationPresenter: notifications
        )

        XCTAssertEqual(notifications.authorizationRequestCount, 1)
    }

    func test_notification_permission_denial_is_exposed_to_the_popover() {
        let notifications = TestNotificationPresenter(authorizationGranted: false)

        let state = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.notificationsEnabled = true
            },
            notificationPresenter: notifications
        )

        XCTAssertEqual(state.issue, .notificationPermission)
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

    func test_attention_snapshot_uses_attention_glow_when_user_was_away() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            soundEngine: TestSoundPlayer(),
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
            preferencesStore: isolatedPreferencesStore(),
            soundEngine: TestSoundPlayer(),
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

    func test_preview_glow_accepts_an_explicit_source_app() {
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            screenGlowController: glow
        )

        state.previewGlow(for: .claude)

        XCTAssertEqual(glow.events, [.preview])
    }

    func test_setting_glow_intensity_updates_an_active_preview() {
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            soundEngine: TestSoundPlayer(),
            accessibilityProbe: TestAccessibilityProbe(),
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.setGlowIntensity(0.2)

        XCTAssertEqual(state.preferences.glowIntensity, 0.2, accuracy: 0.0001)
        XCTAssertEqual(glow.updatedIntensities, [0.2])
    }

    func test_snapshot_does_not_glow_when_user_was_not_away() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            soundEngine: TestSoundPlayer(),
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

    func test_disabled_alerts_mute_both_sound_and_glow() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let sound = TestSoundPlayer()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.completionAlertsEnabled = false
            },
            soundEngine: sound,
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .codex,
            message: "The implementation is complete and all checks pass.",
            fingerprint: "codex-muted",
            userWasAway: true
        ))

        XCTAssertEqual(glow.events, [])
        XCTAssertEqual(sound.playedSoundIDs, [])
        XCTAssertEqual(state.recentActivity.first?.delivery, "Muted (completion alerts are off)")
    }

    func test_away_completion_plays_sound_and_glows_with_delivery_note() {
        let probe = TestAccessibilityProbe()
        let glow = TestScreenGlowPresenter()
        let sound = TestSoundPlayer()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            soundEngine: sound,
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true),
            screenGlowController: glow
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .codex,
            message: "The implementation is complete and all checks pass.",
            fingerprint: "codex-away",
            userWasAway: true
        ))

        XCTAssertEqual(glow.events, [.completion])
        XCTAssertEqual(sound.playedSoundIDs.count, 1)
        XCTAssertEqual(state.recentActivity.first?.delivery, "Sound + glow")
    }

    func test_per_app_sound_mode_plays_the_source_app_sound() {
        let probe = TestAccessibilityProbe()
        let sound = TestSoundPlayer()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.soundRoutingMode = .app
                preferences.setSoundID("tick", for: .codex)
                preferences.setSoundID("horn", for: .claude)
            },
            soundEngine: sound,
            accessibilityProbe: probe,
            accessibilityAuthorizer: TestAccessibilityAuthorizer(isTrusted: true)
        )

        state.startMonitoringIfNeeded()
        probe.emit(WindowSnapshot(
            app: .claude,
            message: "The implementation is complete and all checks pass.",
            fingerprint: "claude-provider-sound",
            userWasAway: false
        ))

        XCTAssertEqual(sound.playedSoundIDs, ["horn"])
    }

    func test_setup_test_plays_the_selected_app_completion_sound_and_glow() {
        let sound = TestSoundPlayer()
        let glow = TestScreenGlowPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.soundRoutingMode = .app
                preferences.setSoundID("tick", for: .codex)
                preferences.setSoundID("horn", for: .claude)
            },
            soundEngine: sound,
            screenGlowController: glow
        )

        state.runSetupTest(for: .claude)

        XCTAssertEqual(sound.playedSoundIDs, ["horn"])
        XCTAssertEqual(glow.events, [.completion])
        XCTAssertEqual(state.recentActivity.first?.sourceApp, .claude)
        XCTAssertEqual(state.recentActivity.first?.delivery, "Setup test · Sound + glow")
    }

    func test_setup_test_includes_a_source_aware_banner_when_enabled() {
        let notifications = TestNotificationPresenter()
        let state = AppState(
            preferencesStore: isolatedPreferencesStore { preferences in
                preferences.notificationsEnabled = true
            },
            notificationPresenter: notifications
        )

        state.runSetupTest(for: .codex)

        XCTAssertEqual(notifications.presented.map(\.sourceApp), [.codex])
    }

    func test_login_item_failure_is_exposed_to_the_popover() {
        let loginItem = TestLoginItemController(error: LoginItemTestError.registrationFailed)
        let state = AppState(
            preferencesStore: isolatedPreferencesStore(),
            loginItemController: loginItem
        )

        state.setLaunchAtLogin(true)

        XCTAssertEqual(state.issue, .loginItem("The login item could not be updated."))
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "Chime4BreakfastTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func isolatedPreferencesStore(mutate: (inout UserPreferences) -> Void = { _ in }) -> PreferencesStore {
        let store = PreferencesStore(defaults: isolatedDefaults())
        var preferences = UserPreferences.defaultValue
        mutate(&preferences)
        store.preferences = preferences
        return store
    }
}

private enum LoginItemTestError: LocalizedError {
    case registrationFailed

    var errorDescription: String? { "The login item could not be updated." }
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
private final class TestLoginItemController: LoginItemControlling {
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func isEnabled() -> Bool { false }

    func setEnabled(_ enabled: Bool) throws {
        if let error {
            throw error
        }
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
private final class TestSoundPlayer: SoundPlaying {
    private(set) var playedSoundIDs: [String] = []

    @discardableResult
    func play(soundID: String) -> Bool {
        playedSoundIDs.append(soundID)
        return true
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
    private(set) var updatedIntensities: [Double] = []

    func flashCompletion(color: Color, intensity: Double) {
        events.append(.completion)
    }

    func showAttention(color: Color, intensity: Double) {
        events.append(.attention)
    }

    func preview(color: Color, intensity: Double) {
        events.append(.preview)
    }

    func updatePreview(intensity: Double) {
        updatedIntensities.append(intensity)
    }

    func dismiss() {
        events.append(.dismiss)
    }
}

@MainActor
private final class TestNotificationPresenter: NotificationPresenting {
    private let authorizationGranted: Bool
    private(set) var authorizationRequestCount = 0
    private(set) var presented: [(title: String, body: String, sourceApp: TargetApp)] = []

    init(authorizationGranted: Bool = true) {
        self.authorizationGranted = authorizationGranted
    }

    func requestAuthorizationIfNeeded() {
        authorizationRequestCount += 1
    }

    func requestAuthorizationIfNeeded(onResult: @escaping @MainActor @Sendable (Bool) -> Void) {
        authorizationRequestCount += 1
        onResult(authorizationGranted)
    }

    func present(title: String, body: String, sourceApp: TargetApp) {
        presented.append((title, body, sourceApp))
    }
}
