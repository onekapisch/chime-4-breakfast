import Foundation

final class FinishEdgeDetector {
    private struct State {
        var wasGenerating = false
        var awaitingConfirm = false
        var sawAwayDuringGeneration = false
        var pendingMessage: String?
        var pendingChangeKey: String?
        var lastFiredAt: Date?
    }

    /// Minimum spacing between two alerts for the same app. A confirmed Stop
    /// edge always represents a real completion (regardless of what text the
    /// selector happened to pick), so identical-message dedup would silently
    /// swallow rapid consecutive replies - this brief debounce only absorbs
    /// generating-indicator flicker.
    private let refireDebounce: TimeInterval = 3

    private var states: [TargetApp: State] = [:]

    func reset(watching apps: [TargetApp]) {
        states = Dictionary(uniqueKeysWithValues: apps.map { ($0, State()) })
    }

    func reset(app: TargetApp) {
        states[app] = State()
    }

    func noteActivation(bundleIdentifier: String?) {
        for app in Array(states.keys) {
            guard states[app]?.wasGenerating == true else { continue }
            if bundleIdentifier != app.bundleIdentifier {
                states[app]?.sawAwayDuringGeneration = true
            }
        }
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
            // Transcript text can change throughout a streamed response; only
            // a confirmed generation edge is authoritative for completion.
            return nil
        }

        guard let selectedMessage = message ?? state.pendingMessage else { return nil }

        state.awaitingConfirm = false
        let selectedChangeKey = changeKey ?? state.pendingChangeKey
        state.pendingMessage = nil
        state.pendingChangeKey = nil

        let selectedFingerprint = fingerprint(app, selectedChangeKey ?? selectedMessage)

        // A confirmed Stop edge is a real completion by construction - fire even
        // when the selected text matches the previous reply (short answers like
        // "Hi." often select the same transcript candidate twice). The debounce
        // alone absorbs indicator flicker.
        guard hasClearedDebounce(state, now: now) else {
            return nil
        }

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
