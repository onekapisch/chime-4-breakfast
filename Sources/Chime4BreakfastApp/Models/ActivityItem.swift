import Foundation

struct ActivityItem: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceApp: TargetApp
    let eventType: NotificationEventType
    let timestamp: Date
    let excerpt: String
    let fingerprint: String
    /// Human-readable record of what the app did for this event and why
    /// (e.g. "Sound + glow", "Sound only (you were in the app)",
    /// "Muted (quiet hours)"). Optional so activity persisted by older builds
    /// still decodes.
    var delivery: String? = nil
}
