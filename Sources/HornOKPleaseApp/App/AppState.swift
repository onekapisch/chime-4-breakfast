import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum Status: Equatable {
        case idle
        case watching
        case paused
        case attention
        case permissionRequired
        case error
    }

    @Published var status: Status = .idle
    @Published var preferences: UserPreferences
    @Published private(set) var recentActivity: [ActivityItem] = []
    @Published private(set) var runningApps: Set<TargetApp> = []
    @Published private(set) var launchAtLoginEnabled: Bool = false

    private let preferencesStore: PreferencesStore
    private let activityStore: ActivityStore
    private let soundEngine: SoundEngine
    private let appObserver: AppObserver
    private let accessibilityProbe: any AccessibilityProbing
    private let accessibilityAuthorizer: any AccessibilityAuthorizing
    private let screenGlowController: ScreenGlowController
    private let loginItemController: any LoginItemControlling
    private let notificationPresenter: NotificationPresenter
    private let classifier = MessageClassifier()
    private var cancellables: Set<AnyCancellable> = []
    private var attentionResetTask: Task<Void, Never>?
    private var hasRequestedAccessibilityPrompt = false

    init(
        preferencesStore: PreferencesStore = PreferencesStore(),
        activityStore: ActivityStore = ActivityStore(),
        soundEngine: SoundEngine = SoundEngine(),
        appObserver: AppObserver = AppObserver(),
        accessibilityProbe: any AccessibilityProbing = AccessibilityProbe(),
        accessibilityAuthorizer: any AccessibilityAuthorizing = AccessibilityAuthorizer(),
        screenGlowController: ScreenGlowController = ScreenGlowController(),
        loginItemController: any LoginItemControlling = LoginItemController(),
        notificationPresenter: NotificationPresenter = NotificationPresenter()
    ) {
        self.preferencesStore = preferencesStore
        self.activityStore = activityStore
        self.soundEngine = soundEngine
        self.appObserver = appObserver
        self.accessibilityProbe = accessibilityProbe
        self.accessibilityAuthorizer = accessibilityAuthorizer
        self.screenGlowController = screenGlowController
        self.loginItemController = loginItemController
        self.notificationPresenter = notificationPresenter
        self.preferences = preferencesStore.preferences
        self.recentActivity = activityStore.items
        self.launchAtLoginEnabled = loginItemController.isEnabled()

        preferencesStore.$preferences
            .sink { [weak self] in self?.preferences = $0 }
            .store(in: &cancellables)

        activityStore.$items
            .sink { [weak self] in self?.recentActivity = $0 }
            .store(in: &cancellables)
    }

    var menuBarSymbolName: String {
        switch status {
        case .idle:
            "bell"
        case .watching:
            "waveform"
        case .paused:
            "pause.circle.fill"
        case .attention:
            "bell.badge.fill"
        case .permissionRequired:
            "hand.raised.fill"
        case .error:
            "exclamationmark.triangle.fill"
        }
    }

    var statusTitle: String {
        switch status {
        case .idle:
            "Idle"
        case .watching:
            runningApps.isEmpty ? "Waiting for Codex or Claude" : "Watching"
        case .paused:
            "Paused"
        case .attention:
            "Attention needed"
        case .permissionRequired:
            "Accessibility required"
        case .error:
            "Watcher error"
        }
    }

    var statusDetail: String {
        switch status {
        case .idle:
            return "Enable Codex or Claude monitoring to start receiving alerts."
        case .watching:
            let activeAppNames = runningApps.map(\.displayName).sorted()
            guard !activeAppNames.isEmpty else {
                return "Waiting for Codex or Claude to be open."
            }

            return "Watching \(formattedAppList(activeAppNames)) for finished responses."
        case .paused:
            return "Monitoring is paused until you resume it."
        case .attention:
            return "The latest assistant response likely needs your input."
        case .permissionRequired:
            return "Grant Accessibility access so Horn OK Please can inspect Codex and Claude."
        case .error:
            return "The watcher hit an unexpected error. Restart the app and try again."
        }
    }

    func startMonitoringIfNeeded() {
        guard status != .paused else { return }
        restartMonitoring()
    }

    func restartMonitoring() {
        let trusted = accessibilityAuthorizer.isTrusted()
        requestAccessibilityPromptIfNeeded(trusted: trusted)
        let watchedApps = TargetApp.allCases.filter { preferences.isWatching($0) }
        guard !watchedApps.isEmpty else {
            accessibilityProbe.stop()
            runningApps = []
            status = trusted ? .idle : .permissionRequired
            return
        }

        if !trusted {
            status = .permissionRequired
        }

        accessibilityProbe.start(
            watching: watchedApps,
            snapshotHandler: { [weak self] snapshot in
                self?.handle(snapshot: snapshot)
            },
            statusHandler: { [weak self] permissionGranted, runningApps in
                self?.handleStatus(permissionGranted: permissionGranted, runningApps: runningApps)
            }
        )
    }

    func toggleWatching(_ targetApp: TargetApp, enabled: Bool) {
        preferences.setWatching(targetApp, enabled: enabled)
        preferencesStore.preferences = preferences
        restartMonitoring()
    }

    func setSound(_ soundID: String, for eventType: NotificationEventType) {
        preferences.setSoundID(soundID, for: eventType)
        preferencesStore.preferences = preferences
    }

    func setAlertsEnabled(_ enabled: Bool, for eventType: NotificationEventType) {
        preferences.setAlertsEnabled(enabled, for: eventType)
        preferencesStore.preferences = preferences
    }

    func setQuietHoursEnabled(_ enabled: Bool) {
        preferences.quietHoursEnabled = enabled
        preferencesStore.preferences = preferences
    }

    func setQuietHoursStart(hour: Int) {
        preferences.quietHoursStartHour = hour
        preferencesStore.preferences = preferences
    }

    func setQuietHoursEnd(hour: Int) {
        preferences.quietHoursEndHour = hour
        preferencesStore.preferences = preferences
    }

    func setScreenGlowEnabled(_ enabled: Bool) {
        preferences.screenGlowEnabled = enabled
        preferencesStore.preferences = preferences
        if !enabled {
            screenGlowController.dismiss()
        }
    }

    func setGlowColor(_ color: Color, for eventType: NotificationEventType) {
        guard let hex = color.hexString() else { return }
        preferences.setGlowColorHex(hex, for: eventType)
        preferencesStore.preferences = preferences
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        preferences.notificationsEnabled = enabled
        preferencesStore.preferences = preferences
        if enabled {
            notificationPresenter.requestAuthorizationIfNeeded()
        }
    }

    func addAttentionPhrase(_ phrase: String) {
        let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !preferences.customAttentionPhrases.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return }
        preferences.customAttentionPhrases.append(trimmed)
        preferencesStore.preferences = preferences
    }

    func removeAttentionPhrase(_ phrase: String) {
        preferences.customAttentionPhrases.removeAll { $0 == phrase }
        preferencesStore.preferences = preferences
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        try? loginItemController.setEnabled(enabled)
        launchAtLoginEnabled = loginItemController.isEnabled()
    }

    func clearRecentActivity() {
        activityStore.clear()
    }

    /// Writes a detection diagnostics report to the Desktop and reveals it in
    /// Finder so it can be attached to a bug report.
    @discardableResult
    func captureDiagnostics() -> URL? {
        let report = accessibilityProbe.captureDiagnostics(for: TargetApp.allCases)

        let directory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = directory.appendingPathComponent("HornOKPlease-Diagnostics-\(formatter.string(from: Date())).txt")

        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return url
        } catch {
            return nil
        }
    }

    func previewSound(for eventType: NotificationEventType) {
        soundEngine.play(soundID: preferences.soundID(for: eventType))
    }

    func setGlowIntensity(_ intensity: Double) {
        preferences.glowIntensity = min(max(intensity, 0.2), 1.0)
        preferencesStore.preferences = preferences
    }

    func previewGlow(for eventType: NotificationEventType) {
        let color = glowColor(for: eventType)
        switch eventType {
        case .completion:
            screenGlowController.flashCompletion(color: color, intensity: preferences.glowIntensity)
        case .attention:
            screenGlowController.previewAttention(color: color, intensity: preferences.glowIntensity)
        }
    }

    func pauseWatching() {
        accessibilityProbe.stop()
        screenGlowController.dismiss()
        runningApps = []
        status = .paused
    }

    func resumeWatching() {
        status = .idle
        restartMonitoring()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func acknowledgeAttention() {
        guard status == .attention else { return }
        attentionResetTask?.cancel()
        screenGlowController.dismiss()
        status = .watching
    }

    private func glowColor(for eventType: NotificationEventType) -> Color {
        Color(hex: preferences.glowColorHex(for: eventType)) ?? eventType.accentColor
    }

    private func handle(snapshot: WindowSnapshot) {
        guard let observedEvent = appObserver.process(snapshot, extraPhrases: preferences.customAttentionPhrases) else { return }

        let item = ActivityItem(
            id: UUID(),
            sourceApp: observedEvent.sourceApp,
            eventType: observedEvent.eventType,
            timestamp: Date(),
            excerpt: classifier.normalizedExcerpt(from: observedEvent.message),
            fingerprint: observedEvent.fingerprint
        )

        activityStore.append(item)

        let alertAllowed = preferences.alertsEnabled(for: observedEvent.eventType) && !preferences.quietHoursContains(Date())

        if alertAllowed {
            soundEngine.play(soundID: preferences.soundID(for: observedEvent.eventType))
        }

        if alertAllowed, preferences.notificationsEnabled {
            notificationPresenter.present(
                title: "\(observedEvent.sourceApp.displayName) · \(observedEvent.eventType.title)",
                body: item.excerpt
            )
        }

        if preferences.screenGlowEnabled {
            switch observedEvent.eventType {
            case .completion:
                screenGlowController.flashCompletion(color: glowColor(for: .completion), intensity: preferences.glowIntensity)
            case .attention:
                screenGlowController.showAttention(color: glowColor(for: .attention), intensity: preferences.glowIntensity)
            }
        }

        switch observedEvent.eventType {
        case .completion:
            if status != .attention {
                status = .watching
            }
        case .attention:
            status = .attention
            scheduleAttentionReset()
        }
    }

    private func handleStatus(permissionGranted: Bool, runningApps: Set<TargetApp>) {
        self.runningApps = runningApps

        guard permissionGranted else {
            status = .permissionRequired
            return
        }

        hasRequestedAccessibilityPrompt = false

        if status != .attention {
            status = preferences.isWatching(.codex) || preferences.isWatching(.claude) ? .watching : .idle
        }
    }

    private func scheduleAttentionReset() {
        attentionResetTask?.cancel()
        attentionResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(90))
            guard let self, self.status == .attention else { return }
            self.screenGlowController.dismiss()
            self.status = .watching
        }
    }

    private func requestAccessibilityPromptIfNeeded(trusted: Bool) {
        guard !trusted, !hasRequestedAccessibilityPrompt else { return }
        accessibilityAuthorizer.requestPrompt()
        hasRequestedAccessibilityPrompt = true
    }

    private func formattedAppList(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return ""
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            let leadingNames = names.dropLast().joined(separator: ", ")
            return "\(leadingNames), and \(names[names.count - 1])"
        }
    }
}
