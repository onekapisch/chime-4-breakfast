import Foundation

enum QuietHoursMode: String, Codable, CaseIterable, Equatable {
    case allSignals
    case soundOnly

    var title: String {
        switch self {
        case .allSignals:
            "Mute all alerts"
        case .soundOnly:
            "Mute sound only"
        }
    }
}

enum SoundRoutingMode: String, Codable, CaseIterable, Equatable {
    case event
    case app

    var title: String {
        switch self {
        case .event:
            "Per event"
        case .app:
            "Per app"
        }
    }
}

struct UserPreferences: Codable, Equatable {
    var watchCodex: Bool
    var watchClaude: Bool
    var completionAlertsEnabled: Bool
    var attentionAlertsEnabled: Bool
    var completionSoundID: String
    var attentionSoundID: String
    var soundRoutingMode: SoundRoutingMode = .event
    var codexSoundID: String = "wave"
    var claudeSoundID: String = "horn"
    var quietHoursEnabled: Bool
    var quietHoursStartHour: Int
    var quietHoursEndHour: Int
    var quietHoursMode: QuietHoursMode = .allSignals
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
        soundRoutingMode: .event,
        codexSoundID: "wave",
        claudeSoundID: "horn",
        quietHoursEnabled: false,
        quietHoursStartHour: 22,
        quietHoursEndHour: 8,
        quietHoursMode: .allSignals,
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

    func soundID(for app: TargetApp, eventType: NotificationEventType) -> String {
        guard soundRoutingMode == .app else {
            return soundID(for: eventType)
        }

        switch app {
        case .codex:
            return codexSoundID
        case .claude:
            return claudeSoundID
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

    mutating func setSoundID(_ soundID: String, for app: TargetApp) {
        switch app {
        case .codex:
            codexSoundID = soundID
        case .claude:
            claudeSoundID = soundID
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
        soundRoutingMode = try container.decodeIfPresent(SoundRoutingMode.self, forKey: .soundRoutingMode) ?? defaults.soundRoutingMode
        codexSoundID = try container.decodeIfPresent(String.self, forKey: .codexSoundID) ?? defaults.codexSoundID
        claudeSoundID = try container.decodeIfPresent(String.self, forKey: .claudeSoundID) ?? defaults.claudeSoundID
        quietHoursEnabled = try container.decodeIfPresent(Bool.self, forKey: .quietHoursEnabled) ?? defaults.quietHoursEnabled
        quietHoursStartHour = try container.decodeIfPresent(Int.self, forKey: .quietHoursStartHour) ?? defaults.quietHoursStartHour
        quietHoursEndHour = try container.decodeIfPresent(Int.self, forKey: .quietHoursEndHour) ?? defaults.quietHoursEndHour
        quietHoursMode = try container.decodeIfPresent(QuietHoursMode.self, forKey: .quietHoursMode) ?? defaults.quietHoursMode
        screenGlowEnabled = try container.decodeIfPresent(Bool.self, forKey: .screenGlowEnabled) ?? defaults.screenGlowEnabled
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? defaults.notificationsEnabled
        customAttentionPhrases = try container.decodeIfPresent([String].self, forKey: .customAttentionPhrases) ?? defaults.customAttentionPhrases
        let decodedIntensity = try container.decodeIfPresent(Double.self, forKey: .glowIntensity) ?? defaults.glowIntensity
        glowIntensity = GlowConfiguration(intensity: decodedIntensity).intensity
    }
}
