import Foundation

final class FinishEdgeDetector {
    private struct State {
        var wasGenerating = false
        var awaitingConfirm = false
        var sawAwayDuringGeneration = false
        var pendingMessage: String?
        var lastFiredFingerprint: String?
        var lastObservedFingerprint: String?
        var fastCompletionFallbackArmed = false
    }

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
        isFrontmost: Bool,
        fingerprint: (TargetApp, String) -> String
    ) -> WindowSnapshot? {
        var state = states[app] ?? State()
        defer { states[app] = state }

        if generating {
            if !state.wasGenerating {
                state.sawAwayDuringGeneration = false
                state.pendingMessage = nil
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
            return nil
        }

        if !state.awaitingConfirm {
            guard let selectedMessage = message else { return nil }

            let selectedFingerprint = fingerprint(app, selectedMessage)
            guard let previousFingerprint = state.lastObservedFingerprint else {
                state.lastObservedFingerprint = selectedFingerprint
                state.fastCompletionFallbackArmed = isFrontmost
                return nil
            }

            guard selectedFingerprint != previousFingerprint else {
                state.fastCompletionFallbackArmed = isFrontmost
                return nil
            }

            let canUseFastFallback = state.fastCompletionFallbackArmed
            state.lastObservedFingerprint = selectedFingerprint
            state.fastCompletionFallbackArmed = isFrontmost

            guard !isFrontmost, canUseFastFallback, selectedFingerprint != state.lastFiredFingerprint else {
                return nil
            }

            state.lastFiredFingerprint = selectedFingerprint
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
        state.pendingMessage = nil

        let selectedFingerprint = fingerprint(app, selectedMessage)
        state.lastObservedFingerprint = selectedFingerprint
        state.fastCompletionFallbackArmed = isFrontmost
        guard selectedFingerprint != state.lastFiredFingerprint else {
            return nil
        }

        state.lastFiredFingerprint = selectedFingerprint
        let userWasAway = state.sawAwayDuringGeneration || !isFrontmost
        state.sawAwayDuringGeneration = false

        return WindowSnapshot(
            app: app,
            message: selectedMessage,
            fingerprint: selectedFingerprint,
            userWasAway: userWasAway
        )
    }
}
