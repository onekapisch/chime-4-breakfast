import Foundation

struct ObservedEvent: Equatable {
    let sourceApp: TargetApp
    let eventType: NotificationEventType
    let message: String
    let fingerprint: String
}
