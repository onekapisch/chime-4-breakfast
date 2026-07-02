import AppKit
import ApplicationServices
import CryptoKit
import Foundation

typealias AccessibilitySnapshotHandler = (WindowSnapshot) -> Void
typealias AccessibilityStatusHandler = (_ permissionGranted: Bool, _ runningApps: Set<TargetApp>) -> Void

func chimeDebugLog(_ message: @autoclosure () -> String) {
#if DEBUG
    guard ProcessInfo.processInfo.environment["CHIME_DEBUG_LOG"] == "1" else { return }

    let line = "\(Date()) \(message())\n"
    let path = "/tmp/chime4breakfast.log"
    guard let data = line.data(using: .utf8) else { return }
    if let handle = FileHandle(forWritingAtPath: path) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    } else {
        try? data.write(to: URL(fileURLWithPath: path))
    }
#endif
}

@MainActor
protocol AccessibilityProbing: AnyObject {
    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    )
    func stop()

    /// Produces a human-readable snapshot of what the watcher currently sees for
    /// each app: the raw Accessibility strings, the selected candidate, and how
    /// it would be classified. Used by the diagnostics capture action so users
    /// can report misdetections with real data.
    func captureDiagnostics(for apps: [TargetApp]) -> String
}

/// Pure Accessibility traversal, isolated from the actor so the heavy tree walk
/// can run off the main thread. Codex and Claude Desktop are Electron apps with
/// large web-content trees (thousands of nodes), and their focused window is not
/// always the conversation (it may be a dialog), so this scans every window and
/// keeps the richest result.
enum AXScan {
    static let maxBudget = 40_000
    static let maxDepth = 70
    private static let maxGeneratingBudget = 12_000

    /// Bounds every AX message this process sends. Electron apps can beachball
    /// while rendering a large response; without this, a single attribute read
    /// can hang for the 6-second system default and a full walk can stall the
    /// scanner for minutes — which reads as "the app randomly stopped working".
    static let configureGlobalTimeout: Void = {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.0)
    }()

    static func collectStrings(pid: pid_t) -> [String] {
        _ = configureGlobalTimeout
        let appElement = AXUIElementCreateApplication(pid)

        // Ask Chromium/Electron to expose its full accessibility tree.
        AXUIElementSetAttributeValue(appElement, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)

        var best: [String] = []
        for window in elementArray("AXWindows", of: appElement) ?? [] {
            var budget = maxBudget
            var strings: [String] = []
            walk(window, depth: 0, budget: &budget, into: &strings)
            if strings.count > best.count { best = strings }
        }

        // Fallback for apps whose windows expose little (or none): walk the app.
        if best.count < 5 {
            var budget = maxBudget
            var strings: [String] = []
            walk(appElement, depth: 0, budget: &budget, into: &strings)
            if strings.count > best.count { best = strings }
        }

        return best
    }

    /// True when the app still appears to be generating — a Stop control or a
    /// thinking/reasoning status is present — so the current text is not yet a
    /// finished reply and must not trigger an alert.
    static func indicatesGenerating(pid: pid_t) -> Bool {
        _ = configureGlobalTimeout
        let appElement = AXUIElementCreateApplication(pid)

        AXUIElementSetAttributeValue(appElement, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)

        for window in elementArray("AXWindows", of: appElement) ?? [] {
            var budget = maxGeneratingBudget
            if walkForGenerating(window, depth: 0, budget: &budget) {
                return true
            }
        }

        var budget = maxGeneratingBudget
        return walkForGenerating(appElement, depth: 0, budget: &budget)
    }

    static func indicatesGenerating(_ strings: [String]) -> Bool {
        for raw in strings {
            if isGeneratingString(raw) {
                return true
            }
        }
        return false
    }

    private static func isGeneratingString(_ raw: String) -> Bool {
        let s = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "…", with: "...")

        if [
            "stop",
            "thinking",
            "thinking...",
            "reasoning",
            "reasoning...",
            "responding",
            "responding...",
            "generating",
            "generating..."
        ].contains(s) {
            return true
        }

        return s.hasPrefix("stop response")
            || s.hasPrefix("stop generating")
            || s.hasPrefix("stop streaming")
    }

    private static func walk(_ element: AXUIElement, depth: Int, budget: inout Int, into out: inout [String]) {
        guard depth < maxDepth, budget > 0 else { return }
        budget -= 1

        for attribute in ["AXValue", "AXTitle", "AXDescription"] {
            if let text = string(attribute, of: element) {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { out.append(trimmed) }
            }
        }

        for attribute in ["AXChildren", "AXRows", "AXContents"] {
            guard let children = elementArray(attribute, of: element) else { continue }
            for child in children {
                walk(child, depth: depth + 1, budget: &budget, into: &out)
            }
        }
    }

    private static func walkForGenerating(_ element: AXUIElement, depth: Int, budget: inout Int) -> Bool {
        guard depth < maxDepth, budget > 0 else { return false }
        budget -= 1

        for attribute in ["AXValue", "AXTitle", "AXDescription"] {
            if let text = string(attribute, of: element), isGeneratingString(text) {
                return true
            }
        }

        for attribute in ["AXChildren", "AXRows", "AXContents"] {
            guard let children = elementArray(attribute, of: element) else { continue }
            for child in children where walkForGenerating(child, depth: depth + 1, budget: &budget) {
                return true
            }
        }

        return false
    }

    private static func value(_ attribute: String, of element: AXUIElement) -> CFTypeRef? {
        var result: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, attribute as CFString, &result) == .success ? result : nil
    }

    private static func string(_ attribute: String, of element: AXUIElement) -> String? {
        value(attribute, of: element) as? String
    }

    private static func elementArray(_ attribute: String, of element: AXUIElement) -> [AXUIElement]? {
        value(attribute, of: element) as? [AXUIElement]
    }
}

