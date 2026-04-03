import AppKit
import ApplicationServices
import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    enum Status {
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
    private let accessibilityProbe: AccessibilityProbe
    private let classifier = MessageClassifier()
    private var cancellables: Set<AnyCancellable> = []
    private var attentionResetTask: Task<Void, Never>?

    init(
        preferencesStore: PreferencesStore = PreferencesStore(),
        activityStore: ActivityStore = ActivityStore(),
        soundEngine: SoundEngine = SoundEngine(),
        appObserver: AppObserver = AppObserver(),
        accessibilityProbe: AccessibilityProbe = AccessibilityProbe()
    ) {
        self.preferencesStore = preferencesStore
        self.activityStore = activityStore
        self.soundEngine = soundEngine
        self.appObserver = appObserver
        self.accessibilityProbe = accessibilityProbe
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

    func startMonitoringIfNeeded() {
        guard status != .paused else { return }
        restartMonitoring()
    }

    func restartMonitoring() {
        let watchedApps = TargetApp.allCases.filter { preferences.isWatching($0) }
        guard !watchedApps.isEmpty else {
            accessibilityProbe.stop()
            runningApps = []
            status = AXIsProcessTrusted() ? .idle : .permissionRequired
            return
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
}
