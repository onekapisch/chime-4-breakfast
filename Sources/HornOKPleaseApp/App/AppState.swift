import AppKit
import Combine
import Foundation

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

    private let preferencesStore: PreferencesStore
    private let activityStore: ActivityStore
    private let soundEngine: SoundEngine
    private let appObserver: AppObserver
    private let accessibilityProbe: any AccessibilityProbing
    private let accessibilityAuthorizer: any AccessibilityAuthorizing
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
        accessibilityAuthorizer: any AccessibilityAuthorizing = AccessibilityAuthorizer()
    ) {
        self.preferencesStore = preferencesStore
        self.activityStore = activityStore
        self.soundEngine = soundEngine
        self.appObserver = appObserver
        self.accessibilityProbe = accessibilityProbe
        self.accessibilityAuthorizer = accessibilityAuthorizer
        self.preferences = preferencesStore.preferences
        self.recentActivity = activityStore.items

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
            "Watching Codex + Claude"
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

    func previewSound(for eventType: NotificationEventType) {
        soundEngine.play(soundID: preferences.soundID(for: eventType))
    }

    func pauseWatching() {
        accessibilityProbe.stop()
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
        status = .watching
    }

    private func handle(snapshot: WindowSnapshot) {
        guard let observedEvent = appObserver.process(snapshot) else { return }

        let item = ActivityItem(
            id: UUID(),
            sourceApp: observedEvent.sourceApp,
            eventType: observedEvent.eventType,
            timestamp: Date(),
            excerpt: classifier.normalizedExcerpt(from: observedEvent.message),
            fingerprint: observedEvent.fingerprint
        )

        activityStore.append(item)

        if preferences.alertsEnabled(for: observedEvent.eventType), !preferences.quietHoursContains(Date()) {
            soundEngine.play(soundID: preferences.soundID(for: observedEvent.eventType))
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
