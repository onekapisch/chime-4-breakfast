import AppKit
import SwiftUI

@MainActor
protocol ScreenGlowPresenting: AnyObject {
    func flashCompletion(color: Color, intensity: Double)
    func showAttention(color: Color, intensity: Double)
    func preview(color: Color, intensity: Double)
    func updatePreview(intensity: Double)
    func dismiss()
}

extension ScreenGlowPresenting {
    func updatePreview(intensity: Double) {}
}

/// Drives a transparent, click-through overlay window on every screen and
/// flashes a luminous edge cue when an assistant response is detected.
@MainActor
final class ScreenGlowController: ScreenGlowPresenting {
    private var windows: [NSWindow] = []
    private let model = GlowOverlayModel()
    private var autoDismissTask: Task<Void, Never>?
    private var teardownTask: Task<Void, Never>?
    private var isPreviewing = false
    // The glow is a nudge, not an overlay: about one fully-visible second
    // (fade-in is near-instant), then a gentle fade-out.
    private let completionFlashDuration: TimeInterval = 1.2
    private let attentionPulseDuration: TimeInterval = 1.7
    private let previewFlashDuration: TimeInterval = 1.5

    func flashCompletion(color: Color, intensity: Double) {
        chimeDebugLog("GLOW completion.requested intensity=\(intensity)")
        isPreviewing = false
        present(color: color, pulsing: false, intensity: intensity)
        scheduleAutoDismiss(after: completionFlashDuration)
    }

    /// Attention pulses a little longer than a completion flash, but always
    /// auto-dismisses - the glow is a nudge, never a lingering overlay.
    func showAttention(color: Color, intensity: Double) {
        chimeDebugLog("GLOW attention.requested intensity=\(intensity)")
        isPreviewing = false
        present(color: color, pulsing: true, intensity: intensity)
        scheduleAutoDismiss(after: attentionPulseDuration)
    }

    func preview(color: Color, intensity: Double) {
        chimeDebugLog("GLOW preview.requested intensity=\(intensity)")
        isPreviewing = true
        present(color: color, pulsing: false, intensity: intensity)
        scheduleAutoDismiss(after: previewFlashDuration)
    }

    func updatePreview(intensity: Double) {
        guard isPreviewing, model.visible else { return }

        model.configuration = GlowConfiguration(intensity: intensity)
        chimeDebugLog("GLOW preview.updated intensity=\(model.configuration.intensity)")
    }

    func dismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        isPreviewing = false

        guard !windows.isEmpty else { return }

        chimeDebugLog("GLOW dismiss windows=\(windows.count)")
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

        let configuration = GlowConfiguration(intensity: intensity)
        model.color = color
        model.pulsing = pulsing
        model.configuration = configuration
        model.visible = false
        let hexColor = color.hexString() ?? "unknown"
        chimeDebugLog(
            "GLOW present windows=\(windows.count) pulsing=\(pulsing) intensity=\(configuration.intensity) color=\(hexColor)"
        )

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
        chimeDebugLog("GLOW windows.built count=\(windows.count)")
    }

    private func teardownWindows() {
        for window in windows {
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        chimeDebugLog("GLOW windows.teardown")
    }
}
