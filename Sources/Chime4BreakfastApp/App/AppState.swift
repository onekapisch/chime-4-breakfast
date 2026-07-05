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
    private let soundEngine: any SoundPlaying
    private let appObserver: AppObserver
    private let accessibilityProbe: any AccessibilityProbing
    private let accessibilityAuthorizer: any AccessibilityAuthorizing
    private let screenGlowController: any ScreenGlowPresenting
    private let loginItemController: any LoginItemControlling
    private let notificationPresenter: any NotificationPresenting
    private let classifier = MessageClassifier()
    private var appColorCache: [TargetApp: Color] = [:]
    private var cancellables: Set<AnyCancellable> = []
    private var attentionResetTask: Task<Void, Never>?
    private var hasRequestedAccessibilityPrompt = false

    init(
        preferencesStore: PreferencesStore = PreferencesStore(),
        activityStore: ActivityStore = ActivityStore(),
        soundEngine: any SoundPlaying = SoundEngine(),
        appObserver: AppObserver = AppObserver(),
        accessibilityProbe: any AccessibilityProbing = AccessibilityProbe(),
        accessibilityAuthorizer: any AccessibilityAuthorizing = AccessibilityAuthorizer(),
        screenGlowController: any ScreenGlowPresenting = ScreenGlowController(),
        loginItemController: any LoginItemControlling = LoginItemController(),
        notificationPresenter: any NotificationPresenting = NotificationPresenter()
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
        if preferences.notificationsEnabled {
            notificationPresenter.requestAuthorizationIfNeeded()
        }

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
            return "Grant Accessibility access so Chime 4 Breakfast can inspect Codex and Claude."
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
        let url = directory.appendingPathComponent("Chime4Breakfast-Diagnostics-\(formatter.string(from: Date())).txt")

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
        preferences.glowIntensity = min(max(intensity, 0.7), 1.0)
        preferencesStore.preferences = preferences
    }

    func previewGlow() {
        let app = Self.preferredPreviewApp(from: runningApps)
        screenGlowController.preview(color: appGlowColor(for: app), intensity: preferences.glowIntensity)
    }

    static func preferredPreviewApp(from runningApps: Set<TargetApp>) -> TargetApp {
        if runningApps.contains(.codex) {
            return .codex
        }

        if runningApps.contains(.claude) {
            return .claude
        }

        return .codex
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

    /// The glow color for an app = the dominant color of its Dock icon, so the
    /// edge light matches the app that finished (Claude orange, Codex blue, …).
    /// Computed once per app and cached.
    private func appGlowColor(for app: TargetApp) -> Color {
        if let cached = appColorCache[app] { return cached }
        let fallbackHex = app == .claude ? "#F06139" : "#3025FF"
        let color = Self.iconColor(forBundleID: app.bundleIdentifier) ?? Color(hex: fallbackHex) ?? .orange
        appColorCache[app] = color
        return color
    }

    private static func iconColor(forBundleID bundleID: String) -> Color? {
        guard let icon = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.icon else {
            return nil
        }

        let size = 24
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        icon.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()

        // Pick the most vivid (saturation × brightness) opaque pixel — that's the
        // brand accent rather than the background.
        var best = -1.0
        var rgb = (0.0, 0.0, 0.0)
        for x in 0..<size {
            for y in 0..<size {
                guard let pixel = rep.colorAt(x: x, y: y), pixel.alphaComponent > 0.6 else { continue }
                let r = pixel.redComponent, g = pixel.greenComponent, b = pixel.blueComponent
                let vivid = Double((max(r, g, b) - min(r, g, b)) * max(r, g, b))
                if vivid > best {
                    best = vivid
                    rgb = (Double(r), Double(g), Double(b))
                }
            }
        }

        guard best >= 0 else { return nil }
        return Color(.sRGB, red: rgb.0, green: rgb.1, blue: rgb.2, opacity: 1)
    }

    private func handle(snapshot: WindowSnapshot) {
        guard let observedEvent = appObserver.process(snapshot, extraPhrases: preferences.customAttentionPhrases) else { return }

        // One decision governs every output. Quiet hours and the per-event
        // toggle mute EVERYTHING together; "away" then picks sound-only vs
        // sound + glow. The chosen outcome is recorded on the activity item so
        // the Recent list always explains what happened and why.
        let quietHoursActive = preferences.quietHoursContains(Date())
        let eventEnabled = preferences.alertsEnabled(for: observedEvent.eventType)
        let away = snapshot.userWasAway

        let playSound = eventEnabled && !quietHoursActive
        let showGlow = playSound && away && preferences.screenGlowEnabled
        let showBanner = playSound && away && preferences.notificationsEnabled

        let delivery: String
        if !eventEnabled {
            delivery = "Muted — \(observedEvent.eventType.title.lowercased()) alerts are off"
        } else if quietHoursActive {
            delivery = "Muted — quiet hours"
        } else if showGlow {
            delivery = "Sound + glow"
        } else if away {
            delivery = "Sound — glow is off"
        } else {
            delivery = "Sound — you were in the app"
        }

        let item = ActivityItem(
            id: UUID(),
            sourceApp: observedEvent.sourceApp,
            eventType: observedEvent.eventType,
            timestamp: Date(),
            excerpt: classifier.normalizedExcerpt(from: observedEvent.message),
            fingerprint: observedEvent.fingerprint,
            delivery: delivery
        )

        activityStore.append(item)
        chimeDebugLog(
            "EVENT \(observedEvent.eventType.rawValue) src=\(observedEvent.sourceApp.rawValue) away=\(away) → \(delivery)"
        )

        if playSound {
            soundEngine.play(soundID: preferences.soundID(for: observedEvent.eventType))
        }

        if showBanner {
            notificationPresenter.present(
                title: "\(observedEvent.sourceApp.displayName) · \(observedEvent.eventType.title)",
                body: item.excerpt
            )
        }

        if showGlow {
            let color = appGlowColor(for: observedEvent.sourceApp)
            switch observedEvent.eventType {
            case .completion:
                screenGlowController.flashCompletion(color: color, intensity: preferences.glowIntensity)
            case .attention:
                screenGlowController.showAttention(color: color, intensity: preferences.glowIntensity)
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
