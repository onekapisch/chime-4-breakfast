import Foundation

final class StabilityDetector {
    private let settleDuration: TimeInterval
    private var lastCandidate: String?
    private var lastChangeTime: TimeInterval = 0
    private var lastEmittedCandidate: String?

    init(settleDuration: TimeInterval = 2.0) {
        self.settleDuration = settleDuration
    }

    func record(candidate: String, at time: TimeInterval) {
        guard candidate != lastCandidate else { return }
        if candidate != lastEmittedCandidate {
            lastEmittedCandidate = nil
        }
        lastCandidate = candidate
        lastChangeTime = time
    }

    func stableCandidate(at time: TimeInterval) -> String? {
        guard let lastCandidate else { return nil }
        guard time - lastChangeTime >= settleDuration else { return nil }
        guard lastCandidate != lastEmittedCandidate else { return nil }
        lastEmittedCandidate = lastCandidate
        return lastCandidate
    }
}
