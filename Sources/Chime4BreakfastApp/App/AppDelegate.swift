import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private enum DefaultsKey {
        static let hasConfirmedStatusItemAccess = "hasConfirmedStatusItemAccess"
    }

    private var appState: AppState?
    private var statusBarController: StatusBarController?
    private var recoveryPanel: NSPanel?
    private var recoveryTask: Task<Void, Never>?
    private var didDismissRecoveryPanel = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appState = AppState()
        self.appState = appState
        statusBarController = StatusBarController(appState: appState) { [weak self] in
            self?.confirmStatusItemAccess()
        }
        appState.startMonitoringIfNeeded()
        validateStatusItemHost()
    }

    func applicationWillTerminate(_ notification: Notification) {
        recoveryTask?.cancel()
    }

    private func validateStatusItemHost() {
        recoveryTask = Task { [weak self] in
            // AppKit can attach the status-item window a little after launch.
            // Do not create a recovery surface until that grace period has passed.
            try? await Task.sleep(for: .seconds(3))

            while !Task.isCancelled, let self {
                let needsRecoveryPanel = StatusItemAccessPolicy.needsRecoveryPanel(
                    hasConfirmedStatusItemAccess: hasConfirmedStatusItemAccess,
                    statusItemIsHostedOnScreen: statusBarController?.isHostedOnScreen == true
                )

                if !needsRecoveryPanel {
                    dismissRecoveryPanel()
                    return
                }

                showRecoveryPanel()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    private var hasConfirmedStatusItemAccess: Bool {
        UserDefaults.standard.bool(forKey: DefaultsKey.hasConfirmedStatusItemAccess)
    }

    private func confirmStatusItemAccess() {
        UserDefaults.standard.set(true, forKey: DefaultsKey.hasConfirmedStatusItemAccess)
        recoveryTask?.cancel()
        dismissRecoveryPanel()
    }

    private func showRecoveryPanel() {
        guard recoveryPanel == nil, !didDismissRecoveryPanel, let appState else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 368, height: 640),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Chime 4 Breakfast"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.delegate = self
        panel.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView().environmentObject(appState)
        )
        panel.center()
        recoveryPanel = panel
        panel.makeKeyAndOrderFront(nil)
    }

    private func dismissRecoveryPanel() {
        didDismissRecoveryPanel = false
        recoveryPanel?.orderOut(nil)
        recoveryPanel = nil
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel, panel == recoveryPanel else { return }
        recoveryPanel = nil
        didDismissRecoveryPanel = true
    }
}
