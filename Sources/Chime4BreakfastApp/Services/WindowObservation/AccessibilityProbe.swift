import AppKit
import ApplicationServices
import CryptoKit
import Foundation

typealias AccessibilitySnapshotHandler = (WindowSnapshot) -> Void
typealias AccessibilityStatusHandler = (_ permissionGranted: Bool, _ runningApps: Set<TargetApp>) -> Void

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

@MainActor
final class AccessibilityProbe: AccessibilityProbing {
    private var timer: Timer?
    private var observers: [TargetApp: AXObserver] = [:]
    private var watchedApps: [TargetApp] = []
    private var detectors: [TargetApp: StabilityDetector] = [:]
    private var snapshotHandler: AccessibilitySnapshotHandler?
    private var statusHandler: AccessibilityStatusHandler?
    private var coalesceTask: Task<Void, Never>?
    private let classifier = MessageClassifier()
    private let selector = MessageCandidateSelector()

    func start(
        watching apps: [TargetApp],
        snapshotHandler: @escaping AccessibilitySnapshotHandler,
        statusHandler: @escaping AccessibilityStatusHandler
    ) {
        stop()

        watchedApps = apps
        detectors = Dictionary(uniqueKeysWithValues: apps.map { ($0, StabilityDetector()) })
        self.snapshotHandler = snapshotHandler
        self.statusHandler = statusHandler

        tick()

        timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        coalesceTask?.cancel()
        coalesceTask = nil
        let runLoop = CFRunLoopGetMain()
        for observer in observers.values {
            CFRunLoopRemoveSource(runLoop, AXObserverGetRunLoopSource(observer), .commonModes)
        }
        observers.removeAll()
    }

    /// Collapses bursts of Accessibility change notifications (common while a
    /// response is streaming) into at most one tree walk every 200 ms. The
    /// periodic timer still provides a steady 0.75 s baseline.
    func scheduleCoalescedTick() {
        guard coalesceTask == nil else { return }
        coalesceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
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

            let strings = collectCandidateStrings(from: runningApp)
            let selected = selector.select(from: strings)
            let classification = selected.map { classifier.classify($0).rawValue } ?? "n/a"

            lines.append("Running: yes (pid \(runningApp.processIdentifier))")
            lines.append("Raw strings collected: \(strings.count)")
            lines.append("Selected candidate: \(selected ?? "<none>")")
            lines.append("Would classify as: \(classification)")
            lines.append("")
            lines.append("--- raw strings (first 80) ---")
            for (index, value) in strings.prefix(80).enumerated() {
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
            statusHandler?(false, [])
            return
        }

        let running = Set(watchedApps.filter { !$0.runningApplications.isEmpty })
        statusHandler?(true, running)

        let now = Date().timeIntervalSinceReferenceDate

        for app in watchedApps {
            guard running.contains(app), let runningApp = app.runningApplications.first else { continue }
            installObserverIfNeeded(for: app, runningApp: runningApp)
            guard let candidate = extractLatestMessage(from: runningApp) else { continue }

            let normalized = classifier.normalizedExcerpt(from: candidate, limit: 2_000)
            detectors[app]?.record(candidate: normalized, at: now)

            guard let stable = detectors[app]?.stableCandidate(at: now) else { continue }

            snapshotHandler?(
                WindowSnapshot(
                    app: app,
                    message: stable,
                    fingerprint: fingerprint(for: app, message: stable)
                )
            )
        }
    }

    private func extractLatestMessage(from runningApp: NSRunningApplication) -> String? {
        selector.select(from: collectCandidateStrings(from: runningApp))
    }

    private func collectCandidateStrings(from runningApp: NSRunningApplication) -> [String] {
        let applicationElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        let rootElement = focusedWindow(of: applicationElement) ?? firstWindow(of: applicationElement) ?? applicationElement

        var budget = 500
        return collectStrings(from: rootElement, depth: 0, budget: &budget)
    }

    private func focusedWindow(of applicationElement: AXUIElement) -> AXUIElement? {
        elementAttribute(kAXFocusedWindowAttribute, of: applicationElement)
    }

    private func firstWindow(of applicationElement: AXUIElement) -> AXUIElement? {
        guard let windows = elementArrayAttribute(kAXWindowsAttribute, of: applicationElement) else {
            return nil
        }

        return windows.first
    }

    private func collectStrings(from element: AXUIElement, depth: Int, budget: inout Int) -> [String] {
        guard depth < 8, budget > 0 else { return [] }
        budget -= 1

        var values: [String] = []

        for attribute in [kAXValueAttribute, kAXTitleAttribute, kAXDescriptionAttribute] {
            if let text = stringAttribute(attribute, of: element) {
                let trimmed = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    values.append(trimmed)
                }
            }
        }

        let childrenAttributes = [kAXChildrenAttribute, kAXRowsAttribute, kAXVisibleChildrenAttribute, kAXContentsAttribute]
        for attribute in childrenAttributes {
            guard let children = elementArrayAttribute(attribute, of: element) else { continue }
            for child in children {
                values.append(contentsOf: collectStrings(from: child, depth: depth + 1, budget: &budget))
            }
        }

        return values
    }

    private func attributeValue(_ attribute: String, of element: AXUIElement) -> Any? {
        var result: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &result)
        guard error == .success, let result else { return nil }
        return result
    }

    private func stringAttribute(_ attribute: String, of element: AXUIElement) -> String? {
        attributeValue(attribute, of: element) as? String
    }

    private func elementAttribute(_ attribute: String, of element: AXUIElement) -> AXUIElement? {
        guard let value = attributeValue(attribute, of: element) else { return nil }
        return unsafeDowncast(value as AnyObject, to: AXUIElement.self)
    }

    private func elementArrayAttribute(_ attribute: String, of element: AXUIElement) -> [AXUIElement]? {
        attributeValue(attribute, of: element) as? [AXUIElement]
    }

    private func fingerprint(for app: TargetApp, message: String) -> String {
        let digest = SHA256.hash(data: Data("\(app.rawValue)|\(message)".utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func installObserverIfNeeded(for app: TargetApp, runningApp: NSRunningApplication) {
        guard observers[app] == nil else { return }

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
    }
}

private extension TargetApp {
    var runningApplications: [NSRunningApplication] {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
    }
}
