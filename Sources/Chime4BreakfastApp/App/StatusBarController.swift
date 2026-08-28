import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private static let autosaveName = "Chime4BreakfastStatusItemV2"

    private let appState: AppState
    private let popover: NSPopover
    private let statusItem: NSStatusItem
    private var cancellables: Set<AnyCancellable> = []

    init(appState: AppState) {
        self.appState = appState
        popover = NSPopover()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        configureStatusItem()
        configurePopover()
        observeAppState()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 368, height: 640)
        popover.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView().environmentObject(appState)
        )
    }

    private func configureStatusItem() {
        // Visibility is persisted by AppKit using this name. The previous
        // MenuBarExtra used macOS's anonymous Item-0 identity, which can be
        // restored hidden and leave the agent with no visible entry point.
        statusItem.autosaveName = Self.autosaveName
        statusItem.behavior = []
        statusItem.isVisible = true

        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.sendAction(on: [.leftMouseUp])
        button.toolTip = "Chime 4 Breakfast"
        updateButton(for: appState.status)
    }

    private func observeAppState() {
        appState.$status
            .sink { [weak self] status in
                self?.updateButton(for: status)
            }
            .store(in: &cancellables)
    }

    private func updateButton(for status: AppState.Status) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        switch status {
        case .idle:
            symbolName = "bell"
        case .watching:
            symbolName = "waveform"
        case .paused:
            symbolName = "pause.circle.fill"
        case .attention:
            symbolName = "bell.badge.fill"
        case .permissionRequired:
            symbolName = "hand.raised.fill"
        case .error:
            symbolName = "exclamationmark.triangle.fill"
        }

        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.title = ""
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Chime 4 Breakfast")?
            .withSymbolConfiguration(configuration)
        button.image?.isTemplate = true
        button.setAccessibilityLabel("Chime 4 Breakfast: \(appState.statusTitle)")
    }

    var isHostedOnScreen: Bool {
        guard let frame = statusItem.button?.window?.frame else {
            return false
        }

        let isInMenuBarBand = NSScreen.screens.contains {
            StatusItemHostValidator.isHosted(
                statusItemFrame: frame,
                screenFrame: $0.frame,
                visibleFrame: $0.visibleFrame
            )
        }
        guard isInMenuBarBand else {
            return false
        }

        return !ControlCenterStatusHostInspector.needsRecoveryPanel(
            statusItemIsInMenuBarBand: true,
            collapsedStatusItemCount: ControlCenterStatusHostInspector.collapsedStatusItemCount()
        )
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
