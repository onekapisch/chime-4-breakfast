import Foundation

/// Defines the monitoring cadence independently from Accessibility traversal.
/// A full response scan is only useful after a known generation edge, so idle
/// monitoring stays event-led and uses a slow recovery poll.
enum MonitoringScanPolicy {
    static func pollInterval(hasActiveFinishEdge: Bool) -> TimeInterval {
        hasActiveFinishEdge ? 1 : 30
    }

    static func eventCooldown(hasActiveFinishEdge: Bool) -> TimeInterval {
        hasActiveFinishEdge ? 0.5 : 2
    }

    static func shouldExtractMessage(hasActiveFinishEdge: Bool, generating: Bool) -> Bool {
        hasActiveFinishEdge && !generating
    }

    static func shouldScan(
        hasActiveFinishEdge: Bool,
        isEventDriven: Bool,
        lastIdleScanAt: Date?,
        now: Date
    ) -> Bool {
        if hasActiveFinishEdge || isEventDriven || lastIdleScanAt == nil {
            return true
        }

        return now.timeIntervalSince(lastIdleScanAt!) >= pollInterval(hasActiveFinishEdge: false)
    }
}

enum GenerationIndicatorCachePolicy {
    static func shouldPerformFullTraversal(cachedIndicatorMatches: Bool?) -> Bool {
        cachedIndicatorMatches != true
    }
}
