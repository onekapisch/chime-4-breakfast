import Foundation

final class FinishEdgeDetector {
    private struct State {
        var wasGenerating = false
        var awaitingConfirm = false
        var sawAwayDuringGeneration = false
        var pendingMessage: String?
        var pendingChangeKey: String?
        var lastFiredFingerprint: String?
        var lastFiredAt: Date?
        var lastObservedFingerprint: String?
        var fastCompletionFallbackArmed = false
    }

    /// Minimum spacing between two alerts for the same app. A confirmed Stop
    /// edge always represents a real completion (regardless of what text the
    /// selector happened to pick), so identical-message dedup would silently
    /// swallow rapid consecutive replies - this brief debounce only absorbs
    /// generating-indicator flicker.
    private let refireDebounce: TimeInterval = 3

    private var states: [TargetApp: State] = [:]
    private var lastActivatedBundleIdentifier: String?

    func reset(watching apps: [TargetApp]) {
        states = Dictionary(uniqueKeysWithValues: apps.map { ($0, State()) })
        lastActivatedBundleIdentifier = nil
    }

    func reset(app: TargetApp) {
        states[app] = State()
    }

    func noteActivation(bundleIdentifier: String?) {
        for app in Array(states.keys) {
            if lastActivatedBundleIdentifier == app.bundleIdentifier,
               bundleIdentifier != app.bundleIdentifier {
                states[app]?.fastCompletionFallbackArmed = true
            }

            guard states[app]?.wasGenerating == true else { continue }
            if bundleIdentifier != app.bundleIdentifier {
                states[app]?.sawAwayDuringGeneration = true
            }
        }

        lastActivatedBundleIdentifier = bundleIdentifier
    }

    func needsMessage(for app: TargetApp) -> Bool {
        guard let state = states[app] else { return false }
        return state.wasGenerating || state.awaitingConfirm
    }

    func process(
        app: TargetApp,
        generating: Bool,
        message: String?,
        changeKey: String? = nil,
        allowsFastFallback: Bool = true,
        isFrontmost: Bool,
        now: Date = Date(),
        fingerprint: (TargetApp, String) -> String
    ) -> WindowSnapshot? {
        var state = states[app] ?? State()
        defer { states[app] = state }

        if generating {
            if !state.wasGenerating {
                state.sawAwayDuringGeneration = false
                state.pendingMessage = nil
                state.pendingChangeKey = nil
            }

            if !isFrontmost {
                state.sawAwayDuringGeneration = true
            }

            state.wasGenerating = true
            state.awaitingConfirm = false
            state.fastCompletionFallbackArmed = false
            return nil
        }

        if state.wasGenerating {
            state.wasGenerating = false
            state.awaitingConfirm = true
            state.pendingMessage = message
            state.pendingChangeKey = changeKey
            return nil
        }

        if !state.awaitingConfirm {
            guard let selectedMessage = message else { return nil }

            let selectedFingerprint = fingerprint(app, changeKey ?? selectedMessage)
            guard let previousFingerprint = state.lastObservedFingerprint else {
                state.lastObservedFingerprint = selectedFingerprint
                state.fastCompletionFallbackArmed = isFrontmost
                return nil
            }

            guard selectedFingerprint != previousFingerprint else {
                state.fastCompletionFallbackArmed = isFrontmost
                return nil
            }

            let canUseFastFallback = state.fastCompletionFallbackArmed && allowsFastFallback
            state.lastObservedFingerprint = selectedFingerprint
            state.fastCompletionFallbackArmed = isFrontmost

            guard !isFrontmost,
                  canUseFastFallback,
                  selectedFingerprint != state.lastFiredFingerprint,
                  hasClearedDebounce(state, now: now) else {
                return nil
            }

            state.lastFiredFingerprint = selectedFingerprint
            state.lastFiredAt = now
            state.fastCompletionFallbackArmed = false
            return WindowSnapshot(
                app: app,
                message: selectedMessage,
                fingerprint: selectedFingerprint,
                userWasAway: true
            )
        }

        guard let selectedMessage = message ?? state.pendingMessage else { return nil }

        state.awaitingConfirm = false
        let selectedChangeKey = changeKey ?? state.pendingChangeKey
        state.pendingMessage = nil
        state.pendingChangeKey = nil

        let selectedFingerprint = fingerprint(app, selectedChangeKey ?? selectedMessage)
        state.lastObservedFingerprint = selectedFingerprint
        state.fastCompletionFallbackArmed = isFrontmost

        // A confirmed Stop edge is a real completion by construction - fire even
        // when the selected text matches the previous reply (short answers like
        // "Hi." often select the same transcript candidate twice). The debounce
        // alone absorbs indicator flicker.
        guard hasClearedDebounce(state, now: now) else {
            return nil
        }

        state.lastFiredFingerprint = selectedFingerprint
        state.lastFiredAt = now
        let userWasAway = state.sawAwayDuringGeneration || !isFrontmost
        state.sawAwayDuringGeneration = false

        return WindowSnapshot(
            app: app,
            message: selectedMessage,
            fingerprint: selectedFingerprint,
            userWasAway: userWasAway
        )
    }

    private func hasClearedDebounce(_ state: State, now: Date) -> Bool {
        guard let lastFiredAt = state.lastFiredAt else { return true }
        return now.timeIntervalSince(lastFiredAt) >= refireDebounce
    }
}
