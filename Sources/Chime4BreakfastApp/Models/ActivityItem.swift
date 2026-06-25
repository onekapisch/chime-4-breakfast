import Foundation

struct ActivityItem: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceApp: TargetApp
    let eventType: NotificationEventType
    let timestamp: Date
    let excerpt: String
    let fingerprint: String
}
