import AppKit
import ApplicationServices
import CryptoKit
import Foundation

typealias AccessibilitySnapshotHandler = (WindowSnapshot) -> Void
typealias AccessibilityStatusHandler = (_ permissionGranted: Bool, _ runningApps: Set<TargetApp>) -> Void

struct GenerationIndicatorPath: Sendable {
    enum Root: Sendable {
        case window(Int)
        case application
    }

    struct Step: Sendable {
        let attribute: String
        let index: Int
    }

    let root: Root
    let steps: [Step]

    func appending(attribute: String, index: Int) -> GenerationIndicatorPath {
        GenerationIndicatorPath(root: root, steps: steps + [Step(attribute: attribute, index: index)])
    }
}

struct GenerationDetection: Sendable {
    let isGenerating: Bool
    let indicatorPath: GenerationIndicatorPath?
}

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
    static let generationIndicatorAttributes = ["AXValue", "AXTitle", "AXDescription", "AXHelp", "AXIdentifier"]
    private static let maxGeneratingBudget = 12_000

    private final class AccessibilityConfigurationCache: @unchecked Sendable {
        let lock = NSLock()
        var configuredPIDs = Set<pid_t>()
    }

    private static let accessibilityConfigurationCache = AccessibilityConfigurationCache()

    /// Bounds every AX message this process sends. Electron apps can beachball
    /// while rendering a large response; without this, a single attribute read
    /// can hang for the 6-second system default and a full walk can stall the
    /// scanner for minutes - which reads as "the app randomly stopped working".
    static let configureGlobalTimeout: Void = {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 1.0)
    }()

    /// Hard wall-clock caps per scan. A beachballing Electron app slows every
    /// AX message; bounding by time (not just node count) guarantees a scan can
    /// never stall the watcher regardless of how slow the target is.
    private static let fullScanTimeLimit: CFTimeInterval = 2.5
    private static let generatingScanTimeLimit: CFTimeInterval = 1.5

    static func collectStrings(pid: pid_t) -> [String] {
        _ = configureGlobalTimeout
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.5)
        configureElectronAccessibility(appElement, pid: pid)

        let deadline = CFAbsoluteTimeGetCurrent() + fullScanTimeLimit
        var windows: [[String]] = []
        for window in elementArray("AXWindows", of: appElement) ?? [] {
            var budget = maxBudget
            var strings: [String] = []
            var visited = Set<CFHashCode>()
            walk(window, depth: 0, budget: &budget, deadline: deadline, visited: &visited, into: &strings)
            windows.append(strings)
        }
        var best = ConversationWindowSelector().select(from: windows) ?? windows.max(by: { $0.count < $1.count }) ?? []

        // Fallback for apps whose windows expose little (or none): walk the app.
        if best.count < 5 {
            var budget = maxBudget
            var strings: [String] = []
            var visited = Set<CFHashCode>()
            walk(appElement, depth: 0, budget: &budget, deadline: deadline, visited: &visited, into: &strings)
            if strings.count > best.count { best = strings }
        }

        return best
    }

    /// True when the app still appears to be generating - a Stop control or a
    /// thinking/reasoning status is present - so the current text is not yet a
    /// finished reply and must not trigger an alert.
    static func indicatesGenerating(pid: pid_t) -> Bool {
        generationDetection(pid: pid, cachedPath: nil).isGenerating
    }

    static func generationDetection(pid: pid_t, cachedPath: GenerationIndicatorPath?) -> GenerationDetection {
        _ = configureGlobalTimeout
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.5)
        configureElectronAccessibility(appElement, pid: pid)

        if let cachedPath {
            let cachedIndicatorMatches = element(at: cachedPath, in: appElement).map(isGeneratingIndicator)
            if !GenerationIndicatorCachePolicy.shouldPerformFullTraversal(cachedIndicatorMatches: cachedIndicatorMatches) {
                return GenerationDetection(isGenerating: true, indicatorPath: cachedPath)
            }
        }

        let deadline = CFAbsoluteTimeGetCurrent() + generatingScanTimeLimit
        for (index, window) in (elementArray("AXWindows", of: appElement) ?? []).enumerated() {
            var budget = maxGeneratingBudget
            var visited = Set<CFHashCode>()
            let path = GenerationIndicatorPath(root: .window(index), steps: [])
            if let indicatorPath = findGeneratingIndicator(
                in: window,
                depth: 0,
                budget: &budget,
                deadline: deadline,
                visited: &visited,
                path: path
            ) {
                return GenerationDetection(isGenerating: true, indicatorPath: indicatorPath)
            }
        }

        var budget = maxGeneratingBudget
        var visited = Set<CFHashCode>()
        let path = GenerationIndicatorPath(root: .application, steps: [])
        let indicatorPath = findGeneratingIndicator(
            in: appElement,
            depth: 0,
            budget: &budget,
            deadline: deadline,
            visited: &visited,
            path: path
        )
        return GenerationDetection(isGenerating: indicatorPath != nil, indicatorPath: indicatorPath)
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

    private static func walk(
        _ element: AXUIElement,
        depth: Int,
        budget: inout Int,
        deadline: CFAbsoluteTime,
        visited: inout Set<CFHashCode>,
        into out: inout [String]
    ) {
        guard depth < maxDepth, budget > 0, CFAbsoluteTimeGetCurrent() < deadline else { return }
        guard visited.insert(CFHash(element)).inserted else { return }
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
                walk(child, depth: depth + 1, budget: &budget, deadline: deadline, visited: &visited, into: &out)
            }
        }
    }

    private static func findGeneratingIndicator(
        in element: AXUIElement,
        depth: Int,
        budget: inout Int,
        deadline: CFAbsoluteTime,
        visited: inout Set<CFHashCode>,
        path: GenerationIndicatorPath
    ) -> GenerationIndicatorPath? {
        guard depth < maxDepth, budget > 0, CFAbsoluteTimeGetCurrent() < deadline else { return nil }
        guard visited.insert(CFHash(element)).inserted else { return nil }
        budget -= 1

        if isGeneratingIndicator(element) {
            return path
        }

        for attribute in ["AXChildren", "AXRows", "AXContents"] {
            guard let children = elementArray(attribute, of: element) else { continue }
            for (index, child) in children.enumerated() {
                if let indicatorPath = findGeneratingIndicator(
                    in: child,
                    depth: depth + 1,
                    budget: &budget,
                    deadline: deadline,
                    visited: &visited,
                    path: path.appending(attribute: attribute, index: index)
                ) {
                    return indicatorPath
                }
            }
        }

        return nil
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

    private static func element(at path: GenerationIndicatorPath, in appElement: AXUIElement) -> AXUIElement? {
        var element: AXUIElement
        switch path.root {
        case .window(let index):
            guard let windows = elementArray("AXWindows", of: appElement), windows.indices.contains(index) else {
                return nil
            }
            element = windows[index]
        case .application:
            element = appElement
        }

        for step in path.steps {
            guard let children = elementArray(step.attribute, of: element), children.indices.contains(step.index) else {
                return nil
            }
            element = children[step.index]
        }
        return element
    }

    private static func isGeneratingIndicator(_ element: AXUIElement) -> Bool {
        generationIndicatorAttributes.contains { attribute in
            guard let text = string(attribute, of: element) else { return false }
            return isGeneratingString(text)
        }
    }

    private static func configureElectronAccessibility(_ appElement: AXUIElement, pid: pid_t) {
        accessibilityConfigurationCache.lock.lock()
        let shouldConfigure = accessibilityConfigurationCache.configuredPIDs.insert(pid).inserted
        accessibilityConfigurationCache.lock.unlock()

        guard shouldConfigure else { return }
        AXUIElementSetAttributeValue(appElement, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(appElement, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue)
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
    private var lastEventScanAt: Date?
    private var lastIdleScanAt: [TargetApp: Date] = [:]
    private var generationIndicatorPaths: [TargetApp: GenerationIndicatorPath] = [:]
    // Each app scans independently, so a slow or hung app can never delay the
    // other one's detection. Sessions invalidate in-flight results on restart.
    private var extractingApps: [TargetApp: Date] = [:]
    private var scanSessions: [TargetApp: Int] = [:]
    private var activityToken: NSObjectProtocol?
    private let classifier = MessageClassifier()
    private let selector = MessageCandidateSelector()
    private var processEpochs = ProcessEpochs()
    private let finishDetector = FinishEdgeDetector()

    /// How long an in-flight scan may run before we assume the target app hung
    /// an AX call and re-arm the scanner (stale results are discarded by the
    /// per-app session). Scans are wall-clock bounded to ~2.5 s, so this is a
    /// belt-and-braces guard against total silence.
    private let extractionStallLimit: TimeInterval = 6

    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    ) {
        stop()

        watchedApps = apps
        invalidateInFlightScans()
        finishDetector.reset(watching: apps)
        processEpochs.invalidateAll(apps)
        observerPIDs = [:]
        self.snapshotHandler = snapshotHandler
        self.statusHandler = statusHandler
        registerActivationObserver()
        registerLifecycleObservers()
        chimeDebugLog("probe.start watching=[\(apps.map { $0.rawValue }.joined(separator: ","))]")

        tick(scanningAllApps: true)
    }

    /// Keep the process responsive while a response is generating or its Stop
    /// edge awaits confirmation. Idle monitoring uses the normal system budget.
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

    private func updateActivityState() {
        let hasActiveDetection = watchedApps.contains { finishDetector.needsMessage(for: $0) }
        if MonitoringActivityPolicy.requiresAppNapExemption(hasActiveDetection: hasActiveDetection) {
            beginActivityIfNeeded()
        } else {
            endActivityIfNeeded()
        }
    }

    func stop() {
        invalidateInFlightScans()
        timer?.invalidate()
        timer = nil
        coalesceTask?.cancel()
        coalesceTask = nil
        lastEventScanAt = nil
        lastIdleScanAt.removeAll()
        generationIndicatorPaths.removeAll()
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
        // (screensDidWake) fires during ordinary use - e.g. an external monitor
        // waking - and resetting there silently drops in-flight finishes.
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
        invalidateInFlightScans()
        coalesceTask?.cancel()
        coalesceTask = nil
        lastIdleScanAt.removeAll()
        generationIndicatorPaths.removeAll()
        finishDetector.reset(watching: watchedApps)
        processEpochs.invalidateAll(watchedApps)
        endActivityIfNeeded()
        chimeDebugLog("probe.reset reason=\(name.rawValue)")
    }

    private func invalidateInFlightScans() {
        for app in TargetApp.allCases {
            scanSessions[app, default: 0] += 1
        }
        extractingApps.removeAll()
        generationIndicatorPaths.removeAll()
    }

    /// Event-driven away detection: the instant the user switches to another app
    /// while a watched app is generating, remember they stepped away - even if
    /// they switch back before it finishes.
    private func handleActivation(activatedBundleID: String?) {
        finishDetector.noteActivation(bundleIdentifier: activatedBundleID)
    }

    /// Collapses Accessibility notifications into a low-rate idle wake-up, then
    /// returns to a fast cadence only after a real generation edge is observed.
    func scheduleCoalescedTick(force: Bool = false, scanningAllApps: Bool = true) {
        guard coalesceTask == nil else { return }
        let hasActiveFinishEdge = watchedApps.contains { finishDetector.needsMessage(for: $0) }
        let now = Date()
        if !force,
           let lastEventScanAt,
           now.timeIntervalSince(lastEventScanAt) < MonitoringScanPolicy.eventCooldown(hasActiveFinishEdge: hasActiveFinishEdge) {
            return
        }
        lastEventScanAt = now

        coalesceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, !Task.isCancelled else { return }
            self.coalesceTask = nil
            self.tick(scanningAllApps: scanningAllApps)
        }
    }

    func captureDiagnostics(for apps: [TargetApp]) -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var lines: [String] = [
            "Chime 4 Breakfast - Detection Diagnostics",
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

    private func tick(scanningAllApps: Bool = false) {
        defer { scheduleNextPoll() }

        let trusted = AXIsProcessTrusted()
        guard trusted else {
            chimeDebugLog("tick trusted=false (no Accessibility permission)")
            statusHandler?(false, [])
            return
        }

        let running = Set(watchedApps.filter { !$0.runningApplications.isEmpty })
        statusHandler?(true, running)

        for app in Set(watchedApps).subtracting(running) {
            finishDetector.reset(app: app)
            processEpochs.invalidate(app: app)
            lastIdleScanAt[app] = nil
            generationIndicatorPaths[app] = nil
            removeObserver(for: app)
        }
        updateActivityState()

        for app in watchedApps {
            guard running.contains(app), let runningApp = app.runningApplications.first else { continue }
            let process = processEpochs.observe(app: app, pid: runningApp.processIdentifier)
            if process.didChange {
                finishDetector.reset(app: app)
                scanSessions[app, default: 0] += 1
                extractingApps[app] = nil
                lastIdleScanAt[app] = nil
                generationIndicatorPaths[app] = nil
            }
            installObserverIfNeeded(for: app, runningApp: runningApp)
            let hasActiveFinishEdge = finishDetector.needsMessage(for: app)
            let now = Date()
            guard MonitoringScanPolicy.shouldScan(
                hasActiveFinishEdge: hasActiveFinishEdge,
                isEventDriven: scanningAllApps,
                lastIdleScanAt: lastIdleScanAt[app],
                now: now
            ) else {
                continue
            }
            if !hasActiveFinishEdge {
                lastIdleScanAt[app] = now
            }
            beginScanIfIdle(app: app, pid: runningApp.processIdentifier, epoch: process.epoch)
        }
    }

    /// Launches an independent, time-bounded scan for one app. Independence
    /// matters: a busy Codex must never delay Claude's finish detection (and
    /// vice versa).
    private func beginScanIfIdle(app: TargetApp, pid: pid_t, epoch: Int) {
        if let startedAt = extractingApps[app] {
            guard Date().timeIntervalSince(startedAt) > extractionStallLimit else { return }
            chimeDebugLog("scan stalled app=\(app.rawValue) - abandoning")
            scanSessions[app, default: 0] += 1
        }

        extractingApps[app] = Date()
        let session = scanSessions[app, default: 0]
        let selector = self.selector
        let hasActiveFinishEdge = finishDetector.needsMessage(for: app)
        let cachedIndicatorPath = generationIndicatorPaths[app]

        Task.detached(priority: .utility) {
            let detection = AXScan.generationDetection(pid: pid, cachedPath: cachedIndicatorPath)
            var generating = detection.isGenerating
            var latest: String?
            var tailKey: String?

            if MonitoringScanPolicy.shouldExtractMessage(
                hasActiveFinishEdge: hasActiveFinishEdge,
                generating: generating
            ) {
                let strings = AXScan.collectStrings(pid: pid)
                generating = AXScan.indicatesGenerating(strings)
                if !generating {
                    let candidate = selector.selectCandidate(from: strings)
                    latest = candidate?.message
                    tailKey = selector.tailKey(from: strings)
                }
            }

            await MainActor.run { [weak self] in
                self?.finishScan(
                    app: app,
                    pid: pid,
                    epoch: epoch,
                    session: session,
                    generating: generating,
                    latest: latest,
                    tailKey: tailKey,
                    indicatorPath: detection.indicatorPath
                )
            }
        }
    }

    /// Fires once per completed response, detected as the moment an app stops
    /// showing its Stop control (generating true→false), confirmed across one
    /// extra observation to ignore flicker, and rate-limited by the detector's
    /// refire debounce.
    private func finishScan(
        app: TargetApp,
        pid: pid_t,
        epoch: Int,
        session: Int,
        generating: Bool,
        latest: String?,
        tailKey: String?,
        indicatorPath: GenerationIndicatorPath?
    ) {
        guard scanSessions[app, default: 0] == session, processEpochs.accepts(app: app, pid: pid, epoch: epoch) else { return }
        extractingApps[app] = nil
        generationIndicatorPaths[app] = indicatorPath

        if let snapshot = finishDetector.process(
            app: app,
            generating: generating,
            message: latest,
            changeKey: tailKey,
            isFrontmost: isFrontmost(app),
            fingerprint: fingerprint
        ) {
            chimeDebugLog("EMIT \(app.rawValue) away=\(snapshot.userWasAway)")
            snapshotHandler?(snapshot)
        }

        // The finish edge needs a confirm observation, and generation needs the
        // next poll - but once streaming stops, AX notifications stop too, so
        // never leave the sequence hostage to the slow timer: self-schedule the
        // follow-up while the detector is mid-flight.
        if finishDetector.isAwaitingConfirmation(for: app) {
            scheduleCoalescedTick(force: true, scanningAllApps: false)
        }
        updateActivityState()
        scheduleNextPoll()
    }

    private func scheduleNextPoll() {
        timer?.invalidate()

        let hasActiveFinishEdge = watchedApps.contains { finishDetector.needsMessage(for: $0) }
        let pollTimer = Timer(
            timeInterval: MonitoringScanPolicy.pollInterval(hasActiveFinishEdge: hasActiveFinishEdge),
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        pollTimer.tolerance = hasActiveFinishEdge ? 0.1 : 3
        RunLoop.main.add(pollTimer, forMode: .common)
        timer = pollTimer
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
            // The app was relaunched (new PID) - tear down the stale observer.
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
