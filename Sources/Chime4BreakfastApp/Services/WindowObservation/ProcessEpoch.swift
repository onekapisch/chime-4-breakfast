import Foundation

/// Invalidates detached Accessibility work whenever a target process changes.
/// A result is usable only for the PID and epoch that launched it.
struct ProcessEpochs: Sendable {
    struct Observation: Equatable, Sendable {
        let epoch: Int
        let didChange: Bool
    }

    private var pids: [TargetApp: pid_t] = [:]
    private var values: [TargetApp: Int] = [:]

    mutating func observe(app: TargetApp, pid: pid_t) -> Observation {
        let didChange = pids[app] != pid
        if didChange {
            values[app, default: 0] += 1
            pids[app] = pid
        }
        return Observation(epoch: values[app, default: 0], didChange: didChange)
    }

    mutating func invalidate(app: TargetApp) {
        values[app, default: 0] += 1
        pids[app] = nil
    }

    mutating func invalidateAll(_ apps: [TargetApp]) {
        for app in apps {
            invalidate(app: app)
        }
    }

    func accepts(app: TargetApp, pid: pid_t, epoch: Int) -> Bool {
        pids[app] == pid && values[app, default: 0] == epoch
    }
}
