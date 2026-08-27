import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState?
    private var controlWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppState()
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 368, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Chime 4 Breakfast"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView().environmentObject(appState)
        )
        window.center()
        controlWindow = window

        appState.startMonitoringIfNeeded()
        showControlWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showControlWindow()
        }
        return true
    }

    private func showControlWindow() {
        guard let controlWindow else { return }
        controlWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