@MainActor
final class AccessibilityProbe: AccessibilityProbing {
    private var timer: Timer?
    private var observers: [TargetApp: AXObserver] = [:]
    private var watchedApps: [TargetApp] = []
    private var observerPIDs: [TargetApp: pid_t] = [:]
    private var activationObserver: NSObjectProtocol?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private var snapshotHandler: AccessibilitySnapshotHandler?
    private var statusHandler: AccessibilityStatusHandler?
    private var coalesceTask: Task<Void, Never>?
    private var isExtracting = false
    private var extractionStartedAt: Date?
    private var scanSessionID = 0
    private var activityToken: NSObjectProtocol?
    private let classifier = MessageClassifier()
    private let selector = MessageCandidateSelector()
    private let finishDetector = FinishEdgeDetector()

    /// How long an in-flight scan may run before we assume the target app hung
    /// an AX call and re-arm the scanner (stale results are discarded by
    /// `scanSessionID`). With the 1 s messaging timeout this should never trip
    /// in practice; it is a belt-and-braces guard against total silence.
    private let extractionStallLimit: TimeInterval = 8

    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    ) {
        stop()

        watchedApps = apps
        scanSessionID &+= 1
        finishDetector.reset(watching: apps)
        observerPIDs = [:]
        self.snapshotHandler = snapshotHandler
        self.statusHandler = statusHandler
        registerActivationObserver()
        registerLifecycleObservers()
        beginActivityIfNeeded()
        chimeDebugLog("probe.start watching=[\(apps.map { $0.rawValue }.joined(separator: ","))]")

        tick()

        // .common mode so the poll keeps firing while menus / the popover are
        // open (default-mode timers stall during event tracking).
        let pollTimer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        pollTimer.tolerance = 0.2
        RunLoop.main.add(pollTimer, forMode: .common)
        timer = pollTimer
    }

    /// Opting out of App Nap while monitoring: this is a background agent, and
    /// napped timers slip from seconds to minutes — the finish edge then goes
    /// unobserved and alerts appear "randomly" late or never.
    private func beginActivityIfNeeded() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "Watching Codex and Claude for finished responses"
        )
    }

    private func endActivityIfNeeded() {
        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }
    }

    func stop() {
        scanSessionID &+= 1
        timer?.invalidate()
        timer = nil
        coalesceTask?.cancel()
        coalesceTask = nil
        isExtracting = false
        extractionStartedAt = nil
        endActivityIfNeeded()
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        for observer in lifecycleObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
        let runLoop = CFRunLoopGetMain()
        for observer in observers.values {
            CFRunLoopRemoveSource(runLoop, AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observers.removeAll()
        observerPIDs.removeAll()
    }

    private func registerActivationObserver() {
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            let bundleID = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
            Task { @MainActor in self?.handleActivation(activatedBundleID: bundleID) }
        }
    }

    private func registerLifecycleObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        // Only true system sleep/wake resets detector state. Display wake
        // (screensDidWake) fires during ordinary use — e.g. an external monitor
        // waking — and resetting there silently drops in-flight finishes.
        let notifications: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.didWakeNotification
        ]

        lifecycleObservers = notifications.map { notificationName in
            notificationCenter.addObserver(
                forName: notificationName,
                object: nil,
                queue: .main
            ) { [weak self] note in
                let name = note.name
                Task { @MainActor in
                    self?.handleWorkspaceLifecycleEvent(name: name)
                }
            }
        }
    }

    private func handleWorkspaceLifecycleEvent(name: Notification.Name) {
        scanSessionID &+= 1
        coalesceTask?.cancel()
        coalesceTask = nil
        isExtracting = false
        finishDetector.reset(watching: watchedApps)
        chimeDebugLog("probe.reset reason=\(name.rawValue)")
    }

    /// Event-driven away detection: the instant the user switches to another app
    /// while a watched app is generating, remember they stepped away — even if
    /// they switch back before it finishes.
    private func handleActivation(activatedBundleID: String?) {
        finishDetector.noteActivation(bundleIdentifier: activatedBundleID)
    }

    /// Collapses bursts of Accessibility change notifications (common while a
    /// response is streaming) into at most one extraction every 250 ms.
    func scheduleCoalescedTick() {
        guard coalesceTask == nil else { return }
        coalesceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, !Task.isCancelled else { return }
            self.coalesceTask = nil
            self.tick()
        }
    }

    func captureDiagnostics(for apps: [TargetApp]) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = [
            "Chime 4 Breakfast — Detection Diagnostics",
            "Generated: \(timestamp)",
            "Accessibility trusted: \(AXIsProcessTrusted())",
            ""
        ]

        for app in apps {
            lines.append("=== \(app.displayName) (\(app.bundleIdentifier)) ===")

            guard let runningApp = app.runningApplications.first else {
                lines.append("Not running.")
                lines.append("")
                continue
            }

            let strings = AXScan.collectStrings(pid: runningApp.processIdentifier)
            let selected = selector.select(from: strings)
            let generating = AXScan.indicatesGenerating(strings)
            let classification = selected.map { classifier.classify($0).rawValue } ?? "n/a"

            lines.append("Running: yes (pid \(runningApp.processIdentifier))")
            lines.append("Appears generating: \(generating ? "yes" : "no")")
            lines.append("Text nodes collected: \(strings.count)")
            lines.append("Selected candidate: \(selected ?? "<none>")")
            lines.append("Would classify as: \(classification)")
            lines.append("")
            lines.append("--- last 40 text nodes (newest content is usually here) ---")
            for (index, value) in strings.suffix(40).enumerated() {
                let trimmed = value.count > 200 ? String(value.prefix(200)) + "…" : value
                lines.append("[\(index)] \(trimmed)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func tick() {
        let trusted = AXIsProcessTrusted()
        guard trusted else {
            chimeDebugLog("tick trusted=false (no Accessibility permission)")
            statusHandler?(false, [])
            return
        }

        let running = Set(watchedApps.filter { !$0.runningApplications.isEmpty })
        statusHandler?(true, running)

        if isExtracting {
            // Watchdog: if a scan has hung past the stall limit (target app
            // unresponsive), abandon it — the session bump discards its result.
            if let startedAt = extractionStartedAt, Date().timeIntervalSince(startedAt) > extractionStallLimit {
                chimeDebugLog("tick stalled scan abandoned after \(Int(extractionStallLimit))s")
                scanSessionID &+= 1
                isExtracting = false
                extractionStartedAt = nil
            } else {
                return
            }
        }

        for app in Set(watchedApps).subtracting(running) {
            finishDetector.reset(app: app)
            removeObserver(for: app)
        }

        var targets: [(TargetApp, pid_t)] = []
        for app in watchedApps {
            guard running.contains(app), let runningApp = app.runningApplications.first else { continue }
            installObserverIfNeeded(for: app, runningApp: runningApp)
            targets.append((app, runningApp.processIdentifier))
        }

        guard !targets.isEmpty else { return }

        isExtracting = true
        extractionStartedAt = Date()
        let scanSessionID = self.scanSessionID
        let selector = self.selector

        Task.detached(priority: .utility) {
            var results: [(TargetApp, Bool, String?, String?)] = []
            for (app, pid) in targets {
                var generating = AXScan.indicatesGenerating(pid: pid)
                var latest: String?
                var tailKey: String?

                if !generating {
                    let strings = AXScan.collectStrings(pid: pid)
                    generating = AXScan.indicatesGenerating(strings)
                    if !generating {
                        latest = selector.select(from: strings)
                        tailKey = selector.tailKey(from: strings)
                    }
                }

                results.append((app, generating, latest, tailKey))
            }
            await MainActor.run { [weak self] in
                guard let self, self.scanSessionID == scanSessionID else { return }
                self.finishExtraction(results)
            }
        }
    }

    /// Fires once per completed response, detected as the moment an app stops
    /// showing its Stop control (generating true→false), confirmed across one
    /// extra tick to ignore flicker, and de-duplicated by message fingerprint.
    private func finishExtraction(_ results: [(TargetApp, Bool, String?, String?)]) {
        isExtracting = false
        extractionStartedAt = nil

        for (app, generating, latest, tailKey) in results {
            guard let snapshot = finishDetector.process(
                app: app,
                generating: generating,
                message: latest,
                changeKey: tailKey,
                isFrontmost: isFrontmost(app),
                fingerprint: fingerprint
            ) else { continue }

            chimeDebugLog("EMIT \(app.rawValue) away=\(snapshot.userWasAway)")
            snapshotHandler?(snapshot)
        }

        // The finish edge needs a confirm observation, and generation needs the
        // next poll — but once streaming stops, AX notifications stop too, so
        // never leave the sequence hostage to the slow timer: self-schedule the
        // follow-up while the detector is mid-flight.
        if watchedApps.contains(where: { finishDetector.needsMessage(for: $0) }) {
            scheduleCoalescedTick()
        }
    }

    private func isFrontmost(_ app: TargetApp) -> Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == app.bundleIdentifier
    }

    private func fingerprint(for app: TargetApp, message: String) -> String {
        let digest = SHA256.hash(data: Data("\(app.rawValue)|\(message)".utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func installObserverIfNeeded(for app: TargetApp, runningApp: NSRunningApplication) {
        let pid = runningApp.processIdentifier

        if observers[app] != nil {
            if observerPIDs[app] == pid { return }
            // The app was relaunched (new PID) — tear down the stale observer.
            removeObserver(for: app)
        }

        var observer: AXObserver?
        let callback: AXObserverCallback = { _, _, _, refcon in
            guard let refcon else { return }
            let probe = Unmanaged<AccessibilityProbe>.fromOpaque(refcon).takeUnretainedValue()
            Task { @MainActor in
                probe.scheduleCoalescedTick()
            }
        }

        guard AXObserverCreate(runningApp.processIdentifier, callback, &observer) == .success, let observer else {
            return
        }

        let applicationElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let notifications = [
            kAXFocusedWindowChangedNotification,
            kAXFocusedUIElementChangedNotification,
            kAXValueChangedNotification
        ]

        for notification in notifications {
            AXObserverAddNotification(observer, applicationElement, notification as CFString, refcon)
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        observers[app] = observer
        observerPIDs[app] = pid
    }

    private func removeObserver(for app: TargetApp) {
        guard let observer = observers[app] else {
            observerPIDs[app] = nil
            return
        }

        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
        observers[app] = nil
        observerPIDs[app] = nil
    }
}

private extension TargetApp {
    var runningApplications: [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
    }
}
