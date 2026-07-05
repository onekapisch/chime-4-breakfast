import AppKit
import SwiftUI
import XCTest
@testable import Chime4BreakfastApp

/// Renders the real popover to /tmp/popover-snapshot.png so visual changes can
/// be reviewed without clicking through the menu bar. Not a pass/fail test -
/// a design harness.
@MainActor
final class PopoverSnapshotTests: XCTestCase {
    func test_render_popover_snapshot() throws {
        let defaultsName = "Chime4BreakfastSnapshot-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: defaultsName)!
        defaults.removePersistentDomain(forName: defaultsName)

        let activityStore = ActivityStore(defaults: defaults)
        activityStore.append(ActivityItem(
            id: UUID(),
            sourceApp: .claude,
            eventType: .attention,
            timestamp: Date(),
            excerpt: "Which option should I use for the release build, automatic signing or the manual profile?",
            fingerprint: "snap-1",
            delivery: "Sound + glow"
        ))
        activityStore.append(ActivityItem(
            id: UUID(),
            sourceApp: .codex,
            eventType: .completion,
            timestamp: Date(),
            excerpt: "Implemented the retry logic and all 45 tests pass.",
            fingerprint: "snap-2",
            delivery: "Sound only (you were in the app)"
        ))

        let probe = SnapshotProbe()
        probe.statusToSend = (true, [.claude, .codex])

        let state = AppState(
            preferencesStore: PreferencesStore(defaults: defaults),
            activityStore: activityStore,
            soundEngine: SnapshotSoundPlayer(),
            accessibilityProbe: probe,
            accessibilityAuthorizer: SnapshotAuthorizer(),
            screenGlowController: SnapshotGlowPresenter()
        )
        state.startMonitoringIfNeeded()

        let hosting = NSHostingView(rootView: MenuBarPopoverView().environmentObject(state))
        hosting.frame = NSRect(x: 0, y: 0, width: 360, height: 620)

        let window = NSWindow(
            contentRect: hosting.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = hosting
        window.orderFrontRegardless()

        RunLoop.main.run(until: Date().addingTimeInterval(0.8))

        let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds)!
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let png = rep.representation(using: .png, properties: [:])!
        try png.write(to: URL(fileURLWithPath: "/tmp/popover-snapshot.png"))

        window.orderOut(nil)

        // Second render: the full sections column without the fixed popover
        // height, so below-the-fold content (Recent, footer context) is
        // reviewable too.
        let columnView = VStack(spacing: 14) {
            StatusBanner()
            AppToggleSection()
            SoundSection()
            GlowSection()
            RulesSection()
            RecentActivitySection()
        }
        .padding(12)
        .frame(width: 360)
        .background(ColorTokens.base)
        .environmentObject(state)
        .preferredColorScheme(.dark)

        let columnHosting = NSHostingView(rootView: columnView)
        columnHosting.frame = NSRect(x: 0, y: 0, width: 360, height: 1000)
        let columnWindow = NSWindow(
            contentRect: columnHosting.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        columnWindow.appearance = NSAppearance(named: .darkAqua)
        columnWindow.contentView = columnHosting
        columnWindow.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))

        let columnRep = columnHosting.bitmapImageRepForCachingDisplay(in: columnHosting.bounds)!
        columnHosting.cacheDisplay(in: columnHosting.bounds, to: columnRep)
        let columnPNG = columnRep.representation(using: .png, properties: [:])!
        try columnPNG.write(to: URL(fileURLWithPath: "/tmp/popover-sections.png"))

        columnWindow.orderOut(nil)
    }
}

@MainActor
private final class SnapshotProbe: AccessibilityProbing {
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
    func captureDiagnostics(for apps: [TargetApp]) -> String { "" }
}

@MainActor
private final class SnapshotAuthorizer: AccessibilityAuthorizing {
    func isTrusted() -> Bool { true }
    func requestPrompt() {}
}

@MainActor
private final class SnapshotSoundPlayer: SoundPlaying {
    @discardableResult
    func play(soundID: String) -> Bool { true }
}

@MainActor
private final class SnapshotGlowPresenter: ScreenGlowPresenting {
    func flashCompletion(color: Color, intensity: Double) {}
    func showAttention(color: Color, intensity: Double) {}
    func preview(color: Color, intensity: Double) {}
    func dismiss() {}
}
