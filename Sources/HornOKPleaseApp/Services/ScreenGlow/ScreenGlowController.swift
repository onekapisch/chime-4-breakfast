import AppKit
import SwiftUI

/// Drives a transparent, click-through overlay window on every screen and uses
/// it to flash a luminous border when an assistant response is detected.
///
/// - Completion events flash briefly and auto-dismiss.
/// - Attention events pulse and persist until explicitly dismissed (the user
///   acknowledges, or the attention state times out).
@MainActor
final class ScreenGlowController {
    private var windows: [NSWindow] = []
    private let model = GlowOverlayModel()
    private var autoDismissTask: Task<Void, Never>?
    private var teardownTask: Task<Void, Never>?

    func flashCompletion(color: Color, intensity: Double = 1.0, duration: TimeInterval = 1.8) {
        present(color: color, pulsing: false, intensity: intensity)
        scheduleAutoDismiss(after: duration)
    }

    func showAttention(color: Color, intensity: Double = 1.0) {
        present(color: color, pulsing: true, intensity: intensity)
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }

    /// A self-dismissing attention pulse used by the preview button.
    func previewAttention(color: Color, intensity: Double = 1.0, duration: TimeInterval = 2.6) {
        present(color: color, pulsing: true, intensity: intensity)
        scheduleAutoDismiss(after: duration)
    }

    func dismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil

        guard !windows.isEmpty else { return }

        model.visible = false
        teardownTask?.cancel()
        teardownTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            self?.teardownWindows()
        }
    }

    private func scheduleAutoDismiss(after duration: TimeInterval) {
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    private func present(color: Color, pulsing: Bool, intensity: Double) {
        teardownTask?.cancel()
        teardownTask = nil

        if windows.isEmpty {
            buildWindows()
        }

        model.color = color
        model.pulsing = pulsing
        model.intensity = min(max(intensity, 0.2), 1.0)
        model.visible = false

        // Flip to visible on the next runloop so the opacity transition animates
        // from zero rather than snapping in.
        Task { @MainActor [weak self] in
            self?.model.visible = true
        }
    }

    private func buildWindows() {
        teardownWindows()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.level = .screenSaver
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary,
                .ignoresCycle
            ]
            window.isReleasedWhenClosed = false

            let hosting = NSHostingView(rootView: GlowBorderView(model: model))
            hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
            window.contentView = hosting
            window.setFrame(screen.frame, display: true)
            window.orderFrontRegardless()

            windows.append(window)
        }
    }

    private func teardownWindows() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
    }
}
