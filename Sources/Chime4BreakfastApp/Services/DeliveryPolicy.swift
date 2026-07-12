import Foundation

struct DeliveryPolicy: Equatable {
    enum QuietHours: Equatable { case off, soundOnly, allSignals }
    let playsSound: Bool
    let showsGlow: Bool
    let showsBanner: Bool

    static let muted = DeliveryPolicy(playsSound: false, showsGlow: false, showsBanner: false)

    static func decide(eventEnabled: Bool, isAway: Bool, glowEnabled: Bool, bannersEnabled: Bool, quietHours: QuietHours) -> DeliveryPolicy {
        guard eventEnabled else { return .muted }
        switch quietHours {
        case .allSignals: return .muted
        case .soundOnly: return .init(playsSound: false, showsGlow: isAway && glowEnabled, showsBanner: isAway && bannersEnabled)
        case .off: return .init(playsSound: true, showsGlow: isAway && glowEnabled, showsBanner: isAway && bannersEnabled)
        }
    }
}
