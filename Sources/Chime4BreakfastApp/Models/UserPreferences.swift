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
    var screenGlowEnabled: Bool
    var notificationsEnabled: Bool = false
    var customAttentionPhrases: [String] = []
    var glowIntensity: Double = 1.0

    static let defaultValue = UserPreferences(
        watchCodex: true,
        watchClaude: true,
        completionAlertsEnabled: true,
        attentionAlertsEnabled: true,
        completionSoundID: "wave",
        attentionSoundID: "horn",
        quietHoursEnabled: false,
        quietHoursStartHour: 22,
        quietHoursEndHour: 8,
        screenGlowEnabled: true,
        notificationsEnabled: false,
        customAttentionPhrases: [],
        glowIntensity: 1.0
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

extension UserPreferences {
    /// Decodes defensively so that adding new preference keys in later versions
    /// does not discard a user's previously saved settings. Missing keys fall
    /// back to the matching default value.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = UserPreferences.defaultValue

        watchCodex = try container.decodeIfPresent(Bool.self, forKey: .watchCodex) ?? defaults.watchCodex
        watchClaude = try container.decodeIfPresent(Bool.self, forKey: .watchClaude) ?? defaults.watchClaude
        completionAlertsEnabled = try container.decodeIfPresent(Bool.self, forKey: .completionAlertsEnabled) ?? defaults.completionAlertsEnabled
        attentionAlertsEnabled = try container.decodeIfPresent(Bool.self, forKey: .attentionAlertsEnabled) ?? defaults.attentionAlertsEnabled
        completionSoundID = try container.decodeIfPresent(String.self, forKey: .completionSoundID) ?? defaults.completionSoundID
        attentionSoundID = try container.decodeIfPresent(String.self, forKey: .attentionSoundID) ?? defaults.attentionSoundID
        quietHoursEnabled = try container.decodeIfPresent(Bool.self, forKey: .quietHoursEnabled) ?? defaults.quietHoursEnabled
        quietHoursStartHour = try container.decodeIfPresent(Int.self, forKey: .quietHoursStartHour) ?? defaults.quietHoursStartHour
        quietHoursEndHour = try container.decodeIfPresent(Int.self, forKey: .quietHoursEndHour) ?? defaults.quietHoursEndHour
        screenGlowEnabled = try container.decodeIfPresent(Bool.self, forKey: .screenGlowEnabled) ?? defaults.screenGlowEnabled
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? defaults.notificationsEnabled
        customAttentionPhrases = try container.decodeIfPresent([String].self, forKey: .customAttentionPhrases) ?? defaults.customAttentionPhrases
        let decodedIntensity = try container.decodeIfPresent(Double.self, forKey: .glowIntensity) ?? defaults.glowIntensity
        // Values below 0.7 predate the visible-floor fix (old builds silently
        // overrode the slider, leaving stale stored values like 0.2). Treat them
        // as unset and restore full brightness.
        glowIntensity = decodedIntensity < 0.7 ? 1.0 : min(decodedIntensity, 1.0)
    }
}
