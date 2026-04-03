import Foundation

struct UserPreferences: Codable, Equatable {
    var watchCodex: Bool
    var watchClaude: Bool
    var completionAlertsEnabled: Bool
    var attentionAlertsEnabled: Bool
    var completionSoundID: String
    var attentionSoundID: String
    var quietHoursEnabled: Bool
    var quietHoursStartHour: Int
    var quietHoursEndHour: Int

    static let defaultValue = UserPreferences(
        watchCodex: true,
        watchClaude: true,
        completionAlertsEnabled: true,
        attentionAlertsEnabled: true,
        completionSoundID: "wave",
        attentionSoundID: "horn",
        quietHoursEnabled: false,
        quietHoursStartHour: 22,
        quietHoursEndHour: 8
    )

    func isWatching(_ app: TargetApp) -> Bool {
        switch app {
        case .codex:
            watchCodex
        case .claude:
            watchClaude
        }
    }

    mutating func setWatching(_ app: TargetApp, enabled: Bool) {
        switch app {
        case .codex:
            watchCodex = enabled
        case .claude:
            watchClaude = enabled
        }
    }

    func soundID(for eventType: NotificationEventType) -> String {
        switch eventType {
        case .completion:
            completionSoundID
        case .attention:
            attentionSoundID
        }
    }

    mutating func setSoundID(_ soundID: String, for eventType: NotificationEventType) {
        switch eventType {
        case .completion:
            completionSoundID = soundID
        case .attention:
            attentionSoundID = soundID
        }
    }

    func alertsEnabled(for eventType: NotificationEventType) -> Bool {
        switch eventType {
        case .completion:
            completionAlertsEnabled
        case .attention:
            attentionAlertsEnabled
        }
    }

    mutating func setAlertsEnabled(_ enabled: Bool, for eventType: NotificationEventType) {
        switch eventType {
        case .completion:
            completionAlertsEnabled = enabled
        case .attention:
            attentionAlertsEnabled = enabled
        }
    }

    func quietHoursContains(_ date: Date, calendar: Calendar = .current) -> Bool {
        guard quietHoursEnabled else { return false }

        let hour = calendar.component(.hour, from: date)

        if quietHoursStartHour == quietHoursEndHour {
            return true
        }

        if quietHoursStartHour < quietHoursEndHour {
            return (quietHoursStartHour..<quietHoursEndHour).contains(hour)
        }

        return hour >= quietHoursStartHour || hour < quietHoursEndHour
    }
}
